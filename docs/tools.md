# Сетевые команды

Две утилиты заменяют повторяемые ручные вызовы `ping`, `nc` и `ssh -D/-L`.
Никакие адреса серверов, результаты проверок и ключи внутри репозитория не хранятся.
Установка на macOS не нужна: используются штатные Bash, OpenSSH, ping и nc.
На Linux нужны Bash, OpenSSH client, iputils-ping и netcat-openbsd.

```bash
./scripts/net-check.sh example.com 443
./scripts/ssh-tunnel.sh socks my-vps 1080
./scripts/ssh-tunnel.sh forward my-vps 8080 127.0.0.1 80
```

`my-vps` задайте локально в `~/.ssh/config`; реальные HostName, User и IdentityFile
остаются вне Git. `TARGET_HOST` разрешается и достигается со стороны VPS.
Поддерживаются DNS-имена/IPv4; IPv6-литералы этими оболочками не обрабатываются.
SOCKS-клиенту укажите `127.0.0.1:1080`, а для DNS через туннель — SOCKS5 hostname
(например, `curl --proxy socks5h://127.0.0.1:1080 https://example.com`).

Туннель слушает только `127.0.0.1`, работает до Ctrl-C и прекращает запуск при занятом
локальном порте. Пароли и host-key checking обрабатывает обычный SSH.
Это не VPN для всей системы; скрипт не меняет системные proxy-настройки.
В Linux приватные ключи должны иметь права 600, каталог `~/.ssh` — 700.

`net-check` делает три ICMP-пробы и одну попытку TCP-подключения.
Его код возврата: 0 — TCP доступен, 1 — недоступен/нет зависимости, 2 — неверные аргументы.
ICMP может блокироваться при работающем TCP. Скрипт не измеряет пропускную способность
и не доказывает использование нужного VPN. Вывод содержит введённый адрес: не коммитьте
логи с частными адресами и не прикладывайте их публично без проверки.

Проверка перед изменением скриптов:

```bash
bash -n scripts/net-check.sh
bash -n scripts/ssh-tunnel.sh
shellcheck scripts/*.sh
gitleaks dir . --redact=100
gitleaks git . --redact=100 --log-opts=--all
```

ShellCheck и Gitleaks входят в `mac-setup/Brewfile`. Проверка по шаблонам не заменяет
просмотр `git diff --cached`, особенно для персональных данных и VPN-профилей.
