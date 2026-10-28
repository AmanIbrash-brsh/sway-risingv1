#!/usr/bin/env bash
# Wi-Fi menu (rofi): toggle radio, connect/disconnect, prompt for password on new networks.
THEME=~/.config/rofi/catppuccin.rasi
menu() { rofi -dmenu -i -p "$1" -theme "$THEME" "${@:2}"; }

radio=$(nmcli radio wifi)
if [[ $radio != enabled ]]; then
    choice=$(printf '%s\n' "Включить Wi-Fi" | menu "Wi-Fi")
    [[ $choice == "Включить Wi-Fi" ]] && nmcli radio wifi on && notify-send "Wi-Fi" "Включён"
    exit 0
fi

declare -A seen
list=""
while IFS=: read -r use sig sec ssid; do
    [[ -z $ssid || -n ${seen[$ssid]} ]] && continue
    seen[$ssid]=1
    mark="○"; [[ $use == '*' ]] && mark="●"
    lock=""; [[ -n $sec && $sec != "--" ]] && lock=" (защищена)"
    list+="$mark $ssid  ${sig}%$lock"$'\n'
done < <(nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan auto | sort -t: -k2 -nr)

choice=$(printf '%s%s\n%s\n' "$list" "Выключить Wi-Fi" "Расширенные настройки…" | sed '/^$/d' | menu "Wi-Fi") || exit 0
[[ -z $choice ]] && exit 0

case $choice in
    "Выключить Wi-Fi") nmcli radio wifi off; notify-send "Wi-Fi" "Выключен"; exit 0 ;;
    "Расширенные настройки…") exec nm-connection-editor ;;
esac

ssid=${choice:2}; ssid=${ssid%%  *}
if [[ ${choice:0:1} == "●" ]]; then
    nmcli connection down id "$ssid" >/dev/null && notify-send "Wi-Fi" "Отключено от $ssid"
elif nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    nmcli connection up id "$ssid" >/dev/null 2>&1 && notify-send "Wi-Fi" "Подключено к $ssid" || notify-send -u critical "Wi-Fi" "Не удалось подключиться к $ssid"
else
    if [[ $choice == *"(защищена)"* ]]; then
        pw=$(menu "Пароль для $ssid" -password -lines 0) || exit 0
        out=$(nmcli dev wifi connect "$ssid" password "$pw" 2>&1)
    else
        out=$(nmcli dev wifi connect "$ssid" 2>&1)
    fi
    [[ $? -eq 0 ]] && notify-send "Wi-Fi" "Подключено к $ssid" || notify-send -u critical "Wi-Fi" "Ошибка: $out"
fi
