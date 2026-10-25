#!/usr/bin/env bash
# Bootstrap and maintain this terminal environment on Linux (Omarchy).
#
# The Linux twin of dot.ps1, with the same commands. Links this repository's
# configs into the paths Neovim and Herdr read, and diagnoses the ways that
# wiring silently rots. foot is the terminal and Omarchy configures it, so
# there is nothing to link for it.
#
#   ./dot.sh init
#   ./dot.sh init --with-agents
#   ./dot.sh doctor

set -uo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
MANIFEST=$REPO_ROOT/packages/pacman.txt
NVIM_LINK=$CONFIG_HOME/nvim
NVIM_TARGET=$REPO_ROOT/nvim
HERDR_LINK=$CONFIG_HOME/herdr/config.toml
HERDR_TARGET=$REPO_ROOT/herdr/config.linux.toml
LAZY_LOCK=$REPO_ROOT/nvim/lazy-lock.json
BASH_RC=$REPO_ROOT/bash/bashrc
# Sourced from ~/.bashrc; the match is on the path, so the line can be edited.
BASH_RC_LINE="[[ -r \"$BASH_RC\" ]] && source \"$BASH_RC\""

WITH_AGENTS=0
SKIP_INSTALL=0
YES=0
FAILURES=0
WARNINGS=0

if [[ -t 1 ]]; then
	C_MAGENTA=$'\e[35m' C_CYAN=$'\e[36m' C_GREEN=$'\e[32m' C_YELLOW=$'\e[33m'
	C_RED=$'\e[31m' C_DIM=$'\e[90m' C_RESET=$'\e[0m'
else
	C_MAGENTA='' C_CYAN='' C_GREEN='' C_YELLOW='' C_RED='' C_DIM='' C_RESET=''
fi

header() { printf '\n%s=> %s%s\n' "$C_MAGENTA" "$1" "$C_RESET"; }
step() { printf '\n%s-- %s%s\n' "$C_CYAN" "$1" "$C_RESET"; }
ok() { printf '%s  [ ok ] %s%s\n' "$C_GREEN" "$1" "$C_RESET"; }
warn() { printf '%s  [warn] %s%s\n' "$C_YELLOW" "$1" "$C_RESET"; }
fail() { printf '%s  [FAIL] %s%s\n' "$C_RED" "$1" "$C_RESET"; }
info() { printf '%s         %s%s\n' "$C_DIM" "$1" "$C_RESET"; }

add_fail() { fail "$1"; FAILURES=$((FAILURES + 1)); }
add_warn() { warn "$1"; WARNINGS=$((WARNINGS + 1)); }

confirm() {
	((YES)) && return 0
	local reply
	while true; do
		read -r -p "$1 [y/N] " reply || return 1
		case ${reply,,} in
		y | yes) return 0 ;;
		'' | n | no) return 1 ;;
		esac
	done
}

read_manifest() {
	if [[ ! -f $MANIFEST ]]; then
		fail "package manifest not found: $MANIFEST"
		return 1
	fi
	sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$MANIFEST"
}

# Moves a real file or directory aside so a link can take its place. Omarchy
# ships its own nvim and herdr configs, so on a fresh install there is always
# something here; refusing outright, as dot.ps1 does, would make init always fail.
backup_path() {
	local path=$1 label=$2 backup
	backup="$path.bak-$(date +%Y%m%d-%H%M%S)"
	if ! confirm "  $label: move existing $path to $backup?"; then
		warn "$label left unchanged"
		return 1
	fi
	mv -- "$path" "$backup" && ok "$label backed up to $backup"
}

link_path() {
	local link=$1 target=$2 label=$3
	if [[ ! -e $target ]]; then
		fail "$label target missing from the repo: $target"
		return 1
	fi
	mkdir -p -- "$(dirname -- "$link")"

	if [[ -L $link ]]; then
		local current
		current=$(readlink -f -- "$link")
		if [[ $current == "$target" ]]; then
			ok "$label link already correct"
			return 0
		fi
		warn "$label link points at $(readlink -- "$link")"
		if ! confirm "  Repoint it to $target?"; then
			warn "$label left unchanged"
			return 1
		fi
		rm -- "$link"
	elif [[ -e $link ]]; then
		backup_path "$link" "$label" || return 1
	fi

	if ln -s -- "$target" "$link"; then
		ok "$label -> $target"
		return 0
	fi
	fail "$label link failed"
	return 1
}

# Removes the link only if it points into this repo, then restores the newest
# backup link_path made, so Omarchy's own config comes back.
unlink_path() {
	local link=$1 target=$2 label=$3
	if [[ ! -L $link ]]; then
		if [[ -e $link ]]; then warn "$label is a real path, left alone: $link"; else info "$label not linked"; fi
		return
	fi
	if [[ $(readlink -f -- "$link") != "$target" ]]; then
		warn "$label link points at $(readlink -- "$link"), not this repo. Left alone."
		return
	fi
	rm -- "$link"
	ok "$label link removed"

	local backup
	backup=$(compgen -G "$link.bak-*" | sort | tail -n 1)
	if [[ -n $backup ]]; then
		mv -- "$backup" "$link" && ok "$label restored from $backup"
	fi
}

set_bashrc() {
	local bashrc=$HOME/.bashrc
	if [[ -f $bashrc ]] && grep -qF -- "$BASH_RC" "$bashrc"; then
		ok '~/.bashrc already sources the repo'
		return 0
	fi
	# Appended, so it lands after Omarchy's rc and its bindings win.
	printf '\n# dotfiles: %s\n%s\n' "$REPO_ROOT" "$BASH_RC_LINE" >>"$bashrc"
	ok "~/.bashrc -> $BASH_RC"
}

unset_bashrc() {
	local bashrc=$HOME/.bashrc
	if [[ -f $bashrc ]] && grep -qF -- "$BASH_RC" "$bashrc"; then
		local tmp
		tmp=$(mktemp)
		grep -vF -e "$BASH_RC" -e "# dotfiles: $REPO_ROOT" "$bashrc" >"$tmp" && cat "$tmp" >"$bashrc"
		rm -f -- "$tmp"
		ok '~/.bashrc no longer sources the repo'
	else
		info '~/.bashrc does not source the repo'
	fi
}

# A running Herdr server keeps the config it started with.
reload_herdr() {
	command -v herdr >/dev/null || return 0
	if herdr server reload-config >/dev/null 2>&1; then
		ok 'running herdr reloaded its config'
	fi
}

cmd_install() {
	header 'Installing packages'
	if ! command -v pacman >/dev/null; then
		fail 'pacman not found; dot.sh targets Arch-based Omarchy'
		return 1
	fi

	local -a missing=()
	local pkg
	while read -r pkg; do
		if pacman -Q "$pkg" >/dev/null 2>&1; then ok "$pkg already installed"; else missing+=("$pkg"); fi
	done < <(read_manifest)

	local status=0
	if ((${#missing[@]})); then
		info "installing ${missing[*]}"
		# --needed and no -y: install what is missing, never a partial upgrade.
		# System upgrades belong to omarchy-update.
		if sudo pacman -S --needed --noconfirm "${missing[@]}"; then
			ok "installed ${missing[*]}"
		else
			fail "pacman failed for: ${missing[*]}"
			info 'Re-run ./dot.sh install to retry.'
			status=1
		fi
	fi

	((WITH_AGENTS)) && cmd_agents
	return $status
}

# Omarchy installs the agent CLIs through mise, so these go the same way.
cmd_agents() {
	step 'agent CLIs'
	if ! command -v mise >/dev/null; then
		fail 'mise not found'
		return 1
	fi
	local tool
	for tool in claude codex; do
		if command -v "$tool" >/dev/null; then
			ok "$tool already installed ($(command -v "$tool"))"
		elif mise use -g "$tool@latest"; then
			ok "$tool installed"
		else
			fail "$tool install failed"
		fi
	done
}

cmd_link() {
	header 'Linking configs'
	local status=0
	link_path "$NVIM_LINK" "$NVIM_TARGET" nvim || status=1
	link_path "$HERDR_LINK" "$HERDR_TARGET" herdr || status=1
	set_bashrc || status=1
	reload_herdr

	# The Linux counterpart of the stray .wezterm.lua: this outranks the link.
	if [[ -n ${HERDR_CONFIG_PATH:-} ]]; then
		fail "HERDR_CONFIG_PATH=$HERDR_CONFIG_PATH outranks $HERDR_LINK. Unset it."
		status=1
	fi
	return $status
}

cmd_unlink() {
	header 'Unlinking configs'
	if ! confirm 'Remove both links, restore backups, and drop the ~/.bashrc line?'; then
		warn 'aborted'
		return 0
	fi
	unlink_path "$NVIM_LINK" "$NVIM_TARGET" nvim
	unlink_path "$HERDR_LINK" "$HERDR_TARGET" herdr
	unset_bashrc
	reload_herdr
	return 0
}

cmd_check_packages() {
	header 'Package status'
	local pkg version missing=0
	while read -r pkg; do
		if version=$(pacman -Q "$pkg" 2>/dev/null); then
			printf '  %-18s %-10s %s\n' "$pkg" installed "${version#* }"
		else
			printf '  %-18s %s%-10s%s %s\n' "$pkg" "$C_RED" MISSING "$C_RESET" -
			missing=$((missing + 1))
		fi
	done < <(read_manifest)

	if ((missing)); then
		warn "$missing missing. Run ./dot.sh install"
		return 1
	fi
	ok 'all manifest packages installed'
}

check_link() {
	local link=$1 target=$2 label=$3
	if [[ ! -e $link && ! -L $link ]]; then
		add_fail "$label not linked ($link missing)"
		info 'fix: ./dot.sh link'
	elif [[ ! -L $link ]]; then
		add_fail "$label exists but is not a link: $link"
		info 'fix: ./dot.sh link (it offers to back the old one up)'
	elif [[ $(readlink -f -- "$link") != "$target" ]]; then
		add_fail "$label -> $(readlink -- "$link") (expected $target)"
	else
		ok "$label -> $target"
	fi
}

cmd_doctor() {
	header 'Environment check'
	FAILURES=0
	WARNINGS=0

	step 'packages'
	local pkg version
	while read -r pkg; do
		if version=$(pacman -Q "$pkg" 2>/dev/null); then ok "$version"; else add_fail "$pkg not installed"; fi
	done < <(read_manifest)

	step 'commands on PATH'
	local name
	for name in nvim git tree-sitter gcc rg fd wl-copy foot herdr; do
		if command -v "$name" >/dev/null; then ok "$name -> $(command -v "$name")"; else add_fail "$name not on PATH"; fi
	done

	step 'neovim version'
	if command -v nvim >/dev/null; then
		local first
		first=$(nvim --version | head -n 1)
		if [[ $first =~ v([0-9]+)\.([0-9]+) ]]; then
			if ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 11)); then
				ok "$first"
			else
				add_fail "$first is below 0.11; vim.lsp.config does not exist there"
			fi
		else
			add_warn 'could not parse nvim version'
		fi
	else
		add_fail 'nvim not found'
	fi

	step 'config links'
	check_link "$NVIM_LINK" "$NVIM_TARGET" nvim
	check_link "$HERDR_LINK" "$HERDR_TARGET" herdr
	if [[ -f $HOME/.bashrc ]] && grep -qF -- "$BASH_RC" "$HOME/.bashrc"; then
		ok '~/.bashrc sources bash/bashrc'
	else
		add_fail '~/.bashrc does not source bash/bashrc'
		info 'fix: ./dot.sh link'
	fi

	step 'herdr config'
	# Silent failure: a set HERDR_CONFIG_PATH beats the symlink, and Herdr runs
	# happily from whatever file it names.
	if [[ -n ${HERDR_CONFIG_PATH:-} ]]; then
		add_fail "HERDR_CONFIG_PATH=$HERDR_CONFIG_PATH outranks $HERDR_LINK"
		info 'fix: remove it from wherever it is exported, then open a new terminal'
	else
		ok 'HERDR_CONFIG_PATH unset; herdr reads the symlink'
	fi
	if command -v herdr >/dev/null; then
		local result
		result=$(HERDR_CONFIG_PATH=$HERDR_TARGET herdr config check 2>&1)
		if [[ $result == 'config: ok' ]]; then
			ok 'herdr/config.linux.toml validates'
		else
			add_fail 'herdr config check reported issues'
			while IFS= read -r line; do info "$line"; done <<<"$result"
		fi
	fi

	step 'neovim plugins'
	if [[ -f $LAZY_LOCK ]]; then ok 'nvim/lazy-lock.json present (plugin commits pinned)'; else add_warn 'nvim/lazy-lock.json missing; plugin versions are unpinned'; fi

	step 'optional tooling'
	for name in claude codex; do
		if command -v "$name" >/dev/null; then ok "$name -> $(command -v "$name")"; else info "$name not installed (optional)"; fi
	done

	echo
	if ((FAILURES)); then
		printf '%s  %d failed, %d warnings%s\n' "$C_RED" "$FAILURES" "$WARNINGS" "$C_RESET"
	elif ((WARNINGS)); then
		printf '%s  all checks passed, %d warnings%s\n' "$C_YELLOW" "$WARNINGS" "$C_RESET"
	else
		printf '%s  all checks passed%s\n' "$C_GREEN" "$C_RESET"
	fi
	((FAILURES == 0))
}

cmd_update() {
	header 'Updating'
	step 'git pull'
	if git -C "$REPO_ROOT" pull --ff-only; then ok 'repo up to date'; else warn 'git pull failed; uncommitted changes or a diverged branch?'; fi

	# Upgrading single packages is a partial upgrade on Arch, so this only fills
	# gaps. omarchy-update upgrades the whole system.
	cmd_install
	info 'System packages upgrade with omarchy-update, not here.'
	cmd_link
	cmd_doctor
}

cmd_init() {
	header 'dotfiles init'
	info "repo: $REPO_ROOT"
	if ((SKIP_INSTALL)); then
		info 'skipping package installation (--skip-install)'
	else
		cmd_install
	fi
	cmd_link

	if cmd_doctor; then
		echo
		ok 'Ready.'
		info 'Open a NEW terminal so ~/.bashrc picks up bash/bashrc.'
		info 'Then run nvim once and let lazy.nvim and Mason finish.'
		return 0
	fi
	echo
	warn 'Setup finished with failures. See above.'
	return 1
}

show_help() {
	cat <<EOF

${C_MAGENTA}dot.sh - bootstrap and maintain this terminal environment${C_RESET}

  Usage: ./dot.sh <command> [options]

  ${C_CYAN}Commands:${C_RESET}
    init             install packages, link configs, then verify
    install          install the pacman packages in packages/pacman.txt
    agents           install the agent CLIs (Claude Code, Codex) with mise
    link             symlink nvim and herdr, source bash/bashrc from ~/.bashrc
    unlink           remove the links, restore backups, drop the ~/.bashrc line
    doctor           diagnose the environment; exits non-zero on failure
    update           git pull, install anything missing, re-link, verify
    check-packages   list manifest packages against what is installed
    help             this message

  ${C_CYAN}Options:${C_RESET}
    --with-agents    also install the agent CLIs during init/install
    --skip-install   init links and verifies without installing
    -y, --yes        assume yes at every prompt

  ${C_DIM}Everything is idempotent. Only install asks for sudo, and only when
  something is missing.${C_RESET}

EOF
}

command=${1:-help}
(($#)) && shift
for arg in "$@"; do
	case $arg in
	--with-agents) WITH_AGENTS=1 ;;
	--skip-install) SKIP_INSTALL=1 ;;
	-y | --yes) YES=1 ;;
	*)
		fail "unknown option: $arg"
		show_help
		exit 1
		;;
	esac
done

case $command in
init) cmd_init ;;
install) cmd_install ;;
agents) cmd_agents ;;
link) cmd_link ;;
unlink) cmd_unlink ;;
doctor) cmd_doctor ;;
update) cmd_update ;;
check-packages) cmd_check_packages ;;
help | -h | --help) show_help ;;
*)
	fail "unknown command: $command"
	show_help
	exit 1
	;;
esac
