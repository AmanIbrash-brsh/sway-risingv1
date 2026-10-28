#!/bin/sh
# Lock with DankMaterialShell (matches the shell theme). Fall back to swaylock-effects / swaylock
# when DMS is not running or the IPC call fails.
pgrep -x swaylock >/dev/null && exit 0
if pgrep -x dms >/dev/null && timeout 3 dms ipc call lock lock >/dev/null 2>&1; then
    exit 0
fi
fx=$HOME/.local/bin/swaylock-effects
if [ -x "$fx" ]; then
    exec "$fx" -f -C "$HOME/.config/swaylock/config-effects"
fi
exec swaylock -f
