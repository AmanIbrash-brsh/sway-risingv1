#!/bin/bash
choice=$(printf '%s\n' '  Area → clipboard' '  Area → file' '  Screen → clipboard' '  Screen → file' \
    | rofi -dmenu -i -p "Screenshot" -theme ~/.config/rofi/catppuccin.rasi \
    -theme-str 'window {width: 380px;} listview {lines: 4;} entry {enabled: false;}')
dir=$HOME/Pictures/Screenshots; mkdir -p "$dir"
f=$dir/$(date +%F_%H-%M-%S).png
case "$choice" in
    *"Area → clipboard") ~/.config/sway/screenshot.sh clip ;;
    *"Area → file")      ~/.config/sway/screenshot.sh file ;;
    *"Screen → clipboard") sleep 0.3; grim - | wl-copy ;;
    *"Screen → file")    sleep 0.3; grim "$f" ;;
    *) exit 0 ;;
esac
notify-send -t 2000 "Screenshot" "Saved"
