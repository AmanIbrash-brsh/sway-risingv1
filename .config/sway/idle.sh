#!/bin/sh
pkill -x swayidle
exec swayidle -w \
    timeout 300 "$HOME/.config/sway/lock.sh" \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep "$HOME/.config/sway/lock.sh"
