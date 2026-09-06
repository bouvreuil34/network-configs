# Обычный Wi-Fi-профиль Shadowrocket

Эта спецификация задаёт намеренное поведение `shadowrocket/wifi.conf`. Профиль предназначен для обычного Wi-Fi без удалённого доступа к домашней сети. Интернет-маршрутизация, порядок интернет-правил, DNS и IPv6 должны совпадать с `shadowrocket/wifi-remote.conf`.

## Локальная сеть

Вся `192.168.0.0/16`, включая домашнюю подсеть `192.168.168.0/24`, считается локальной и направляется `DIRECT`. Политика `Домашний роутер` не используется.

LAN должна обходить прокси и быть исключена из TUN: `192.168.0.0/16` присутствует в `skip-proxy` и `tun-excluded-routes`. Домены `.lan` и `.local` обрабатываются напрямую; `*.lan` и `*.local` присутствуют в `skip-proxy`, соответствующие DIRECT-правила сохраняются. Link-local и multicast IPv4/IPv6 остаются `DIRECT` и вне TUN. Остальные локальные DIRECT-правила и исключения профиля `wifi-remote.conf` сохраняются.

## Интернет-маршрутизация

- Apple → `DIRECT`.
- Google / Meta / OpenAI / Telegram / YouTube → `PROXY`.
- IP-списки Meta и Telegram → `PROXY`.
- Ограниченные ресурсы (`inside-clashx`, `no-russia-hosts`, `geosite-ru-blocked`) → `PROXY`.
- Всё остальное → `FINAL,DIRECT`.

DNS совпадает с `wifi-remote.conf`: DIRECT использует системный DNS текущей сети (`dns-server = system`, `fallback-dns-server = system`). Дома запросы идут через Netcraze к DNS, полученным от провайдера МТС; в другой Wi-Fi-сети — к её DNS, в мобильной сети — к DNS оператора. `dns-direct-system` включён, `dns-fallback-system` и `dns-direct-fallback-proxy` выключены. Публичный DoH намеренно не используется для обычного DIRECT-трафика, в том числе как fallback, из-за возможных проблем с географическим выбором российских CDN.

Доменные VPN-правила с политикой `PROXY` сохраняют `force-remote-dns`; конкретный DNS resolver на стороне прокси конфигом не задаётся. IPv6 совпадает с `wifi-remote.conf`.

Для домашнего Wi-Fi профиль можно выбирать автоматически через Shadowrocket Scene по SSID домашней сети.
