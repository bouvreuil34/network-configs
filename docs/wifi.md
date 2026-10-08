# Обычный Wi-Fi-профиль Shadowrocket

Эта спецификация задаёт намеренное поведение `shadowrocket/wifi.conf`. Профиль предназначен для обычного Wi-Fi без удалённого доступа к домашней сети. Интернет-маршрутизация, порядок интернет-правил, DNS и IPv6 должны совпадать с `shadowrocket/wifi-remote.conf`.

## Локальная сеть

Вся `192.168.0.0/16`, включая домашнюю подсеть `192.168.168.0/24`, считается локальной и направляется `DIRECT`. Политика `Домашний роутер` не используется.

LAN должна обходить прокси и быть исключена из TUN: `192.168.0.0/16` присутствует в `skip-proxy` и `tun-excluded-routes`. Домены `.lan` и `.local` обрабатываются напрямую; `*.lan` и `*.local` присутствуют в `skip-proxy`, соответствующие DIRECT-правила сохраняются. Link-local и multicast IPv4/IPv6 остаются `DIRECT` и вне TUN. Остальные локальные DIRECT-правила и исключения профиля `wifi-remote.conf` сохраняются.

## Интернет-маршрутизация

Приоритет исключений и положение IP-правил с `no-resolve` сохраняются. Независимые сервисные блоки и домены внутри них отсортированы по алфавиту; `FINAL` остаётся последним.

- AWS: `amazonaws.com` и поддомены → `PROXY`.
- Исключения iCloud и связанных сервисов Apple: `apple-cloudkit.com`, `apple-dns.net`, `apple-livephotoskit.com`, `cdn-apple.com`, `gc.apple.com`, `icloud-content.com`, `icloud.com`, `iwork.apple.com` и их поддомены → `PROXY`; эти правила стоят перед общими списками Apple.
- Остальной Apple по `Apple_Domain.list` и `Apple.list`, а также `captive.apple.com` и `push.apple.com` с поддоменами push → `DIRECT`.
- Google / Meta / OpenAI → `PROXY`.
- Prefect / FastMCP / Horizon (`fastmcp.app`, `gofastmcp.com`, `prefect.cloud`, `prefect.io`, `workos.com` и их поддомены) → `PROXY`.
- Telegram / YouTube → `PROXY`.
- IP-списки Meta и Telegram → `PROXY`.
- Ограниченные ресурсы (`geosite-ru-blocked`, `inside-clashx`, `no-russia-hosts`) → `PROXY`.
- Всё остальное → `FINAL,DIRECT`.

DNS совпадает с `wifi-remote.conf`: DIRECT использует системный DNS текущей сети (`dns-server = system`). Дома запросы идут через Netcraze к DNS, полученным от провайдера МТС; в другой Wi-Fi-сети — к её DNS, в мобильной сети — к DNS оператора. `dns-direct-system` включён, `dns-fallback-system` и `dns-direct-fallback-proxy` выключены. Отдельный fallback DNS в Shadowrocket не используется. Публичный DoH намеренно не используется для обычного DIRECT-трафика из-за возможных проблем с географическим выбором российских CDN.

Для доменных VPN-правил с политикой `PROXY` используется стандартное поведение DNS в Shadowrocket. Конкретный DNS resolver на стороне прокси конфигом не задаётся. IPv6 совпадает с `wifi-remote.conf`.

Для домашнего Wi-Fi профиль можно выбирать автоматически через Shadowrocket Scene по SSID домашней сети.

`no-russia-hosts` использует `RULE-SET` с `DOMAIN-SUFFIX` для доменов и поддоменов. [Обновление профиля и списка](../README.md#обновление-shadowrocket-и-списков).
