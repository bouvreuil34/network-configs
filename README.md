# Конфиги домашней сети

Репозиторий содержит актуальные конфиги домашней сети, Shadowrocket, Netcraze и VPN.

## Каталоги

- `shadowrocket/` — конфиги и правила Shadowrocket.
- `netcraze/` — конфиги домашней сети и оборудования Netcraze.
- `vpn/` — конфиги VPN без секретов и приватных ключей.
- `scripts/` — проверка ICMP/TCP и SSH-туннели; команды в [docs/tools.md](docs/tools.md).

## Восстановление и использование

```bash
git clone https://github.com/bouvreuil34/network-configs.git
cd network-configs
./scripts/net-check.sh example.com 443
./scripts/ssh-tunnel.sh socks my-vps 1080
```

В Shadowrocket импортируйте нужный профиль: `shadowrocket/mobile.conf`,
`shadowrocket/wifi.conf` или `shadowrocket/wifi-remote.conf`.
Намеренное поведение и зависимости профилей описаны в [mobile](docs/mobile.md),
[wifi](docs/wifi.md) и [wifi-remote](docs/wifi-remote.md). Подписки и сами VPN-серверы восстановите отдельно в приложении:
Git хранит правила маршрутизации, а не доступ к VPN. Для Netcraze используйте списки
`netcraze/vpn-*.txt` в прежних настройках маршрутизации; это не полный backup роутера.

SSH Host `my-vps`, адреса и пути к ключам задайте в локальном `~/.ssh/config`.
Приватные ключи, VPN-профили с ключами и подписки храните в отдельном зашифрованном
backup. Серверную ОС и сервисы этот репозиторий не разворачивает.
Для восстановления CLI на Mac существует отдельный приватный `mac-setup`.

## Профили Shadowrocket

- `shadowrocket/mobile.conf` — мобильная сеть.
- `shadowrocket/wifi.conf` — обычный Wi-Fi, без удалённого доступа к домашней LAN; локальная LAN напрямую.
- `shadowrocket/wifi-remote.conf` — Wi-Fi с удалённым доступом к домашней LAN.

## Правила

- `main` всегда считается текущей рабочей версией; изменения коммитим напрямую в неё.
- История изменений хранится в Git, поэтому версии файлов в именах не используются.
- Имена файлов стабильны: например, `mobile.conf`, а не `mobile-v4-final.conf`.
- Секреты, приватные ключи (включая VPN), пароли и токены коммитить нельзя. Локальные секреты храним вне Git; `.gitignore` не заменяет проверку содержимого.
- Перед каждым commit проверяем staged-файлы на секреты, включая чувствительные `.env`. При подозрении останавливаем commit и проверяем файл.
- Сначала простота и читаемость, потом автоматизация.
