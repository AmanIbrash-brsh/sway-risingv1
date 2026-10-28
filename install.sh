#!/usr/bin/env bash
# sway-rising installer (Fedora): turns a fresh Fedora install into the full rice
# (SwayFX + DankMaterialShell, kitty, zsh/tmux, CLI tools, fonts, wallpapers, configs).
#
# Usage: ./install.sh [options]
#   -y, --yes          do not ask questions (non-interactive)
#       --dry-run      print what would be done, change nothing
#       --check        only run the health check and exit
#       --no-packages  configs only, skip package installation
#       --no-dms       do not install DankMaterialShell
#       --no-shell     skip zsh / oh-my-zsh / tmux / CLI tools
#       --with-tools   also install sysadmin tools (nmap, tcpdump, mtr, jq, ansible, btop)
#       --force-shell  overwrite an existing ~/.zshrc (the old one is backed up)
#   -h, --help
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
WALLS=$HOME/.local/share/backgrounds
STAMP=$(date +%F-%H%M%S)
BACKUP=$HOME/rice-backup-$STAMP

YES=0; DRY=0; CHECK=0; PACKAGES=1; DMS=1; SHELLSETUP=1; TOOLS=0; FORCE_SHELL=0
for a in "$@"; do
    case $a in
        -y|--yes) YES=1 ;;
        --dry-run) DRY=1 ;;
        --check) CHECK=1 ;;
        --no-packages) PACKAGES=0 ;;
        --no-dms) DMS=0 ;;
        --no-shell) SHELLSETUP=0 ;;
        --with-tools) TOOLS=1 ;;
        --force-shell) FORCE_SHELL=1 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $a (try --help)" >&2; exit 1 ;;
    esac
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
    sway-systemd                                   # session target + env for portals
    kitty swaylock swayidle grim swappy jq wl-clipboard brightnessctl libnotify
    pavucontrol network-manager-applet wireplumber pipewire-pulseaudio
    nautilus                                       # file manager (Super+O)
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    jetbrains-mono-fonts fontawesome-6-free-fonts adw-gtk3-theme
)
SHELL_PKGS=(zsh tmux git curl fzf zoxide eza bat fd-find ripgrep ncdu fastfetch)
TOOLS_PKGS=(nmap tcpdump mtr jq btop ansible)

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

# lazygit is not in Fedora: official release binary, checksum verified
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

# ---------------------------------------------------------------- zsh / oh-my-zsh
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
backup_and_copy_configs() {
    say "Backing up existing configs to $BACKUP"
    run mkdir -p "$BACKUP"
    local d
    for d in sway swaylock kitty dms swappy waybar rofi dunst swaync; do   # last four: legacy, only backed up
        if [ -e "$CFG/$d" ]; then run cp -a "$CFG/$d" "$BACKUP/"; fi
    done

    say "Copying configs to $CFG"
    run mkdir -p "$CFG"
    # the machine-specific monitor layout ships only as 05-outputs.conf.example (see outputs-setup.sh)
    if [ "$DRY" = 1 ]; then echo "   [dry-run] cp -a $REPO/.config/. $CFG/"; else cp -a "$REPO/.config/." "$CFG/"; fi
    run rm -f "$CFG/sway/config.d/40-bar.conf"      # waybar is replaced by DMS; a stale file would start a second bar
    run mkdir -p "$HOME/Pictures/Screenshots"
    if [ "$DRY" = 0 ]; then chmod +x "$CFG"/sway/*.sh 2>/dev/null || true; fi

    if [ -d "$REPO/home" ]; then
        say "Copying shell/tmux files into $HOME (existing ones are backed up)"
        local f
        while IFS= read -r f; do
            if [ "$f" = ".zshrc" ] && [ -e "$HOME/.zshrc" ] && [ "$FORCE_SHELL" = 0 ]; then
                NOTES+=("Your ~/.zshrc was kept. To use the rice's one: ./install.sh --force-shell (the old one is backed up)"); continue
            fi
            if [ -e "$HOME/$f" ]; then run mkdir -p "$BACKUP/$(dirname "$f")"; run cp -a "$HOME/$f" "$BACKUP/$f"; fi
            run mkdir -p "$HOME/$(dirname "$f")"
            run cp -a "$REPO/home/$f" "$HOME/$f"
        done < <(cd "$REPO/home" && find . -type f | sed 's|^\./||')
    fi

    install_wallpapers
}

# Wallpapers are managed by DMS (Settings > Wallpaper); we only drop the shipped favourites into its folder
install_wallpapers() {
    compgen -G "$REPO/wallpapers/*" >/dev/null || return 0
    say "Copying wallpapers to $WALLS"
    run mkdir -p "$WALLS"
    if [ "$DRY" = 1 ]; then echo "   [dry-run] cp -n wallpapers/* $WALLS/"; else cp -n "$REPO"/wallpapers/* "$WALLS/"; fi
    local cur=""
    if [ -n "${SWAYSOCK:-}" ] && have dms && pgrep -x dms >/dev/null; then cur=$(dms ipc call wallpaper get 2>/dev/null | head -1); fi
    if [ "$DRY" = 0 ] && [ -n "${SWAYSOCK:-}" ] && pgrep -x dms >/dev/null && [ -z "$cur" ] && [ -f "$WALLS/kitty.jpg" ]; then
        dms ipc call wallpaper set "$WALLS/kitty.jpg" >/dev/null 2>&1 || true      # only when no wallpaper is chosen yet
    elif [ -z "$cur" ]; then
        NOTES+=("Wallpaper: pick one in DMS (Super+N > settings > Wallpaper); the shipped ones are in $WALLS")
    fi
}

# GTK theme: adw-gtk3 (DMS recolors it); only when the user has no choice of their own yet
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
        if [ "$YES" = 1 ]; then "$CFG/sway/outputs-setup.sh" --auto || true; else "$CFG/sway/outputs-setup.sh" || true; fi
    else
        NOTES+=("Monitors: after logging into sway run  ~/.config/sway/outputs-setup.sh  (layout and scale for laptop + external screens)")
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

# ---------------------------------------------------------------- main
if [ "$CHECK" = 1 ]; then exec "$REPO/.config/sway/doctor.sh"; fi
if [ "$(id -u)" = 0 ]; then warn "Do not run as root; the script uses sudo where needed."; exit 1; fi

if check_fedora; then say "Fedora detected"; else
    warn "This installer is for Fedora. Packages are skipped, configs only."; PACKAGES=0
fi
[ "$DRY" = 1 ] && say "DRY RUN: nothing will be changed"

if [ "$PACKAGES" = 1 ]; then
    say "Installing core packages (${#CORE_PKGS[@]})"
    dnf_install "${CORE_PKGS[@]}"
    install_swayfx
    if [ "$DMS" = 1 ]; then install_dms; fi
    if [ "$SHELLSETUP" = 1 ]; then
        say "Installing shell packages (${#SHELL_PKGS[@]})"
        dnf_install "${SHELL_PKGS[@]}"
        install_lazygit
    fi
    if [ "$TOOLS" = 1 ]; then say "Installing sysadmin tools"; dnf_install "${TOOLS_PKGS[@]}"; fi
fi

backup_and_copy_configs
if [ "$PACKAGES" = 1 ]; then apply_gtk_theme; fi
if [ "$SHELLSETUP" = 1 ]; then install_shell_extras; fi
setup_outputs
verify

echo
echo "Backup of your old configs: $BACKUP"
if [ ${#FAILED[@]} -gt 0 ]; then printf '\033[1;33mDid not work:\033[0m\n'; printf '  - %s\n' "${FAILED[@]}"; fi
if [ ${#NOTES[@]} -gt 0 ]; then printf '\033[1mNext steps:\033[0m\n'; printf '  - %s\n' "${NOTES[@]}"; fi
cat <<EOF

Health check any time:  ./install.sh --check      (or ~/.config/sway/doctor.sh)
Hotkeys: Super+F1 cheatsheet, Super+D launcher, Super+N control center, Super+Shift+X lock.
EOF
