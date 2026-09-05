# Wi-Fi-профиль Shadowrocket

`docs/wifi.md` определяет желаемое поведение профиля, а `shadowrocket/wifi.conf` является его реализацией. В будущем при расхождении сначала проверяется спецификация, а не старое поведение конфига. Приоритеты hobby-проекта — простота, прозрачность, надёжность, предсказуемость и минимум обслуживания.

Wi-Fi работает по модели **DIRECT по умолчанию**. Через PROXY идут только явно перечисленные сервисы и проблемные ресурсы. Российские домены и IP без совпадения с явными VPN-правилами идут DIRECT; правила `GEOIP,RU`, `geosite-category-ru` и отдельные российские proxy-группы не используются. Последнее правило — `FINAL,DIRECT`.

## Маршрутизация

Правила применяются сверху вниз до первого совпадения. Таблица задаёт их смысловой порядок.

| Трафик | Маршрут |
| --- | --- |
| Домашняя подсеть `192.168.168.0/24` | `Домашний роутер` |
| `localhost`, домены `.arpa`, `.lan`, `.local` | DIRECT |
| Остальная LAN и служебные IPv4: private, link-local, multicast, loopback, CGNAT и широковещательный адрес | DIRECT |
| Локальные и служебные IPv6: private, link-local, multicast и loopback | DIRECT |
| Весь Apple, включая `captive.apple.com`, `push.apple.com` и поддомены push; Blackmatrix `Apple_Domain.list` и `Apple.list` | DIRECT |
| Google по доменам: Master-Yoba `geosite-google.list` | PROXY |
| Meta / Facebook / Instagram / WhatsApp по доменам: Master-Yoba `geosite-meta.list` | PROXY |
| OpenAI: `cdn.openaimerge.com`, затем `geosite-openai.list` от Master-Yoba | PROXY |
| Telegram по доменам: Master-Yoba `geosite-telegram.list` | PROXY |
| YouTube: Blackmatrix `YouTube.list` | PROXY |
| Meta по IP: Master-Yoba `geoip-facebook.list`, `no-resolve` | PROXY |
| Telegram по IP: Master-Yoba `geoip-telegram.list`, `no-resolve` | PROXY |
| `inside-clashx`: ресурсы, проблемные или ограниченные из России | PROXY |
| `no-russia-hosts`: ресурсы, ограничивающие доступ с российских IP | PROXY |
| `geosite-ru-blocked` | PROXY |
| Всё остальное, включая российские домены/IP без совпадения выше (`FINAL`) | DIRECT |

Правило `192.168.168.0/24` с точной политикой `Домашний роутер` и `no-resolve` должно стоять раньше общего `192.168.0.0/16 → DIRECT`. Обе подсети остаются внутри TUN: их нельзя добавлять в `skip-proxy` или `tun-excluded-routes`. Существующая логика остальных исключений сохраняется. LAN не блокируется через REJECT.

Доменные и IP-правила Meta/Telegram намеренно разделены для прозрачности; комбинированные Blackmatrix Google, Facebook и Telegram заменены указанными списками Master-Yoba. Отдельные IP-списки Google, YouTube и OpenAI и ASN-правила не используются. Источники YouTube и Apple сохранены без изменений. Для OpenAI обязательны отдельное доменное правило `cdn.openaimerge.com` и список `https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-openai.list`; старый Blackmatrix OpenAI.list не используется.

Все три источника проблемных ресурсов сохраняются:

- inside-clashx: `https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-clashx.lst`.
- no-russia-hosts: `https://raw.githubusercontent.com/dartraiden/no-russia-hosts/master/hosts.txt`.
- geosite-ru-blocked: `https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-ru-blocked.list`.

## DNS и IPv6

Cloudflare DoH (`https://cloudflare-dns.com/dns-query#no-h3`) и Google DoH (`https://dns.google/dns-query#no-h3`) настроены как DNS-серверы Shadowrocket. Для DIRECT разрешён системный DNS текущей Wi-Fi-сети (`dns-direct-system = true`). Доменные proxy-правила, в том числе `no-russia-hosts`, используют `force-remote-dns`, требующий удалённого разрешения назначения. Конкретный resolver, использованный прокси-сервером для такого имени, этим конфигом не определяется; это не обязательно Cloudflare или Google DoH.

Если основные DNS недоступны, резерв — системный DNS (`fallback-dns-server = system`). Дополнительный механизм `dns-fallback-system` выключен: system уже явно указан как резерв. `dns-direct-fallback-proxy = false`; ControlD и AdGuard в DNS-конфигурации не используются.

IPv6 включён (`ipv6 = true`), предпочтение IPv6 выключено (`prefer-ipv6 = false`), ответы с частными IP разрешены (`private-ip-answer = true`).

Сохраняются `bypass-system = true`, `block-quic = all-proxy` и `udp-policy-not-supported-behaviour = REJECT`. Адрес обновления профиля: `https://raw.githubusercontent.com/bouvreuil34/network-configs/main/shadowrocket/wifi.conf`.
