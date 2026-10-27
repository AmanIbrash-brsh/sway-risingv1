#!/bin/bash
# Power menu in rofi
opts=$'  Lock\n  Logout\n  Suspend\n  Reboot\n  Shutdown'
choice=$(printf '%s' "$opts" | rofi -dmenu -i -p "Power" -theme ~/.config/rofi/catppuccin.rasi -theme-str 'window {width: 300px;} listview {lines: 5;} entry {enabled: false;}')
case "$choice" in
    *Lock) swaylock -f ;;
    *Logout) swaymsg exit ;;
    *Suspend) systemctl suspend ;;
    *Reboot) systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
