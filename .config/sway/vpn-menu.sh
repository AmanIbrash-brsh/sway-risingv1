#!/usr/bin/env bash
# VPN menu (rofi): lists NetworkManager vpn/wireguard connections, click to connect/disconnect.
# Secrets are asked by nm-applet (secret agent).
THEME=~/.config/rofi/catppuccin.rasi
menu() { rofi -dmenu -i -p "$1" -theme "$THEME" "${@:2}"; }

active=$(nmcli -t -e no -f NAME,TYPE connection show --active)
list=""
while IFS= read -r line; do
    type=${line##*:}; name=${line%:*}
    [[ $type == vpn || $type == wireguard ]] || continue
    mark="○"; grep -Fxq "$line" <<<"$active" && mark="●"
    list+="$mark $name  ($type)"$'\n'
done < <(nmcli -t -e no -f NAME,TYPE connection show)

[[ -z $list ]] && { notify-send "VPN" "Нет настроенных VPN"; exit 0; }
choice=$(printf '%s%s\n' "$list" "Расширенные настройки…" | menu "VPN") || exit 0
[[ -z $choice ]] && exit 0
[[ $choice == "Расширенные настройки…" ]] && exec nm-connection-editor

name=${choice:2}; name=${name%  (*}
if [[ ${choice:0:1} == "●" ]]; then
    nmcli connection down id "$name" >/dev/null && notify-send "VPN" "Отключено: $name"
else
    nmcli connection up id "$name" >/dev/null 2>&1 && notify-send "VPN" "Подключено: $name" || notify-send -u critical "VPN" "Не удалось подключиться: $name"
fi
