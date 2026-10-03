# Dot-sourced from $PROFILE by `dot.ps1 link`. dmmulroy's shell config is
# zsh; PowerShell is the Windows stand-in, so PSReadLine does the line editing.

# Auto-pair quotes like nvim-autopairs: type the closing quote to step over it,
# no pairing right after a word character (don't), Backspace eats an empty pair.
Set-PSReadLineKeyHandler -Chord '"', "'" -ScriptBlock {
    param($key, $arg)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $q = [string]$key.KeyChar
    if ($cursor -lt $line.Length -and [string]$line[$cursor] -eq $q) {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    } elseif ($cursor -gt 0 -and [string]$line[$cursor - 1] -match '\w') {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($q)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($q + $q)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

Set-PSReadLineKeyHandler -Key Backspace -ScriptBlock {
    param($key, $arg)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -gt 0 -and $cursor -lt $line.Length -and
        $line[$cursor - 1] -eq $line[$cursor] -and [string]$line[$cursor] -match "[`"']") {
        [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
    }
}
