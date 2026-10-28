#!/bin/sh
# Runs at every sway start; does something only on a fresh machine (idempotent):
#   - picks the shipped wallpaper in DMS when none is chosen yet
#   - generates the monitor layout when this machine has none
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
walls=$HOME/.local/share/backgrounds

# wait until DMS has registered its IPC targets (up to ~40 s)
i=0
while [ "$i" -lt 40 ]; do
    dms ipc show 2>/dev/null | grep -q '^target wallpaper' && break
    i=$((i+1)); sleep 1
done
cur=$(dms ipc call wallpaper get 2>/dev/null | head -1)

# DMS prints the path when a wallpaper is set; anything else means "none yet"
case "$cur" in
    /*) ;;
    *) [ -f "$walls/kitty.jpg" ] && dms ipc call wallpaper set "$walls/kitty.jpg" >/dev/null 2>&1 ;;
esac

# monitor layout (laptop panel left, the rest to the right); the file is per machine
[ -e "$cfg/sway/config.d/05-outputs.conf" ] || "$cfg/sway/outputs-setup.sh" --auto >/dev/null 2>&1
exit 0
