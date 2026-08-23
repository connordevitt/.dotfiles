#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap and maintain this Windows terminal environment.

.DESCRIPTION
    Installs the terminal/editor stack with winget, links this repository's
    configs into the fixed paths WezTerm, Neovim and Herdr actually read, and
    diagnoses the ways that wiring silently rots.

    Written for Windows PowerShell 5.1, so no `&&`, no ternary, no `??`.
    Everything here runs unprivileged: junctions and User-scope environment
    variables need no elevation and no Developer Mode.

.EXAMPLE
    .\dot.ps1 init
    .\dot.ps1 init -WithAgents
    .\dot.ps1 doctor
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',

    [switch]$WithAgents,
    [switch]$SkipInstall,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$script:RepoRoot        = $PSScriptRoot
$script:ManifestPath    = Join-Path $script:RepoRoot 'packages\winget.txt'
$script:WezLink         = Join-Path $env:USERPROFILE '.config\wezterm'
$script:WezTarget       = Join-Path $script:RepoRoot 'wezterm'
$script:NvimLink        = Join-Path $env:LOCALAPPDATA 'nvim'
$script:NvimTarget      = Join-Path $script:RepoRoot 'nvim'
$script:HerdrConfig     = Join-Path $script:RepoRoot 'herdr\config.toml'
$script:LiveHerdrConfig = Join-Path $env:APPDATA 'herdr\config.toml'
$script:ShadowWez       = Join-Path $env:USERPROFILE '.wezterm.lua'
$script:LazyLock        = Join-Path $script:RepoRoot 'nvim\lazy-lock.json'

$script:FailedPackages = @()
$script:Failures       = 0
$script:Warnings       = 0

# winget 0x8A15002B, "no applicable upgrade found" -- i.e. already current.
$script:WingetNoUpgrade = -1978335189

function Write-Header { param([string]$Text) Write-Host ''; Write-Host "=> $Text" -ForegroundColor Magenta }
function Write-Step   { param([string]$Text) Write-Host ''; Write-Host "-- $Text" -ForegroundColor Cyan }
function Write-Ok     { param([string]$Text) Write-Host "  [ ok ] $Text" -ForegroundColor Green }
function Write-Warn   { param([string]$Text) Write-Host "  [warn] $Text" -ForegroundColor Yellow }
function Write-Fail   { param([string]$Text) Write-Host "  [FAIL] $Text" -ForegroundColor Red }
function Write-Info   { param([string]$Text) Write-Host "         $Text" -ForegroundColor DarkGray }

function Add-Fail { param([string]$Text) Write-Fail $Text; $script:Failures = $script:Failures + 1 }
function Add-Warn { param([string]$Text) Write-Warn $Text; $script:Warnings = $script:Warnings + 1 }

function Test-Command {
    param([string]$Name)
    $found = Get-Command $Name -ErrorAction SilentlyContinue
    return [bool]$found
}

function Get-CommandPath {
    param([string]$Name)
    $found = Get-Command $Name -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    return $null
}

function Resolve-PathKey {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    return $Path.TrimEnd('\', '/').ToLowerInvariant()
}

# A process inherits PATH at launch, so a shell opened before an install never
# sees the new tool. Rebuild PATH from the registry so checks that follow an
# install in the same run reflect reality.
function Update-SessionPath {
    $parts = @()
    foreach ($scope in @('Machine', 'User')) {
        $value = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ($value) { $parts += $value.Split(';') }
    }
    if ($env:PATH) { $parts += $env:PATH.Split(';') }

    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    $ordered = @()
    foreach ($part in $parts) {
        $trimmed = $part.Trim()
        if ($trimmed -and $seen.Add($trimmed.ToLowerInvariant())) { $ordered += $trimmed }
    }
    $env:PATH = ($ordered -join ';')
}

function Read-Manifest {
    if (-not (Test-Path $script:ManifestPath)) {
        Write-Fail "package manifest not found: $script:ManifestPath"
        return @()
    }
    $ids = @()
    foreach ($line in (Get-Content -Path $script:ManifestPath)) {
        $text = $line
        $hash = $text.IndexOf('#')
        if ($hash -ge 0) { $text = $text.Substring(0, $hash) }
        $text = $text.Trim()
        if ($text) { $ids += $text }
    }
    return $ids
}

function Confirm-Action {
    param([string]$Message)
    if ($Yes) { return $true }
    while ($true) {
        $reply = Read-Host "$Message [y/N]"
        if ([string]::IsNullOrWhiteSpace($reply)) { return $false }
        if ($reply -match '^(y|yes)$') { return $true }
        if ($reply -match '^(n|no)$')  { return $false }
    }
}

function Test-WingetPackage {
    param([string]$Id)
    $null = winget list --id $Id --exact --accept-source-agreements
    return ($LASTEXITCODE -eq 0)
}

function Get-WingetVersion {
    param([string]$Id)
    $output = winget list --id $Id --exact --accept-source-agreements | Out-String
    if ($LASTEXITCODE -ne 0) { return $null }

    # winget pads each column to its content width, so the gap between columns
    # can be a single space. Splitting on runs of whitespace and anchoring on
    # the Id token is more reliable than fixed columns: the version is always
    # the token immediately after the Id.
    foreach ($line in ($output -split "`r?`n")) {
        if ($line -notmatch [regex]::Escape($Id)) { continue }
        $tokens = ($line.Trim() -split '\s+')
        for ($i = 0; $i -lt ($tokens.Count - 1); $i++) {
            if ($tokens[$i] -eq $Id) { return $tokens[$i + 1] }
        }
    }
    return 'installed'
}

function Install-WingetPackage {
    param([string]$Id)

    if (Test-WingetPackage -Id $Id) {
        Write-Ok "$Id already installed"
        return $true
    }

    Write-Info "installing $Id"
    winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
    $code = $LASTEXITCODE

    if ($code -eq 0) { Write-Ok "$Id installed"; return $true }
    if ($code -eq $script:WingetNoUpgrade) { Write-Ok "$Id already installed"; return $true }

    # One failure must not abort the run; collect and report at the end.
    Write-Fail "$Id failed (winget exit $code)"
    $script:FailedPackages += $Id
    return $false
}

# A junction rather than a symlink: no elevation, no Developer Mode, and it
# operates at the directory level so it survives an editor's write-then-rename.
function New-RepoJunction {
    param([string]$LinkPath, [string]$TargetPath, [string]$Label)
    cmd /c mklink /J "$LinkPath" "$TargetPath" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Label junction created"
        return $true
    }
    Write-Fail "$Label junction failed (mklink exit $LASTEXITCODE)"
    return $false
}

function Set-RepoJunction {
    param([string]$LinkPath, [string]$TargetPath, [string]$Label)

    if (-not (Test-Path $TargetPath)) {
        Write-Fail "$Label target missing from the repo: $TargetPath"
        return $false
    }

    $parent = Split-Path -Parent $LinkPath
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        Write-Info "created $parent"
    }

    if (-not (Test-Path $LinkPath)) {
        return (New-RepoJunction -LinkPath $LinkPath -TargetPath $TargetPath -Label $Label)
    }

    $item = Get-Item -LiteralPath $LinkPath -Force

    if ($item.LinkType -eq 'Junction') {
        $current = @($item.Target)[0]
        if ((Resolve-PathKey $current) -eq (Resolve-PathKey $TargetPath)) {
            Write-Ok "$Label junction already correct"
            return $true
        }
        Write-Warn "$Label junction points at $current"
        if (-not (Confirm-Action "  Repoint it to $TargetPath?")) {
            Write-Warn "$Label left unchanged"
            return $false
        }
        # Delete() on a junction removes the reparse point only; the directory
        # it pointed at is untouched.
        $item.Delete()
        return (New-RepoJunction -LinkPath $LinkPath -TargetPath $TargetPath -Label $Label)
    }

    Write-Fail "$Label path exists and is not a junction: $LinkPath"
    Write-Info 'Refusing to touch it. Move or delete it yourself, then re-run.'
    return $false
}

function Remove-RepoJunction {
    param([string]$LinkPath, [string]$TargetPath, [string]$Label)

    if (-not (Test-Path $LinkPath)) { Write-Info "$Label not linked"; return }

    $item = Get-Item -LiteralPath $LinkPath -Force
    if ($item.LinkType -ne 'Junction') {
        Write-Warn "$Label is a real directory, left alone: $LinkPath"
        return
    }
    $current = @($item.Target)[0]
    if ((Resolve-PathKey $current) -ne (Resolve-PathKey $TargetPath)) {
        Write-Warn "$Label junction points at $current, not this repo. Left alone."
        return
    }
    $item.Delete()
    Write-Ok "$Label junction removed"
}

# Herdr keeps live runtime state (sockets, logs, session.json) in
# %APPDATA%\herdr, so that directory cannot be a junction to the repo. Herdr's
# own environment override is used instead.
function Set-HerdrConfigPath {
    if (-not (Test-Path $script:HerdrConfig)) {
        Write-Fail "herdr config missing from the repo: $script:HerdrConfig"
        return $false
    }

    $current = [Environment]::GetEnvironmentVariable('HERDR_CONFIG_PATH', 'User')

    if ((Resolve-PathKey $current) -eq (Resolve-PathKey $script:HerdrConfig)) {
        $env:HERDR_CONFIG_PATH = $script:HerdrConfig
        Write-Ok 'HERDR_CONFIG_PATH already correct'
        return $true
    }

    if ($current) {
        Write-Warn "HERDR_CONFIG_PATH was $current"
    } else {
        Write-Warn 'HERDR_CONFIG_PATH was unset, so herdr has been loading %APPDATA%\herdr\config.toml'
    }

    [Environment]::SetEnvironmentVariable('HERDR_CONFIG_PATH', $script:HerdrConfig, 'User')
    $env:HERDR_CONFIG_PATH = $script:HerdrConfig
    Write-Ok "HERDR_CONFIG_PATH -> $script:HerdrConfig"
    Write-Info 'Already-open terminals keep the old value. Open a new window.'
    return $true
}

function Install-Herdr {
    Write-Step 'herdr'
    if (Test-Command 'herdr') {
        Write-Ok "herdr already installed ($(Get-CommandPath 'herdr'))"
        return
    }
    Write-Warn 'herdr is not on winget; its only Windows install is a remote script'
    Write-Info 'command: irm https://herdr.dev/install.ps1 | iex'
    Write-Info 'herdr documents its Windows support as beta'
    if (-not (Confirm-Action '  Run it?')) {
        Write-Warn 'skipped herdr; the rest of the setup works without it'
        return
    }
    try {
        Invoke-RestMethod -Uri 'https://herdr.dev/install.ps1' | Invoke-Expression
        Update-SessionPath
        if (Test-Command 'herdr') { Write-Ok 'herdr installed' }
        else { Write-Warn 'herdr installed but not on PATH yet; open a new shell' }
    } catch {
        Write-Fail "herdr install failed: $($_.Exception.Message)"
    }
}

function Install-ClaudeCode {
    if (Test-Command 'claude') {
        $version = (claude --version | Out-String).Trim()
        Write-Ok "claude already installed ($version)"
        return
    }
    Write-Info 'installing Claude Code from https://claude.ai/install.ps1'
    try {
        Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression
        Update-SessionPath
        if (Test-Command 'claude') { Write-Ok 'claude installed' }
        else { Write-Warn 'claude installed but not on PATH yet; open a new shell' }
    } catch {
        Write-Fail "Claude Code install failed: $($_.Exception.Message)"
    }
}

# The winget package registers its own directory on PATH but ships the binary
# under its full target-triple name (codex-x86_64-pc-windows-msvc.exe) and does
# not provide a `codex` command. Drop a .cmd shim beside it so the install is
# actually usable. Written as ASCII with no BOM: a BOM breaks `@echo off`.
function Add-CodexShim {
    $root = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (-not (Test-Path $root)) { return $false }

    $dir = Get-ChildItem $root -Directory -Filter 'OpenAI.Codex*' -ErrorAction SilentlyContinue |
           Select-Object -First 1
    if (-not $dir) { return $false }

    $exe = Get-ChildItem $dir.FullName -Filter 'codex-*windows*.exe' -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -notmatch 'sandbox-setup|command-runner' } |
           Select-Object -First 1
    if (-not $exe) { return $false }

    $shim = Join-Path $dir.FullName 'codex.cmd'
    Set-Content -Path $shim -Encoding ascii -Value @('@echo off', "`"%~dp0$($exe.Name)`" %*")
    return $true
}

function Install-Codex {
    if (Test-Command 'codex') {
        Write-Ok "codex already installed ($(Get-CommandPath 'codex'))"
        return
    }

    Install-WingetPackage -Id 'OpenAI.Codex' | Out-Null

    if (Add-CodexShim) { Write-Ok 'codex shim in place' }
    else { Write-Warn 'could not create a codex shim; run codex-x86_64-pc-windows-msvc.exe directly' }

    Update-SessionPath
    if (Test-Command 'codex') { Write-Ok "codex -> $(Get-CommandPath 'codex')" }
    else { Write-Info 'codex will resolve in a new shell' }
}

function Invoke-Agents {
    Write-Step 'agent CLIs'
    # Refresh first: in a shell that predates an earlier install, these tools are
    # already present but invisible, and we would reinstall them needlessly.
    Update-SessionPath
    Install-ClaudeCode
    Install-Codex
}

function Invoke-Install {
    Write-Header 'Installing packages'

    if (-not (Test-Command 'winget')) {
        Write-Fail 'winget not found. Install "App Installer" from the Microsoft Store.'
        return 1
    }

    $script:FailedPackages = @()
    foreach ($id in (Read-Manifest)) {
        Install-WingetPackage -Id $id | Out-Null
    }
    Update-SessionPath

    if ($WithAgents) { Invoke-Agents }

    if ($script:FailedPackages.Count -gt 0) {
        Write-Warn "failed: $($script:FailedPackages -join ', ')"
        Write-Info 'Re-run .\dot.ps1 install to retry.'
        return 1
    }
    return 0
}

function Invoke-Link {
    Write-Header 'Linking configs'

    $ok = $true
    if (-not (Set-RepoJunction -LinkPath $script:WezLink  -TargetPath $script:WezTarget  -Label 'wezterm')) { $ok = $false }
    if (-not (Set-RepoJunction -LinkPath $script:NvimLink -TargetPath $script:NvimTarget -Label 'nvim'))    { $ok = $false }
    if (-not (Set-HerdrConfigPath)) { $ok = $false }

    # A ~/.wezterm.lua outranks ~/.config/wezterm, so it silently wins.
    if (Test-Path $script:ShadowWez) {
        Write-Fail "$script:ShadowWez outranks this repo's config. Delete it."
        $ok = $false
    } else {
        Write-Ok 'no shadowing .wezterm.lua'
    }

    if ($ok) { return 0 }
    return 1
}

function Invoke-Unlink {
    Write-Header 'Unlinking configs'

    if (-not (Confirm-Action 'Remove both junctions and clear HERDR_CONFIG_PATH?')) {
        Write-Warn 'aborted'
        return 0
    }

    Remove-RepoJunction -LinkPath $script:WezLink  -TargetPath $script:WezTarget  -Label 'wezterm'
    Remove-RepoJunction -LinkPath $script:NvimLink -TargetPath $script:NvimTarget -Label 'nvim'

    $current = [Environment]::GetEnvironmentVariable('HERDR_CONFIG_PATH', 'User')
    if ((Resolve-PathKey $current) -eq (Resolve-PathKey $script:HerdrConfig)) {
        [Environment]::SetEnvironmentVariable('HERDR_CONFIG_PATH', $null, 'User')
        Write-Ok 'HERDR_CONFIG_PATH cleared'
    } else {
        Write-Info 'HERDR_CONFIG_PATH does not point at this repo; left alone'
    }
    return 0
}

function Invoke-CheckPackages {
    Write-Header 'Package status'

    if (-not (Test-Command 'winget')) {
        Write-Fail 'winget not found'
        return 1
    }

    $rows = @()
    foreach ($id in (Read-Manifest)) {
        $version = Get-WingetVersion -Id $id
        if ($version) {
            $rows += [pscustomobject]@{ Package = $id; Status = 'installed'; Version = $version }
        } else {
            $rows += [pscustomobject]@{ Package = $id; Status = 'MISSING';   Version = '-' }
        }
    }

    $rows | Format-Table -AutoSize | Out-Host

    $missing = @($rows | Where-Object { $_.Status -eq 'MISSING' })
    if ($missing.Count -gt 0) {
        Write-Warn "$($missing.Count) missing. Run .\dot.ps1 install"
        return 1
    }
    Write-Ok 'all manifest packages installed'
    return 0
}

function Test-JunctionHealth {
    param([string]$LinkPath, [string]$TargetPath, [string]$Label)

    if (-not (Test-Path $LinkPath)) {
        Add-Fail "$Label not linked ($LinkPath missing)"
        Write-Info 'fix: .\dot.ps1 link'
        return
    }
    $item = Get-Item -LiteralPath $LinkPath -Force
    if ($item.LinkType -ne 'Junction') {
        Add-Fail "$Label exists but is not a junction: $LinkPath"
        return
    }
    $current = @($item.Target)[0]
    if ((Resolve-PathKey $current) -ne (Resolve-PathKey $TargetPath)) {
        Add-Fail "$Label junction -> $current (expected $TargetPath)"
        return
    }
    Write-Ok "$Label -> $current"
}

function Invoke-Doctor {
    Write-Header 'Environment check'
    $script:Failures = 0
    $script:Warnings = 0

    # Report what a new shell would see, not what this possibly-stale one does.
    # Without this, running doctor in a terminal opened before an install
    # produces exactly the false alarm doctor exists to prevent.
    Update-SessionPath

    Write-Step 'tooling'
    if (Test-Command 'winget') { Write-Ok 'winget present' }
    else { Add-Fail 'winget not found. Install "App Installer" from the Microsoft Store.' }

    Write-Step 'packages'
    if (Test-Command 'winget') {
        foreach ($id in (Read-Manifest)) {
            $version = Get-WingetVersion -Id $id
            if ($version) { Write-Ok "$id ($version)" }
            else { Add-Fail "$id not installed" }
        }
    } else {
        Add-Warn 'skipped package check; winget unavailable'
    }

    Write-Step 'commands on PATH'
    foreach ($name in @('wezterm', 'nvim', 'git', 'zig', 'rg', 'fd')) {
        $path = Get-CommandPath $name
        if ($path) { Write-Ok "$name -> $path" }
        else {
            Add-Fail "$name not on PATH"
            Write-Info 'A shell opened before the install never sees it. Try a new window.'
        }
    }

    Write-Step 'neovim version'
    if (Test-Command 'nvim') {
        $first = (nvim --version | Select-Object -First 1)
        if ($first -match 'v(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -gt 0 -or $minor -ge 11) { Write-Ok $first.Trim() }
            else { Add-Fail "$($first.Trim()) is below 0.11; vim.lsp.config does not exist there" }
        } else {
            Add-Warn 'could not parse nvim version'
        }
    } else {
        Add-Fail 'nvim not found'
    }

    Write-Step 'config links'
    Test-JunctionHealth -LinkPath $script:WezLink  -TargetPath $script:WezTarget  -Label 'wezterm'
    Test-JunctionHealth -LinkPath $script:NvimLink -TargetPath $script:NvimTarget -Label 'nvim'

    if (Test-Path $script:ShadowWez) {
        Add-Fail "$script:ShadowWez shadows this repo's wezterm.lua"
        Write-Info 'fix: delete it, then press Ctrl+Shift+R in WezTerm'
    } else {
        Write-Ok 'no shadowing .wezterm.lua'
    }

    Write-Step 'herdr config'
    $herdrPath = [Environment]::GetEnvironmentVariable('HERDR_CONFIG_PATH', 'User')
    if (-not $herdrPath) {
        Add-Fail 'HERDR_CONFIG_PATH is unset, so herdr silently loads %APPDATA%\herdr\config.toml'
        Write-Info 'fix: .\dot.ps1 link'
    } elseif ((Resolve-PathKey $herdrPath) -ne (Resolve-PathKey $script:HerdrConfig)) {
        Add-Fail "HERDR_CONFIG_PATH -> $herdrPath (expected $script:HerdrConfig)"
        Write-Info 'fix: .\dot.ps1 link'
    } elseif (-not (Test-Path $herdrPath)) {
        Add-Fail "HERDR_CONFIG_PATH -> $herdrPath but no file is there"
    } else {
        Write-Ok "HERDR_CONFIG_PATH -> $herdrPath"
    }

    if (Test-Path $script:LiveHerdrConfig) {
        $liveHash = (Get-FileHash $script:LiveHerdrConfig).Hash
        $repoHash = (Get-FileHash $script:HerdrConfig).Hash
        if ($liveHash -ne $repoHash) {
            Add-Warn "$script:LiveHerdrConfig differs from the repo copy"
            Write-Info 'Harmless while HERDR_CONFIG_PATH is set; it is the fallback that loads if it is not.'
        }
    }

    Write-Step 'neovim plugins'
    if (Test-Path $script:LazyLock) { Write-Ok 'nvim/lazy-lock.json present (plugin commits pinned)' }
    else { Add-Warn 'nvim/lazy-lock.json missing; plugin versions are unpinned' }

    Write-Step 'optional tooling'
    foreach ($name in @('herdr', 'claude', 'codex')) {
        $path = Get-CommandPath $name
        if ($path) { Write-Ok "$name -> $path" }
        else { Write-Info "$name not installed (optional)" }
    }

    Write-Host ''
    if ($script:Failures -gt 0) {
        Write-Host "  $($script:Failures) failed, $($script:Warnings) warnings" -ForegroundColor Red
    } elseif ($script:Warnings -gt 0) {
        Write-Host "  all checks passed, $($script:Warnings) warnings" -ForegroundColor Yellow
    } else {
        Write-Host '  all checks passed' -ForegroundColor Green
    }
    return $script:Failures
}

function Invoke-Update {
    Write-Header 'Updating'

    Write-Step 'git pull'
    Push-Location $script:RepoRoot
    try {
        git pull --ff-only | Out-Host
        if ($LASTEXITCODE -eq 0) { Write-Ok 'repo up to date' }
        else { Write-Warn 'git pull failed; uncommitted changes or a diverged branch?' }
    } finally {
        Pop-Location
    }

    Write-Step 'winget upgrade'
    if (Test-Command 'winget') {
        foreach ($id in (Read-Manifest)) {
            if (-not (Test-WingetPackage -Id $id)) {
                Write-Info "$id not installed, skipping"
                continue
            }
            winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
            $code = $LASTEXITCODE
            if ($code -eq 0) { Write-Ok "$id upgraded" }
            elseif ($code -eq $script:WingetNoUpgrade) { Write-Ok "$id already current" }
            else { Write-Warn "$id upgrade returned $code" }
        }
        Update-SessionPath
    } else {
        Write-Fail 'winget not found; skipping upgrades'
    }

    Invoke-Link | Out-Null
    return (Invoke-Doctor)
}

function Invoke-Init {
    Write-Header 'dotfiles init'
    Write-Info "repo: $script:RepoRoot"

    if ($SkipInstall) {
        Write-Info 'skipping package installation (-SkipInstall)'
    } else {
        Invoke-Install | Out-Null
    }

    Install-Herdr
    Update-SessionPath
    Invoke-Link | Out-Null

    $failures = Invoke-Doctor

    Write-Host ''
    if ($failures -eq 0) {
        Write-Ok 'Ready.'
        Write-Info 'Open a NEW WezTerm window so PATH and HERDR_CONFIG_PATH apply.'
        Write-Info 'Then run nvim once and let lazy.nvim and Mason finish.'
    } else {
        Write-Warn 'Setup finished with failures. See above.'
    }
    return $failures
}

function Show-Help {
    Write-Host ''
    Write-Host 'dot.ps1 - bootstrap and maintain this terminal environment' -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Usage: .\dot.ps1 <command> [options]'
    Write-Host ''
    Write-Host '  Commands:' -ForegroundColor Cyan
    Write-Host '    init             install packages, link configs, then verify'
    Write-Host '    install          install the winget packages in packages\winget.txt'
    Write-Host '    agents           install the agent CLIs (Claude Code, Codex)'
    Write-Host '    link             create the junctions and set HERDR_CONFIG_PATH'
    Write-Host '    unlink           remove the junctions and clear HERDR_CONFIG_PATH'
    Write-Host '    doctor           diagnose the environment; exits non-zero on failure'
    Write-Host '    update           git pull, upgrade packages, re-link, verify'
    Write-Host '    check-packages   list manifest packages against what is installed'
    Write-Host '    help             this message'
    Write-Host ''
    Write-Host '  Options:' -ForegroundColor Cyan
    Write-Host '    -WithAgents      also install the agent CLIs during init/install'
    Write-Host '    -SkipInstall     init links and verifies without installing'
    Write-Host '    -Yes             assume yes at every prompt'
    Write-Host ''
    Write-Host '  Everything is idempotent and needs no administrator rights.' -ForegroundColor DarkGray
    Write-Host ''
}

$exitCode = 0

switch ($Command.ToLowerInvariant()) {
    'init'           { $exitCode = Invoke-Init }
    'install'        { $exitCode = Invoke-Install }
    'agents'         { Invoke-Agents; $exitCode = 0 }
    'link'           { $exitCode = Invoke-Link }
    'unlink'         { $exitCode = Invoke-Unlink }
    'doctor'         { $exitCode = Invoke-Doctor }
    'update'         { $exitCode = Invoke-Update }
    'check-packages' { $exitCode = Invoke-CheckPackages }
    'help'           { Show-Help; $exitCode = 0 }
    default {
        Write-Fail "unknown command: $Command"
        Show-Help
        $exitCode = 1
    }
}

exit $exitCode
