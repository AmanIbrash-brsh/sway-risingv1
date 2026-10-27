#!/bin/sh
# Lock with swaylock-effects (blur + clock) if installed, else plain swaylock.
pgrep -x swaylock >/dev/null && exit 0
fx=$HOME/.local/bin/swaylock-effects
if [ -x "$fx" ]; then
    exec "$fx" -f -C "$HOME/.config/swaylock/config-effects"
fi
exec swaylock -f
