#!/usr/bin/env bash
# sway-rising installer (Fedora): the "glass" look on SwayFX + DankMaterialShell, with kitty,
# fonts, wallpaper, hotkeys and screenshots. Your existing configs are backed up first.
#
# Usage: ./install.sh [options]
#   -y, --yes          do not ask questions (non-interactive)
#       --dry-run      print what would be done, change nothing
#       --check        only run the health check and exit
#       --restore [DIR]  put your old configs back from a backup (default: the OLDEST ~/rice-backup-*, i.e. before the rice)
#       --layouts L    keyboard layouts, e.g. "us,de" (default: ask; "us,ru" with --yes)
#       --no-packages  configs only, skip package installation
#       --no-dms       do not install DankMaterialShell
#       --with-shell   also install zsh, oh-my-zsh, tmux and CLI tools (fzf, zoxide, eza, ...) with their configs
#       --force-shell  with --with-shell: replace an existing ~/.zshrc (the old one is backed up)
#   -h, --help
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
WALLS=$HOME/.local/share/backgrounds
STAMP=$(date +%F-%H%M%S)
BACKUP=$HOME/rice-backup-$STAMP
n=1; while [ -e "$BACKUP" ]; do n=$((n+1)); BACKUP=$HOME/rice-backup-$STAMP-$n; done      # never reuse a backup folder
MANAGED_DIRS=(sway swaylock kitty dms swappy)            # configs this repo owns
PRESERVE=(sway/config.d/07-input.conf dms/settings.json)   # meant to be edited by the user: installed only when missing
LEGACY_DIRS=(waybar rofi dunst swaync)                   # older versions of the rice; only backed up

YES=0; DRY=0; CHECK=0; RESTORE=0; RESTORE_DIR=""; PACKAGES=1; DMS=1; WITH_SHELL=0; FORCE_SHELL=0; LAYOUTS=""
while [ $# -gt 0 ]; do
    case $1 in
        -y|--yes) YES=1 ;;
        --dry-run) DRY=1 ;;
        --check) CHECK=1 ;;
        --restore) RESTORE=1; if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then RESTORE_DIR=$2; shift; fi ;;
        --layouts) [ $# -gt 1 ] || { echo "--layouts needs a value" >&2; exit 1; }; LAYOUTS=$2; shift ;;
        --no-packages) PACKAGES=0 ;;
        --no-dms) DMS=0 ;;
        --with-shell) WITH_SHELL=1 ;;
        --force-shell) FORCE_SHELL=1 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
    esac
    shift
done

say()  { printf '\033[1;37m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
ask()  { [ "$YES" = 1 ] && return 0; read -r -p "$1 [y/N] " r || return 1; [[ $r =~ ^[yYдД] ]]; }
run()  { if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

FAILED=()   # steps that did not work, shown at the end
NOTES=()    # follow-up hints for the user

# ---------------------------------------------------------------- packages (Fedora names, all verified with dnf)
CORE_PKGS=(
    sway-systemd dbus-tools                        # session target + env for portals
    kitty nautilus swaylock swayidle grim swappy jq wl-clipboard brightnessctl libnotify
    network-manager-applet wireplumber pipewire-pulseaudio
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    jetbrains-mono-fonts fontawesome-6-free-fonts adw-gtk3-theme
)
SHELL_PKGS=(zsh tmux git curl fzf zoxide eza bat fd-find ripgrep ncdu fastfetch)

check_fedora() {
    local ID="" ID_LIKE=""
    [ -r /etc/os-release ] && . /etc/os-release
    case " $ID $ID_LIKE " in *" fedora "*) return 0 ;; esac
    return 1
}

dnf_install() { [ $# -gt 0 ] || return 0
    if run sudo dnf install -y "$@"; then return 0; fi
    warn "Batch install failed, retrying package by package"
    local p; for p in "$@"; do run sudo dnf install -y "$p" || FAILED+=("package:$p"); done
}

install_swayfx() {
    if have sway && sway --version 2>/dev/null | grep -qi swayfx; then say "SwayFX already installed"; return 0; fi
    say "SwayFX comes from the swayfx/swayfx COPR (it conflicts with the stock 'sway' package)"
    if rpm -q sway >/dev/null 2>&1; then
        warn "Stock 'sway' is installed. Remove it first:  sudo dnf remove sway sway-config-fedora   then re-run."
        FAILED+=("swayfx: stock sway is in the way"); return 0
    fi
    if ask "Enable COPR swayfx/swayfx and install swayfx?"; then
        run sudo dnf copr enable -y swayfx/swayfx && dnf_install swayfx || FAILED+=("swayfx")
    else warn "Skipping swayfx: the effects (blur, shadows, rounding) need it."; fi
}

install_dms() {
    if have dms; then say "DankMaterialShell already installed"; return 0; fi
    say "DankMaterialShell (bar, launcher, control center, notifications) comes from the avengemedia/dms COPR"
    if ask "Enable COPR avengemedia/dms and install dms?"; then
        run sudo dnf copr enable -y avengemedia/dms && dnf_install dms || FAILED+=("dms")
    else warn "Skipping dms: no bar / control center / notifications will be started."; fi
}

# lazygit is not in Fedora: official release binary, checksum verified (only with --with-shell)
install_lazygit() {
    have lazygit && return 0
    local arch; case $(uname -m) in x86_64) arch=x86_64 ;; aarch64) arch=arm64 ;; *) warn "lazygit: unsupported arch"; return 0 ;; esac
    say "Installing lazygit (official release binary)"
    if [ "$DRY" = 1 ]; then echo "   [dry-run] download lazygit_*_linux_$arch.tar.gz, verify sha256, install to ~/.local/bin"; return 0; fi
    local tmp tag ver; tmp=$(mktemp -d)
    tag=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
    if [ -z "$tag" ]; then warn "lazygit: could not get the latest version"; FAILED+=("lazygit"); rm -rf "$tmp"; return 0; fi
    ver=${tag#v}
    local base=https://github.com/jesseduffield/lazygit/releases/download/$tag asset=lazygit_${ver}_linux_${arch}.tar.gz
    if ( cd "$tmp" && curl -fsSLO "$base/$asset" && curl -fsSLO "$base/checksums.txt" \
         && [ "$(grep " $asset\$" checksums.txt | awk '{print $1}')" = "$(sha256sum "$asset" | awk '{print $1}')" ] \
         && tar -xzf "$asset" lazygit ); then
        install -Dm755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
    else warn "lazygit: download or checksum failed"; FAILED+=("lazygit"); fi
    rm -rf "$tmp"
}

# ---------------------------------------------------------------- zsh / oh-my-zsh (only with --with-shell)
install_shell_extras() {
    local zsh_custom=$HOME/.oh-my-zsh/custom p
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        say "Installing oh-my-zsh"
        run git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || FAILED+=("oh-my-zsh")
    fi
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
        [ -d "$zsh_custom/plugins/$p" ] || run git clone --depth 1 "https://github.com/zsh-users/$p.git" "$zsh_custom/plugins/$p" || FAILED+=("zsh plugin $p")
    done
    if [ "$(basename "${SHELL:-}")" != zsh ] && have zsh; then
        if ask "Make zsh your login shell (chsh)?"; then run chsh -s "$(command -v zsh)" || NOTES+=("chsh failed; run: chsh -s $(command -v zsh)"); fi
    fi
}

# ---------------------------------------------------------------- configs
choose_layouts() {
    [ -n "$LAYOUTS" ] && return 0
    if [ "$YES" = 1 ] || [ ! -t 0 ] || [ "$DRY" = 1 ]; then return 0; fi     # keep the shipped "us,ru"
    read -r -p "Keyboard layouts, comma separated (first one must be Latin) [us,ru]: " LAYOUTS || LAYOUTS=""
}

apply_layouts() {
    [ -n "$LAYOUTS" ] && [ "$LAYOUTS" != "us,ru" ] || return 0
    if ! [[ $LAYOUTS =~ ^[a-z0-9_,()-]+$ ]]; then warn "Ignoring odd layout string '$LAYOUTS'"; return 0; fi
    say "Keyboard layouts: $LAYOUTS"
    if [ "$DRY" = 1 ]; then echo "   [dry-run] set xkb_layout \"$LAYOUTS\" in config.d/07-input.conf"; return 0; fi
    sed -i "s|xkb_layout \".*\"|xkb_layout \"$LAYOUTS\"|" "$CFG/sway/config.d/07-input.conf"
}

backup_and_copy_configs() {
    say "Backing up existing configs to $BACKUP"
    run mkdir -p "$BACKUP"
    local d
    for d in "${MANAGED_DIRS[@]}" "${LEGACY_DIRS[@]}"; do
        if [ -e "$CFG/$d" ]; then run cp -a "$CFG/$d" "$BACKUP/"; fi
    done

    say "Copying configs to $CFG"
    run mkdir -p "$CFG"
    # files the user is meant to edit (keyboard, DMS theme) are installed only when missing; 99-*.conf are never in the repo
    local kept=() f tmp
    tmp=$(mktemp -d)
    for f in "${PRESERVE[@]}"; do
        if [ "$DRY" = 0 ] && [ -f "$CFG/$f" ]; then mkdir -p "$tmp/$(dirname "$f")"; cp -a "$CFG/$f" "$tmp/$f"; kept+=("$f"); fi
    done
    if [ "$DRY" = 1 ]; then echo "   [dry-run] cp -a $REPO/.config/. $CFG/  (keeping existing: ${PRESERVE[*]})"; else cp -a "$REPO/.config/." "$CFG/"; fi
    for f in "${kept[@]}"; do cp -a "$tmp/$f" "$CFG/$f"; NOTES+=("Kept your existing $f (not overwritten)"); done
    rm -rf "$tmp"
    run rm -f "$CFG/sway/config.d/40-bar.conf"      # waybar is replaced by DMS; a stale file from an old version would start a second bar
    if [ "$DRY" = 0 ]; then chmod +x "$CFG"/sway/*.sh 2>/dev/null || true; fi
    run mkdir -p "$HOME/Pictures/Screenshots"

    if [ "$WITH_SHELL" = 1 ] && [ -d "$REPO/home" ]; then
        say "Copying shell/tmux files into $HOME (existing ones are backed up)"
        local f
        while IFS= read -r f; do
            if [ "$f" = ".zshrc" ] && [ -e "$HOME/.zshrc" ] && [ "$FORCE_SHELL" = 0 ]; then
                NOTES+=("Your ~/.zshrc was kept. To use the rice's one: ./install.sh --with-shell --force-shell (the old one is backed up)"); continue
            fi
            if [ -e "$HOME/$f" ]; then run mkdir -p "$BACKUP/$(dirname "$f")"; run cp -a "$HOME/$f" "$BACKUP/$f"; fi
            run mkdir -p "$HOME/$(dirname "$f")"
            run cp -a "$REPO/home/$f" "$HOME/$f"
        done < <(cd "$REPO/home" && find . -type f | sed 's|^\./||')
    fi
    install_wallpapers
}

# Wallpapers are managed by DMS; we only drop the shipped favourites into its folder.
# The first sway start (firstrun.sh) picks one in DMS if none is chosen yet.
install_wallpapers() {
    compgen -G "$REPO/wallpapers/*" >/dev/null || return 0
    say "Copying wallpapers to $WALLS"
    run mkdir -p "$WALLS"
    if [ "$DRY" = 1 ]; then echo "   [dry-run] cp -n wallpapers/* $WALLS/"; else cp -n "$REPO"/wallpapers/* "$WALLS/"; fi
}

# GTK theme: adw-gtk3 (DMS recolors it)
apply_gtk_theme() {
    have gsettings || return 0
    [ -d /usr/share/themes/adw-gtk3-dark ] || return 0
    run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
}

setup_outputs() {
    if [ -e "$CFG/sway/config.d/05-outputs.conf" ]; then say "Monitor layout already configured (05-outputs.conf)"; return 0; fi
    if [ -n "${SWAYSOCK:-}" ] && [ "$DRY" = 0 ]; then
        say "Generating the monitor layout"
        "$CFG/sway/outputs-setup.sh" --auto || true
    else
        NOTES+=("Monitors: the first sway start generates the layout automatically; fine-tune with ~/.config/sway/outputs-setup.sh")
    fi
}

verify() {
    if have sway && [ "$DRY" = 0 ]; then
        if sway -C >/dev/null 2>&1; then say "sway config is valid"; else warn "sway -C reported a problem; run: sway -C"; FAILED+=("sway config check"); fi
    fi
    if [ -n "${SWAYSOCK:-}" ] && have swaymsg && [ "$DRY" = 0 ]; then
        swaymsg reload >/dev/null && say "sway reloaded"
    else
        NOTES+=("Log out and pick the 'Sway' session on the login screen to see the result.")
    fi
}

# ---------------------------------------------------------------- restore
restore_backup() {
    local src=$RESTORE_DIR
    # the oldest backup holds your configs from before the rice; newer ones hold earlier installs of the rice itself
    [ -n "$src" ] || src=$(ls -d "$HOME"/rice-backup-* 2>/dev/null | sort | head -1 || true)
    if [ -z "$src" ] || [ ! -d "$src" ]; then warn "No backup found (looked for $HOME/rice-backup-*)"; exit 1; fi
    say "Restoring from $src"
    ask "This replaces the rice configs in $CFG with the backed up ones. Continue?" || exit 0
    local e name d
    for e in "$src"/* "$src"/.[!.]*; do
        [ -e "$e" ] || continue
        name=$(basename "$e")
        case $name in
            .*) run cp -a "$e" "$HOME/" ;;                       # shell/tmux files
            *)  run rm -rf "$CFG/$name"; run cp -a "$e" "$CFG/" ;;
        esac
    done
    for d in "${MANAGED_DIRS[@]}"; do
        [ -e "$src/$d" ] || NOTES+=("$d had no config before the install, so it was left as is: remove it with  rm -rf $CFG/$d")
    done
    NOTES+=("Packages are not removed. To drop the rice: sudo dnf remove swayfx dms   (then pick your old session at login)")
}

# ---------------------------------------------------------------- main
if [ "$CHECK" = 1 ]; then exec "$REPO/.config/sway/doctor.sh"; fi
if [ "$(id -u)" = 0 ]; then warn "Do not run as root; the script uses sudo where needed."; exit 1; fi

if [ "$RESTORE" = 1 ]; then
    restore_backup
    if [ ${#NOTES[@]} -gt 0 ]; then printf '\033[1mNext steps:\033[0m\n'; printf '  - %s\n' "${NOTES[@]}"; fi
    exit 0
fi

if check_fedora; then say "Fedora detected"; else
    warn "This installer is for Fedora. Packages are skipped, configs only."; PACKAGES=0
fi
[ "$DRY" = 1 ] && say "DRY RUN: nothing will be changed"
choose_layouts

if [ "$PACKAGES" = 1 ]; then
    say "Installing core packages (${#CORE_PKGS[@]})"
    dnf_install "${CORE_PKGS[@]}"
    install_swayfx
    if [ "$DMS" = 1 ]; then install_dms; fi
    if [ "$WITH_SHELL" = 1 ]; then
        say "Installing shell packages (${#SHELL_PKGS[@]})"
        dnf_install "${SHELL_PKGS[@]}"
        install_lazygit
    fi
fi

backup_and_copy_configs
apply_layouts
if [ "$PACKAGES" = 1 ]; then apply_gtk_theme; fi
if [ "$WITH_SHELL" = 1 ]; then install_shell_extras; fi
setup_outputs
verify

echo
echo "Backup of your old configs: $BACKUP   (undo with: ./install.sh --restore)"
if [ ${#FAILED[@]} -gt 0 ]; then printf '\033[1;33mDid not work:\033[0m\n'; printf '  - %s\n' "${FAILED[@]}"; fi
if [ ${#NOTES[@]} -gt 0 ]; then printf '\033[1mNext steps:\033[0m\n'; printf '  - %s\n' "${NOTES[@]}"; fi
cat <<EOF

Health check any time:  ./install.sh --check      (or ~/.config/sway/doctor.sh)
Hotkeys: Super+F1 cheatsheet, Super+D launcher, Super+N control center, Print screenshot, Super+Shift+X lock.
Your own tweaks go into ~/.config/sway/config.d/99-personal.conf (never touched by this script).
EOF
