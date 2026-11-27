# Clash Verge Rev для Windows

| Подключение ноутбука | URL для импорта в Clash |
| --- | --- |
| Обычный Wi‑Fi | [Wi‑Fi](https://raw.githubusercontent.com/bouvreuil34/network-configs/main/clash-verge/wifi.yaml) |
| Раздача интернета с телефона | [Mobile](https://raw.githubusercontent.com/bouvreuil34/network-configs/main/clash-verge/mobile.yaml) |

Оба профиля используют одну подписку «Платный VPN». В Wi‑Fi выбери свой узел в группе `PROXY`. Mobile сохраняет выбор LTE-узлов из Shadowrocket. OpenAI идёт через турецкие узлы, `atomic-pr.ru` и `volgaparking.ru` через российские, а мобильный белый список обслуживается напрямую по порядку правил профиля.

## Подключение

1. В Shadowrocket скопируй **URL подписки** «Платный VPN». Если провайдер предлагает отдельную ссылку формата Clash/Mihomo, используй её. Для Mobile в подписке должны быть узлы с именами LTE.
2. В Clash Verge Rev открой **Profiles → Global Extend Script** и вставь следующий скрипт. Замени `PASTE_SUBSCRIPTION_URL_HERE` на URL подписки и сохрани. Если у тебя уже есть глобальный скрипт, добавь этот блок в его функцию `main` до `return config`.

```js
function main(config) {
  const provider = config["proxy-providers"]?.["bouvreuil34-paid-vpn"]
  const subscriptionUrl = "PASTE_SUBSCRIPTION_URL_HERE"
  if (provider && /^https?:\/\//i.test(subscriptionUrl)) {
    provider.type = "http"
    provider.url = subscriptionUrl
    provider.path = "./proxies/network-configs-paid-vpn.yaml"
    provider.interval = 3600
  }
  return config
}
```

3. В **Profiles** импортируй оба URL из таблицы как **Remote**. Настрой интервал обновления 1440 минут для обоих профилей и оставь режим **Rule**.
4. Активируй **Wi‑Fi**, открой **Proxies** и выбери узел. Затем один раз активируй **Mobile** при обычном доступе в интернет, чтобы загрузились списки правил и узлы LTE. При раздаче с телефона запускай Clash на ноутбуке и переключайся на **Mobile**.
5. Для браузера включи **System Proxy**. Для приложений, которые игнорируют системный прокси, включи **TUN Mode**.

URL подписки и скачанные узлы хранятся на ноутбуке. С GitHub загружаются профили и публичные списки правил. Профили переключаются вручную.

Маршруты перенесены из [Wi‑Fi](../shadowrocket/wifi.conf) и [Mobile](../shadowrocket/mobile.conf). Текстовые списки используют совместимые типы правил Mihomo. Для Apple и YouTube подключены списки Clash от тех же авторов. Mihomo использует системный DNS в Wi‑Fi, а в Mobile добавляет DNS-over-HTTPS через LTE для основных проксируемых списков. Правки в самих файлах Shadowrocket нужно переносить в YAML, а списки `rule-providers` обновляются по своим URL.
