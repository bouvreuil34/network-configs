# Мобильный профиль Shadowrocket

Эта спецификация задаёт намеренное поведение `shadowrocket/mobile.conf`. Будущие изменения конфига следует проверять относительно неё. Приоритеты hobby-проекта — простота, прозрачность, предсказуемость и минимум обслуживания.

Профиль Mobile использует **DIRECT по умолчанию**. VPN включается только для явно перечисленных ниже сервисов и списков. Российские домены и IP идут напрямую, если не совпали с явным VPN-правилом. Отдельной маршрутизации по России и автоматического выбора российского VPN нет. Последнее правило — `FINAL,DIRECT`.

## DNS, IP и локальная сеть

Системный DNS мобильной сети является основным локальным resolver для DIRECT (`dns-server = system`). Google DoH (`https://dns.google/dns-query#no-h3`) задан как fallback DNS Shadowrocket. `dns-direct-system` включён, `dns-fallback-system` и `dns-direct-fallback-proxy` выключены. Проксируемые доменные правила используют `force-remote-dns`: это требует удалённого разрешения имени для прокси-маршрута, но не означает использование именно Google DoH. Конкретный DNS resolver на стороне прокси этим конфигом не задаётся.

IPv6 намеренно отключён: `ipv6 = false`, `prefer-ipv6 = false`. Ответы DNS с частными IP разрешены (`private-ip-answer = true`). Локальная сеть не блокируется: localhost, домены `.arpa`, `.lan`, `.local`, частные, link-local и multicast адреса IPv4/IPv6 обрабатываются напрямую. DIRECT-правила IPv6 сохраняют это намерение при отключённом IPv6.

Сохраняются `bypass-system = true`, `block-quic = all-proxy` и `udp-policy-not-supported-behaviour = REJECT`. Адрес обновления профиля: `https://raw.githubusercontent.com/bouvreuil34/network-configs/main/shadowrocket/mobile.conf`.

## Выбор VPN

Все VPN-правила обращаются к группе `Mobile`: ручной выбор между `Mobile-Foreign` (по умолчанию, `select=0`) и `Mobile-Manual`. Обе вложенные группы используют подписку с точным именем **Платный VPN**.

- **Mobile-Foreign** — автоматический зарубежный LTE через `fallback`. Название сервера должно содержать `LTE` и не содержать ни одного из вариантов: `Авто`, `Москва`, `МСК`, `Санкт-Петербург`, `СПБ`, `Екатеринбург`, `Хабаровск`, `Россия`, `РФ`. Наличие ⭐ не ограничивается. Проверка доступности: `https://cp.cloudflare.com/generate_204`, интервал 120 секунд, тайм-аут 4 секунды. Важна доступность, а не минимальная задержка.
- **Mobile-Manual** — ручной запасной выбор через `select`. Доступны все серверы с `LTE` в названии, включая российские, зарубежные, `Авто` и ⭐. Других фильтров и периодических проверок доступности нет. Российский сервер может использоваться только при таком ручном выборе для явных VPN-правил.

## Маршрутизация

Правила применяются сверху вниз до первого совпадения. Таблица задаёт их порядок.

Google, Meta, OpenAI, Telegram и весь YouTube всегда идут через VPN с политикой `Mobile`.

| Трафик | Маршрут |
| --- | --- |
| Локальные и служебные домены и адреса | `DIRECT` |
| `captive.apple.com`, `push.apple.com` и поддомены push | `DIRECT` |
| Остальной Apple: `Apple_Domain.list` и `Apple.list` | `Mobile` |
| Google | `Mobile` |
| Meta по доменам | `Mobile` |
| OpenAI: `cdn.openaimerge.com`, затем `geosite-openai.list` | `Mobile` |
| Telegram по доменам | `Mobile` |
| YouTube | `Mobile` |
| Mobile whitelist: `geosite-ru-mobile-whitelist.list` | `DIRECT` |
| `inside-clashx.lst`: ресурсы, проблемные или ограниченные из России | `Mobile` |
| `no-russia-hosts`: ресурсы, ограничивающие доступ с российских IP | `Mobile` |
| Meta по IP | `Mobile` |
| Telegram по IP | `Mobile` |
| Всё остальное, включая российские домены/IP без совпадения выше (`FINAL`) | `DIRECT` |

`cdn.openaimerge.com` нужен OpenAI, но отсутствует в используемом [geosite-openai.list](https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-openai.list), поэтому перед списком сохранено отдельное доменное правило с `force-remote-dns`.

[Mobile whitelist](https://raw.githubusercontent.com/Master-Yoba/shadowrocket-rules/release/rules-geosite/geosite-ru-mobile-whitelist.list) применяется после сервисных VPN-правил и перед списками ограниченных ресурсов. Оба источника ограниченных ресурсов сохраняются: [inside-clashx](https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-clashx.lst) и [no-russia-hosts](https://raw.githubusercontent.com/dartraiden/no-russia-hosts/master/hosts.txt). Они описывают разные причины ограничения доступа.

`no-russia-hosts` подключается как `DOMAIN-SET` с политикой `Mobile` и `force-remote-dns`. Источник содержит родительские домены; фактический охват поддоменов нужно подтвердить практическим тестом Shadowrocket.
