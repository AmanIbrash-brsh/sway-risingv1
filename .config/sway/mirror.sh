#!/bin/bash
# Mirror the internal display to any external output (sway has no native mirroring).
# Watches output hotplug events; needs wl-mirror.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sway-mirror.lock"
flock -n 9 || exit 0

internal=eDP-1

sync() {
    pkill -x wl-mirror
    for ext in $(swaymsg -t get_outputs -r | jq -r --arg i "$internal" '.[] | select(.active and .name != $i) | .name'); do
        wl-mirror --fullscreen-output "$ext" "$internal" &
    done
}

sync
swaymsg -t subscribe -m '["output"]' | while read -r _; do
    sleep 1
    sync
done
