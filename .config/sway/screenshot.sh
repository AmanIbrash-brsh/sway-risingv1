#!/bin/sh
# Screenshots. Every capture goes to ~/Pictures/Screenshots AND the clipboard, with a notification.
# usage: screenshot.sh region | full | all | window | scroll | last | edit
#   region  select an area (DMS selector: drag, Enter/Space to confirm, Esc to cancel)
#   full    the focused monitor          all     all monitors in one image
#   window  the focused window           last    repeat the previous area
#   scroll  stitch a scrolling area into one tall image (Enter finishes)
#   edit    select an area and annotate it in swappy (arrows, text, blur; save/copy from there)
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
mode=${1:-region}

case "$mode" in
    region|full|all|last|scroll)
        exec dms screenshot "$mode" --dir "$dir" ;;
    window)
        # DMS cannot capture a single window on sway, so use grim on the focused container
        geo=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | head -1)
        [ -n "$geo" ] || { notify-send -u low "Screenshot" "No focused window"; exit 1; }
        f="$dir/$(date +%F_%H-%M-%S)_window.png"
        grim -g "$geo" "$f" && wl-copy < "$f" && notify-send -t 3000 -i "$f" "Screenshot" "Window saved and copied"
        ;;
    edit)
        if ! command -v swappy >/dev/null; then
            notify-send -u critical "Screenshot" "swappy is not installed: sudo dnf install swappy"; exit 1
        fi
        dms screenshot region --stdout --no-file --no-clipboard --no-notify | swappy -f -
        ;;
    *) echo "usage: $0 region|full|all|window|scroll|last|edit" >&2; exit 1 ;;
esac
