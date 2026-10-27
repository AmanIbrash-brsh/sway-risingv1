#!/bin/sh
# usage: screenshot.sh clip | file
geo=$(slurp) || exit 0
if [ "$1" = file ]; then
    dir=$HOME/Pictures/Screenshots
    mkdir -p "$dir"
    grim -g "$geo" "$dir/$(date +%F_%H-%M-%S).png"
else
    grim -g "$geo" - | wl-copy
fi
