# sway-rising

Монохромный «стеклянный» райс для **SwayFX** на Fedora: blur, скруглённые углы, мягкое свечение у активного окна и **DankMaterialShell** (бар, лаунчер, панель управления с Wi-Fi / Bluetooth / VPN, уведомления, блокировка, обои) поверх sway.

## Что внутри

| Путь | Что это |
|---|---|
| `.config/sway/config` | базовый конфиг sway (раскладки us/ru, хоткеи, `--to-code`: хоткеи работают и на русской раскладке) |
| `.config/sway/config.d/00-session.conf` | окружение и `sway-session.target`, чтобы работали порталы (демонстрация экрана, диалоги) |
| `.config/sway/config.d/05-outputs.conf.example` | пример раскладки мониторов; свой файл создаёт `outputs-setup.sh` |
| `.config/sway/config.d/06-mouse.conf` | чувствительность мыши |
| `.config/sway/config.d/10-appearance.conf` | цвета рамок и вкладок, отступы, тачпад, правила окон, idle |
| `.config/sway/config.d/20-swayfx.conf`, `21-dms-effects.conf` | эффекты SwayFX: blur, тени, скругления, прозрачность; blur для слоёв DMS |
| `.config/sway/config.d/30-workflow.conf` | scratchpad-терминал, скриншоты, шпаргалка, режим производительности |
| `.config/sway/config.d/50-dms.conf` | запуск DMS, буфер обмена, медиаклавиши (громкость, яркость, плеер) |
| `.config/sway/config.d/60-autostart.conf` | автозапуск Nextcloud, Remmina и Geary (xdg-autostart в sway не работает) |
| `.config/sway/screenshot.sh` | все режимы скриншотов (см. ниже) |
| `.config/sway/{lock,idle,cheatsheet}.sh` | блокировка (DMS, запасной swaylock), swayidle, шпаргалка по хоткеям |
| `.config/sway/outputs-setup.sh`, `doctor.sh` | настройка мониторов под новое железо; проверка здоровья системы |
| `.config/dms/settings.json` | настройки DMS: виджеты бара (раскладка, VPN, температура, приватность), шрифты, панель управления |
| `.config/kitty/kitty.conf` | JetBrains Mono, палитра Tokyo Night, прозрачность, вкладки и сплиты; `Ctrl+C` копирует выделенное (без выделения прерывает), `Ctrl+V` вставляет |
| `.config/Thunar/uca.xml`, `.config/xfce4/helpers.rc` | файловый менеджер: «Open kitty here», «Copy path» в контекстном меню, терминал kitty |
| `.config/swappy/config` | редактор скриншотов (стрелки, текст, размытие) |
| `.config/swaylock/` | запасная блокировка, если DMS не запущен |
| `home/.tmux.conf`, `home/.zshrc`, `home/.oh-my-zsh/custom/sysadmin.zsh` | tmux, zsh, алиасы сисадмина; fzf / zoxide / eza подключаются сами |
| `wallpapers/` | любимые обои (кладутся в `~/.local/share/backgrounds`, дальше обоями управляет DMS) |

Обои, уведомления, панель управления, лаунчер и бар обслуживает DMS. Waybar, swaync, dunst, rofi и сопутствующие скрипты убраны из репозитория.

## Скриншоты

Все снимки сохраняются в `~/Pictures/Screenshots` **и** копируются в буфер обмена, DMS показывает уведомление.

| Клавиши | Что снимает |
|---|---|
| `Print` или `Super+Shift+S` | область: выделить мышью, `Enter` или пробел подтверждает, `Esc` отменяет |
| `Shift+Print` | весь текущий монитор |
| `Ctrl+Print` | активное окно |
| `Alt+Print` | прокручиваемая область одним длинным снимком (`Enter` завершает) |
| `Super+Print` | повторить прошлую область |
| `Ctrl+Shift+Print` | область с редактором swappy (стрелки, текст, размытие) |

## Хоткеи (`Super` = Mod4)

| Клавиши | Действие |
|---|---|
| `Super+Return` | терминал (kitty) |
| `Super+D` | лаунчер DMS |
| `Super+N` | панель управления DMS (Wi-Fi, Bluetooth, VPN, звук, яркость) |
| `Super+Shift+N` | центр уведомлений |
| `Super+Shift+V` | история буфера обмена |
| `Super+O` | файловый менеджер (Thunar) |
| `Super+Shift+Q` | закрыть окно |
| `Super+Shift+C` | перезагрузить конфиг |
| `Super+Shift+E` / `Super+Shift+P` | меню выключения DMS |
| `Super+Shift+X` | заблокировать экран |
| `Super+F1` | **шпаргалка по всем хоткеям** |
| `Super+Shift+B` | режим производительности (blur + тени) |
| ``Super+` `` | выпадающий терминал (scratchpad) |
| `Super+H/J/K/L` | фокус влево / вниз / вверх / вправо |
| `Super+Shift+H/J/K/L` | переместить окно |
| `Super+1…0` / `Super+Shift+1…0` | воркспейс / переместить окно на воркспейс |
| `Super+Tab` / `Super+Shift+Tab` | следующий / предыдущий воркспейс |
| `Super+F` | полный экран |
| `Super+Shift+Space` | плавающее окно вкл/выкл |
| `Super+Shift+F` | плавающее 1000×600 по центру |
| `Super+C` | центрировать плавающее окно |
| `Super+R` | режим изменения размера (`H/J/K/L`, `Esc`) |
| `Super+S` / `Super+W` / `Super+E` | layout: stacking / tabbed / split |
| `Alt+Shift` | переключение раскладки (us / ru); первой в `xkb_layout` должна стоять `us` |

## Новый ноутбук за одну команду (Fedora)

На свежей Fedora (Workstation или любой вариант с `git`):

```sh
git clone git@git.ibrash.duckdns.org:aibrash/sway-rising.git && cd sway-rising && ./install.sh
```

Репозиторий клонируется по ssh, поэтому на новой машине сначала нужен ваш ключ (`~/.ssh/id_ed25519`) или ключ, добавленный на git-сервер.

Скрипт спрашивает подтверждение перед каждым COPR и больше ни о чём не спрашивает. Для полностью автоматического режима: `./install.sh --yes`.

Что он делает:
1. Ставит пакеты через `dnf`: сессия sway (`sway-systemd`, порталы), kitty, swaylock/swayidle, grim, swappy (аннотации скриншотов), шрифты JetBrains Mono и Font Awesome, тема `adw-gtk3`.
2. Подключает COPR `swayfx/swayfx` и `avengemedia/dms` и ставит SwayFX и DankMaterialShell.
3. Ставит CLI: zsh, tmux, fzf, zoxide, eza, bat, fd, ripgrep, ncdu, fastfetch, lazygit (бинарник с проверкой суммы), клонирует oh-my-zsh с плагинами. Опция `--with-tools` добавляет nmap, tcpdump, mtr, jq, btop, ansible.
4. **Делает бэкап** ваших конфигов в `~/rice-backup-<дата>` и копирует конфиги, обои (в `~/.local/share/backgrounds`), tmux и алиасы. Ваш `~/.zshrc` не трогает (его заменит только `--force-shell`).
5. Включает тему `adw-gtk3-dark` и проверяет конфиг (`sway -C`).

После установки: выйти и выбрать на экране входа сессию **Sway**. Внутри сессии один раз выполнить

```sh
~/.config/sway/outputs-setup.sh   # раскладка и масштаб мониторов (ноутбук слева, внешний справа)
```

Файл раскладки мониторов намеренно не копируется: на другом железе другие имена выходов. В репозитории лежит только пример `05-outputs.conf.example`.

Проверка здоровья в любой момент: `./install.sh --check` (то же самое: `~/.config/sway/doctor.sh`). Показывает, что установлено, что работает, а что нет (DMS, порталы, шрифты, инструменты, раскладка мониторов).

Флаги: `--yes`, `--dry-run` (показать действия, ничего не менять), `--check`, `--no-packages`, `--no-dms`, `--no-shell`, `--with-tools`, `--force-shell`. Можно запускать повторно.

DMS запускается из `config.d/50-dms.conf`, руками его запускать не нужно. Диагностика самого DMS: `dms doctor`.
