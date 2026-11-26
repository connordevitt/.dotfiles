#!/usr/bin/env bash
# dot-mac.sh — macOS bootstrap and maintenance. Equivalent of dot.ps1 for Windows.
# Everything is idempotent and needs no sudo (except Homebrew's own installer).
# No -e: one failed link or check must not abort the rest of the run.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BREWFILE="$REPO_ROOT/packages/Brewfile"

# ── helpers ──────────────────────────────────────────────────────────────────

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
header() { echo; printf '\033[35m=> %s\033[0m\n' "$*"; }
step()   { echo; printf '\033[36m-- %s\033[0m\n' "$*"; }
ok()     { printf '  \033[32m[ ok ]\033[0m %s\n' "$*"; }
warn()   { printf '  \033[33m[warn]\033[0m %s\n' "$*"; }
fail()   { printf '  \033[31m[FAIL]\033[0m %s\n' "$*"; }
info()   { printf '  \033[90m        %s\033[0m\n' "$*"; }

has() { command -v "$1" &>/dev/null; }

# ── link ─────────────────────────────────────────────────────────────────────

ensure_link() {
    local target="$1" link="$2" label="$3"
    if [ ! -e "$target" ]; then
        fail "$label target missing: $target"; return 1
    fi
    mkdir -p "$(dirname "$link")"
    if [ -L "$link" ]; then
        local current; current="$(readlink "$link")"
        if [ "$current" = "$target" ]; then
            ok "$label symlink already correct"; return 0
        fi
        warn "$label symlink points at $current, relinking"
        rm "$link"
    elif [ -e "$link" ]; then
        fail "$label path exists and is not a symlink: $link"
        info "Move or delete it yourself, then re-run."
        return 1
    fi
    ln -s "$target" "$link"
    ok "$label -> $target"
}

remove_link() {
    local target="$1" link="$2" label="$3"
    if [ ! -L "$link" ]; then
        [ -e "$link" ] && warn "$label is not a symlink, left alone: $link"
        return 0
    fi
    local current; current="$(readlink "$link")"
    if [ "$current" != "$target" ]; then
        warn "$label symlink points at $current, not this repo. Left alone."
        return 0
    fi
    rm "$link"
    ok "$label symlink removed"
}

# ── commands ─────────────────────────────────────────────────────────────────

do_install() {
    header "Installing packages"

    if ! has brew; then
        step "Homebrew"
        warn "brew not found — installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon installs to /opt/homebrew, Intel to /usr/local.
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [ -x "$b" ] && eval "$("$b" shellenv)" && break
        done
    fi

    step "Brewfile"
    if brew bundle --file="$BREWFILE"; then ok "packages installed"; else fail "brew bundle failed"; return 1; fi
}

do_link() {
    header "Linking configs"

    # Older versions linked the whole ~/.config/herdr dir, which put Herdr's
    # runtime state in the repo and loaded the Windows config. Undo that.
    if [ -L "$HOME/.config/herdr" ] && [ "$(readlink "$HOME/.config/herdr")" = "$REPO_ROOT/herdr" ]; then
        rm "$HOME/.config/herdr"
        info "removed old ~/.config/herdr directory symlink"
    fi

    local rc=0
    ensure_link "$REPO_ROOT/nvim"    "$HOME/.config/nvim"    "nvim"    || rc=1
    ensure_link "$REPO_ROOT/ghostty" "$HOME/.config/ghostty" "ghostty" || rc=1
    # Ghostty has no leader, same as foot, so the Linux config (Herdr owns
    # ctrl+a) fits. config.toml is the Windows one, built around WezTerm's leader.
    ensure_link "$REPO_ROOT/herdr/config.linux.toml" "$HOME/.config/herdr/config.toml" "herdr" || rc=1
    return $rc
}

do_unlink() {
    header "Unlinking configs"

    remove_link "$REPO_ROOT/nvim"    "$HOME/.config/nvim"    "nvim"
    remove_link "$REPO_ROOT/ghostty" "$HOME/.config/ghostty" "ghostty"
    remove_link "$REPO_ROOT/herdr/config.linux.toml" "$HOME/.config/herdr/config.toml" "herdr"
}

do_doctor() {
    header "Environment check"
    local failures=0

    step "tooling"
    if has brew; then ok "brew present"; else fail "brew not found"; failures=$((failures+1)); fi

    step "commands on PATH"
    for cmd in nvim git rg fd; do
        if has "$cmd"; then
            ok "$cmd -> $(command -v "$cmd")"
        else
            fail "$cmd not on PATH"; failures=$((failures+1))
        fi
    done

    # The cask installs an app bundle; there is no ghostty command on PATH.
    if [ -d /Applications/Ghostty.app ] || [ -d "$HOME/Applications/Ghostty.app" ]; then
        ok "Ghostty.app installed"
    else
        fail "Ghostty.app not found"; failures=$((failures+1))
    fi

    step "neovim version"
    if has nvim; then
        local ver; ver="$(nvim --version | head -1)"
        ok "$ver"
    fi

    step "config links"
    for pair in "nvim:$HOME/.config/nvim:nvim" "ghostty:$HOME/.config/ghostty:ghostty"                 "herdr:$HOME/.config/herdr/config.toml:herdr/config.linux.toml"; do
        local label="${pair%%:*}" rest="${pair#*:}"
        local link="${rest%%:*}" expected="$REPO_ROOT/${rest#*:}"
        if [ -L "$link" ]; then
            local current; current="$(readlink "$link")"
            if [ "$current" = "$expected" ]; then
                ok "$label -> $current"
            else
                fail "$label -> $current (expected $expected)"
                failures=$((failures+1))
            fi
        elif [ -e "$link" ]; then
            fail "$label exists but is not a symlink: $link"
            failures=$((failures+1))
        else
            fail "$label not linked ($link missing)"
            info "fix: ./dot-mac.sh link"
            failures=$((failures+1))
        fi
    done

    step "optional tooling"
    for cmd in herdr claude; do
        if has "$cmd"; then ok "$cmd -> $(command -v "$cmd")"; else info "$cmd not installed (optional)"; fi
    done

    echo
    if [ "$failures" -gt 0 ]; then
        red "  $failures checks failed"
    else
        green "  all checks passed"
    fi
    # Exit codes wrap at 256; the count is already printed above.
    [ "$failures" -eq 0 ]
}

do_init() {
    header "dotfiles init (macOS)"
    info "repo: $REPO_ROOT"

    do_install
    do_link
    if do_doctor; then
        echo
        ok "Ready."
        info "Run nvim once and let lazy.nvim and Mason finish."
    else
        echo
        warn "Setup finished with failures. See above."
        return 1
    fi
}

do_update() {
    header "Updating"

    step "git pull"
    # dmmulroy runs a plain `git pull`. --rebase --autostash goes further so a
    # plain clone with local tweaks (committed or not) still updates: no fork
    # needed just to keep personal changes.
    if (cd "$REPO_ROOT" && git pull --rebase --autostash); then
        ok "repo up to date"
    else
        fail "git pull failed; your changes conflict with upstream."
        info "resolve and 'git rebase --continue', or 'git rebase --abort', then re-run"
        return 1
    fi

    step "brew upgrade"
    brew bundle --file="$BREWFILE"
    brew upgrade
    ok "packages updated"

    do_link
    do_doctor
}

show_help() {
    cat <<'EOF'

dot-mac.sh - bootstrap and maintain this terminal environment (macOS)

  Usage: ./dot-mac.sh <command>

  Commands:
    init         install packages, link configs, then verify
    install      install the Brewfile packages
    link         create config symlinks
    unlink       remove config symlinks
    doctor       diagnose the environment
    update       git pull, upgrade packages, re-link, verify
    help         this message

  Everything is idempotent and needs no sudo (besides Homebrew itself).

EOF
}

# ── dispatch ─────────────────────────────────────────────────────────────────

case "${1:-help}" in
    init)    do_init ;;
    install) do_install ;;
    link)    do_link ;;
    unlink)  do_unlink ;;
    doctor)  do_doctor ;;
    update)  do_update ;;
    help)    show_help ;;
    *)       fail "unknown command: $1"; show_help; exit 1 ;;
esac
