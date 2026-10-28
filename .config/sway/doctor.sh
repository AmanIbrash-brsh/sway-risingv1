#!/usr/bin/env bash
# Health check for the sway-rising setup. Prints OK / WARN / FAIL per item. Exit code = number of FAILs.
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
fails=0
ok()   { printf '  \033[32mOK\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fails=$((fails+1)); }
have() { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n\033[1m%s\033[0m\n' "$*"; }

section "Compositor"
if have sway; then
    v=$(sway --version 2>/dev/null | head -1); ok "$v"
    case $v in *swayfx*) ok "SwayFX (blur, shadows, rounded corners available)";; *) warn "plain sway: effects are disabled";; esac
    sway -C >/dev/null 2>&1 && ok "sway config is valid" || bad "sway -C reports errors"
else bad "sway / swayfx not installed"; fi
[ -n "${SWAYSOCK:-}" ] && ok "running inside sway" || warn "not inside a sway session (some checks skipped)"

section "Shell (DMS)"
if have dms; then
    ok "dms installed"
    pgrep -x dms >/dev/null && ok "dms is running" || { [ -n "${SWAYSOCK:-}" ] && bad "dms is not running" || warn "dms not running (not in session)"; }
else bad "dms not installed"; fi
[ -f "$CFG/dms/settings.json" ] && ok "DMS settings present" || warn "no DMS settings yet"
if have dms && pgrep -x dms >/dev/null; then
    w=$(dms ipc call wallpaper get 2>/dev/null | head -1)
    case $w in /*) ok "wallpaper set in DMS ($(basename "$w"))";; *) warn "no wallpaper chosen in DMS yet (firstrun.sh sets one at the next sway start)";; esac
fi

section "Session / portals"
if systemctl --user is-active sway-session.target >/dev/null 2>&1; then ok "sway-session.target active"
else [ -n "${SWAYSOCK:-}" ] && bad "sway-session.target inactive (portals will not start)" || warn "sway-session.target inactive (not in session)"; fi
if [ -n "${SWAYSOCK:-}" ] && have gdbus; then
    timeout 10 gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.DBus.Properties.Get org.freedesktop.portal.Settings version >/dev/null 2>&1 \
        && ok "xdg-desktop-portal reachable" || bad "xdg-desktop-portal unreachable"
fi

section "Fonts and theme"
fc-list 2>/dev/null | grep -qi "JetBrains Mono" && ok "JetBrains Mono" || bad "JetBrains Mono missing"
fc-list 2>/dev/null | grep -qiE "Font ?Awesome" && ok "Font Awesome" || warn "Font Awesome missing (some icons)"
{ [ -d /usr/share/themes/adw-gtk3-dark ] || [ -d "$HOME/.local/share/themes/adw-gtk3-dark" ]; } && ok "adw-gtk3 theme" || warn "adw-gtk3 theme missing (GTK apps will not follow the palette)"

section "Terminal and shell tools"
for t in kitty zsh tmux git fzf zoxide eza bat fd rg ncdu lazygit; do
    have "$t" || { [ "$t" = fd ] && have fdfind; } && ok "$t" || warn "$t missing"
done
[ -d "$HOME/.oh-my-zsh" ] && ok "oh-my-zsh" || warn "oh-my-zsh missing"
[ "$(basename "${SHELL:-}")" = zsh ] && ok "login shell is zsh" || warn "login shell is not zsh (run: chsh -s $(command -v zsh || echo /usr/bin/zsh))"

section "Per-machine config"
[ -f "$CFG/sway/config.d/05-outputs.conf" ] && ok "monitor layout (05-outputs.conf)" || warn "no monitor layout yet: run ~/.config/sway/outputs-setup.sh inside sway"
for t in nautilus grim swappy jq swaylock swayidle brightnessctl wl-copy notify-send; do have "$t" && ok "$t" || warn "$t missing"; done

printf '\n'; [ "$fails" -eq 0 ] && echo "No failures." || echo "$fails failure(s)."
exit "$fails"
