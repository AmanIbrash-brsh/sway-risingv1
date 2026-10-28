#!/usr/bin/env bash
# sway-rising installer: packages + configs + wallpapers + swaylock-effects.
# Usage: ./install.sh [--yes] [--no-packages] [--no-lock-effects]
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
WALLS=$HOME/Pictures/wallpapers
STAMP=$(date +%F-%H%M%S)
BACKUP=$HOME/rice-backup-$STAMP

YES=0; PACKAGES=1; LOCKFX=1
for a in "$@"; do
    case $a in
        -y|--yes) YES=1 ;;
        --no-packages) PACKAGES=0 ;;
        --no-lock-effects) LOCKFX=0 ;;
        -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

say()  { printf '\033[1;37m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
ask()  { [ "$YES" = 1 ] && return 0; read -r -p "$1 [y/N] " r; [[ $r =~ ^[yYдД] ]]; }

# ---------- 1. packages (Fedora) ----------
install_packages() {
    if ! command -v dnf >/dev/null; then
        warn "dnf not found. Install manually: swayfx waybar rofi dunst swaylock swayidle kitty grim slurp"
        warn "wl-clipboard playerctl brightnessctl ImageMagick libnotify pavucontrol network-manager-applet"
        warn "JetBrains Mono and Font Awesome 6 fonts."
        return
    fi

    local want=(waybar rofi dunst swaylock swayidle kitty grim slurp wl-clipboard playerctl
                brightnessctl ImageMagick libnotify pavucontrol network-manager-applet
                wireplumber fontawesome-6-free-fonts)
    fc-list | grep -qi "JetBrains Mono" || want+=(jetbrains-mono-fonts)

    local missing=() p
    for p in "${want[@]}"; do rpm -q "$p" >/dev/null 2>&1 || missing+=("$p"); done

    if ! rpm -q swayfx >/dev/null 2>&1; then
        say "swayfx is not installed (it lives in the swayfx/swayfx COPR)"
        if ask "Enable COPR swayfx/swayfx and install swayfx? (replaces nothing, but 'sway' conflicts)"; then
            sudo dnf copr enable -y swayfx/swayfx
            missing+=(swayfx)
        else
            warn "Skipping swayfx: effects will not work on plain sway."
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        say "Installing: ${missing[*]}"
        sudo dnf install -y "${missing[@]}"
    else
        say "All packages already installed"
    fi
}

# ---------- 2. swaylock-effects (side by side, system swaylock untouched) ----------
install_lock_effects() {
    local dest=$HOME/.local/bin/swaylock-effects
    if [ -x "$dest" ]; then say "swaylock-effects already installed"; return; fi
    command -v dnf >/dev/null || { warn "No dnf: put a swaylock-effects binary at $dest yourself"; return; }
    command -v cpio >/dev/null || { warn "cpio missing, skipping swaylock-effects"; return; }

    say "swaylock-effects: not in Fedora repos, it comes from the third-party COPR pheeef/swaylock-effects"
    ask "Enable that COPR and extract the binary into ~/.local/bin (does not replace system swaylock)?" || { warn "Skipped; plain swaylock will be used"; return; }

    sudo dnf copr enable -y pheeef/swaylock-effects
    local tmp; tmp=$(mktemp -d)
    ( cd "$tmp" && dnf download swaylock-effects \
        && rpm2cpio ./swaylock-effects-*.x86_64.rpm 2>/dev/null | cpio -idm 2>/dev/null \
        || bsdtar -xf ./swaylock-effects-*.x86_64.rpm 2>/dev/null )
    if [ -f "$tmp/usr/bin/swaylock" ]; then
        install -Dm755 "$tmp/usr/bin/swaylock" "$dest"
        say "Installed $dest ($("$dest" --version))"
    else
        warn "Could not extract swaylock-effects; plain swaylock will be used"
    fi
    rm -rf "$tmp"
}

# ---------- 3. configs ----------
install_configs() {
    say "Backing up existing configs to $BACKUP"
    mkdir -p "$BACKUP"
    local d
    for d in sway waybar rofi dunst swaylock kitty; do
        [ -e "$CFG/$d" ] && cp -a "$CFG/$d" "$BACKUP/"
    done

    say "Copying configs to $CFG"
    mkdir -p "$CFG"
    cp -a "$REPO/.config/." "$CFG/"
    chmod +x "$CFG"/sway/*.sh "$CFG"/rofi/*.sh 2>/dev/null || true

    say "Copying wallpapers to $WALLS"
    mkdir -p "$WALLS"
    cp -n "$REPO"/wallpapers/* "$WALLS/"
    [ -e "$WALLS/current" ] || ln -s "$WALLS/original.jpg" "$WALLS/current"
}

# ---------- 4. apply ----------
apply() {
    if command -v sway >/dev/null && sway -C >/dev/null 2>&1; then
        say "sway config is valid"
    else
        warn "sway -C reported a problem; check your config"
    fi
    if [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null; then
        swaymsg reload >/dev/null && say "sway reloaded (waybar restarts with it)"
    else
        say "Not inside sway: log in to a sway session to see the result"
    fi
}

[ "$PACKAGES" = 1 ] && install_packages
[ "$LOCKFX" = 1 ] && install_lock_effects
install_configs
apply

cat <<EOF

Done. Backup of your old configs: $BACKUP
Hotkeys: Super+F1 cheatsheet, Super+Shift+W wallpapers, Super+Shift+S screenshots,
         Super+Shift+X lock, Super+Shift+B performance mode.
EOF
