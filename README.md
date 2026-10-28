# sway-rising

«Стеклянный» райс для **Fedora**: матовый blur, скруглённые углы, мягкое свечение у активного окна, **SwayFX** (тайлинг-композитор) и **DankMaterialShell** (бар, лаунчер, панель управления с Wi-Fi / Bluetooth / VPN, уведомления, экран блокировки, обои), терминал **kitty** с красивой палитрой, удобные скриншоты и хоткеи. Ставится одной командой, откатывается одной командой.

## Установка

Нужны: Fedora (лучше Workstation), `git`, интернет, `sudo`.

```sh
git clone https://git.ibrash.duckdns.org/aibrash/sway-rising.git sway-rising && cd sway-rising
./install.sh --dry-run     # необязательно: показать, что будет сделано, ничего не меняя
./install.sh
```

Скрипт спросит про два сторонних репозитория (COPR) для SwayFX и DMS и про раскладки клавиатуры, остальное делает сам. Без вопросов: `./install.sh --yes`.

Перед началом ваши настройки **сохраняются в `~/rice-backup-<дата>`**. Ваши программы, `~/.zshrc`, tmux, ssh и браузер не трогаются.

Что ставится: сессия sway (`SwayFX`, `sway-systemd`, порталы), `DankMaterialShell`, kitty, Nautilus, swaylock/swayidle, grim + swappy (скриншоты), шрифты JetBrains Mono и Font Awesome, тема `adw-gtk3`.

Хочется ещё и zsh с oh-my-zsh, tmux и удобными утилитами (fzf, zoxide, eza, bat, fd, ripgrep, lazygit)? Добавьте `--with-shell`.

После установки **выйдите и выберите на экране входа сессию «Sway»**. При первом запуске райс сам выберет обои и расставит ваши мониторы (ноутбук слева, внешние справа, масштаб подбирается по разрешению).

Если на машине стоит Fedora Sway Spin, в ней есть обычный `sway`, который конфликтует с SwayFX: скрипт предупредит и подскажет команду `sudo dnf remove sway sway-config-fedora`.

## Настройка под себя

| Что | Как |
|---|---|
| Цвета, шрифты, виджеты бара, прозрачность | интерфейс DMS (значок настроек в панели `Super+N`) |
| Обои | интерфейс DMS: Settings → Wallpaper |
| Раскладки клавиатуры, тачпад | `~/.config/sway/config.d/07-input.conf` или `./install.sh --layouts "us,de"` |
| Мониторы и масштаб | `~/.config/sway/outputs-setup.sh` (с вопросами) или файл `config.d/05-outputs.conf` |
| Свои твики (скорость мыши, автозапуск программ) | `~/.config/sway/config.d/99-personal.conf`, пример: `examples/99-personal.conf.example`. Установщик такие файлы **никогда не трогает** |
| Хоткеи | `config` и `config.d/30-workflow.conf`; список всех: `Super+F1` |

Повторный запуск `./install.sh` безопасен: он обновит райс и заново сделает бэкап, а ваши `07-input.conf`, настройки DMS (`~/.config/dms/settings.json`) и все `99-*.conf` оставит как есть.

## Откат и диагностика

- **Вернуть всё как было:** `./install.sh --restore` (берёт самый старый бэкап, то есть состояние до райса; можно указать папку: `--restore ~/rice-backup-...`). Пакеты при этом остаются, убрать их: `sudo dnf remove swayfx dms`.
- **Проверка здоровья:** `./install.sh --check` (то же: `~/.config/sway/doctor.sh`) покажет, что установлено и что работает. Диагностика самого DMS: `dms doctor`.

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
| `Super+O` | файловый менеджер (Nautilus) |
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
| `Alt+Shift` | переключение раскладки; все хоткеи работают на любой раскладке |

## Что внутри

| Путь | Что это |
|---|---|
| `install.sh` | установщик (Fedora): пакеты, бэкап, конфиги, `--restore`, `--check`, `--dry-run` |
| `.config/sway/config` | базовый конфиг sway; все хоткеи работают и на других раскладках (`bindsym --to-code`) |
| `.config/sway/config.d/00-session.conf` | окружение и `sway-session.target`, чтобы работали порталы (демонстрация экрана, диалоги) |
| `.config/sway/config.d/05-outputs.conf.example` | пример раскладки мониторов (свой файл создаёт `outputs-setup.sh`) |
| `.config/sway/config.d/07-input.conf` | клавиатура и тачпад |
| `.config/sway/config.d/10-appearance.conf` | цвета рамок и вкладок, отступы, правила окон, idle |
| `.config/sway/config.d/20-swayfx.conf`, `21-dms-effects.conf` | эффекты SwayFX: blur, тени, скругления, прозрачность; blur для слоёв DMS |
| `.config/sway/config.d/30-workflow.conf` | scratchpad-терминал, скриншоты, шпаргалка, режим производительности |
| `.config/sway/config.d/50-dms.conf` | запуск DMS, буфер обмена, медиаклавиши (громкость, яркость, плеер) |
| `.config/sway/screenshot.sh` | все режимы скриншотов (см. ниже) |
| `.config/sway/{lock,idle,cheatsheet,firstrun}.sh` | блокировка (DMS, запасной swaylock), swayidle, шпаргалка, первый запуск (обои и мониторы) |
| `.config/sway/outputs-setup.sh`, `doctor.sh` | раскладка мониторов под железо; проверка здоровья системы |
| `.config/dms/settings.json` | настройки DMS: тема, шрифты, виджеты бара (раскладка, VPN, температура, приватность), панель управления |
| `.config/kitty/kitty.conf` | JetBrains Mono, палитра Tokyo Night, прозрачность, вкладки (`Ctrl+Shift+←/→`) и сплиты (`Ctrl+Alt+стрелки`); `Ctrl+C` копирует выделенное (без выделения прерывает), `Ctrl+V` вставляет |
| `.config/swappy/config` | редактор скриншотов (стрелки, текст, размытие) |
| `.config/swaylock/` | запасная блокировка, если DMS не запущен |
| `home/` | только для `--with-shell`: `.zshrc`, `.tmux.conf`, алиасы (`ports`, `jce`, `dnfu`, `tm`) и автоподключение fzf / zoxide / eza |
| `wallpapers/` | обои (кладутся в `~/.local/share/backgrounds`, дальше обоями управляет DMS) |
| `examples/` | пример личных настроек |

