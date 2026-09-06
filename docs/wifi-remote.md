# Wi-Fi-профиль Shadowrocket с удалённым доступом к домашней сети

Эта спецификация задаёт намеренное поведение `shadowrocket/wifi-remote.conf`. В будущем при расхождении сначала проверяется спецификация, а не старое поведение конфига. Приоритеты hobby-проекта — простота, прозрачность, надёжность, предсказуемость и минимум обслуживания.

`wifi-remote.conf` используется на Wi-Fi вне домашней сети и обеспечивает удалённый доступ к `192.168.168.0/24` через `Домашний роутер`.

Wi-Fi работает по модели **DIRECT по умолчанию**. Через PROXY идут только явно перечисленные сервисы и проблемные ресурсы. Российские домены и IP без совпадения с явными VPN-правилами идут DIRECT; правила `GEOIP,RU`, `geosite-category-ru` и отдельные российские proxy-группы не используются. Последнее правило — `FINAL,DIRECT`.

## Маршрутизация

Правила применяются сверху вниз до первого совпадения. Таблица задаёт их порядок.

| Трафик | Маршрут |
| --- | --- |
| Домашняя подсеть `192.168.168.0/24` | `Домашний роутер` |
| `localhost`, домены `.arpa`, `.lan`, `.local` | `DIRECT` |
| Остальная LAN и служебные IPv4: private, link-local, multicast, loopback, CGNAT и широковещательный адрес | `DIRECT` |
| Локальные и служебные IPv6: private, link-local, multicast и loopback | `DIRECT` |
| Весь Apple, включая `captive.apple.com`, `push.apple.com` и поддомены push; Blackmatrix `Apple_Domain.list` и `Apple.list` | `DIRECT` |
| Google по доменам: Master-Yoba `geosite-google.list` | `PROXY` |
| Meta / Facebook / Instagram / WhatsApp по доменам: Master-Yoba `geosite-meta.list` | `PROXY` |
| OpenAI: `cdn.openaimerge.com`, затем `geosite-openai.list` от Master-Yoba | `PROXY` |
| Telegram по доменам: Master-Yoba `geosite-telegram.list` | `PROXY` |
| YouTube: Blackmatrix `YouTube.list` | `PROXY` |
| Meta по IP: Master-Yoba `geoip-facebook.list`, `no-resolve` | `PROXY` |
| Telegram по IP: Master-Yoba `geoip-telegram.list`, `no-resolve` | `PROXY` |
| `inside-clashx`: ресурсы, проблемные или ограниченные из России | `PROXY` |
| `no-russia-hosts`: ресурсы, ограничивающие доступ с российских IP | `PROXY` |
| `geosite-ru-blocked` | `PROXY` |
| Всё остальное, включая российские домены/IP без совпадения выше (`FINAL`) | `DIRECT` |

Правило `192.168.168.0/24` с точной политикой `Домашний роутер` и `no-resolve` должно стоять раньше общего `192.168.0.0/16 → DIRECT`. Обе подсети остаются внутри TUN: их нельзя добавлять в `skip-proxy` или `tun-excluded-routes`. Существующая логика остальных исключений сохраняется. LAN не блокируется через REJECT.

Доменные и IP-правила Meta/Telegram намеренно разделены для прозрачности; комбинированные Blackmatrix Google, Facebook и Telegram заменены указанными списками Master-Yoba. Отдельные IP-списки Google, YouTube и OpenAI и ASN-правила не используются. Источники YouTube и Apple сохранены без изменений. Для OpenAI обязательны отдельное доменное правило `cdn.openaimerge.com` и список `https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-openai.list`; старый Blackmatrix OpenAI.list не используется.

Все три источника проблемных ресурсов сохраняются:

- inside-clashx: `https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-clashx.lst`.
- no-russia-hosts: `https://raw.githubusercontent.com/dartraiden/no-russia-hosts/master/hosts.txt`.
- geosite-ru-blocked: `https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-ru-blocked.list`.

## DNS и IPv6

DIRECT использует системный DNS текущей сети (`dns-server = system`): на внешнем Wi-Fi — DNS этой сети, дома — через Netcraze к DNS, полученным от провайдера МТС, в мобильной сети — DNS оператора. `dns-direct-system` включён, `dns-fallback-system` и `dns-direct-fallback-proxy` выключены. Отдельный fallback DNS в Shadowrocket не используется. Публичный DoH намеренно не используется для обычного DIRECT-трафика из-за возможных проблем с географическим выбором российских CDN.

Доменные VPN-правила с политикой `PROXY`, в том числе `no-russia-hosts`, сохраняют `force-remote-dns` для удалённого разрешения имени. Конкретный DNS resolver на стороне прокси этим конфигом не задаётся.

IPv6 включён (`ipv6 = true`), предпочтение IPv6 выключено (`prefer-ipv6 = false`), ответы с частными IP разрешены (`private-ip-answer = true`).

Сохраняются `bypass-system = true`, `block-quic = all-proxy` и `udp-policy-not-supported-behaviour = REJECT`. Адрес обновления профиля: `https://raw.githubusercontent.com/bouvreuil34/network-configs/main/shadowrocket/wifi-remote.conf`.
