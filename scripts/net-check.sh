#!/bin/bash
set -euo pipefail

usage() { echo 'Usage: ./scripts/net-check.sh HOST [TCP_PORT=443]'; }
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
if [[ $# -lt 1 || $# -gt 2 ]]; then usage >&2; exit 2; fi
host=$1
port=${2:-443}
# Только имя хоста или IPv4; URL, credentials, пробелы и опции не принимаются.
[[ $host =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || { echo 'Нужно DNS-имя или IPv4.' >&2; exit 2; }
[[ $port =~ ^[0-9]{1,5}$ ]] || { echo 'TCP-порт должен быть числом 1–65535.' >&2; exit 2; }
port=$((10#$port))
(( port >= 1 && port <= 65535 )) || { echo 'TCP-порт вне диапазона 1–65535.' >&2; exit 2; }
for cmd in ping nc; do
  command -v "$cmd" >/dev/null || { printf 'Не найдена команда: %s\n' "$cmd" >&2; exit 1; }
done
case $(uname -s) in
  Darwin) ping_args=(-n -c 3 -W 1000 -t 5); nc_args=(-z -G 3 -w 3) ;;
  Linux) ping_args=(-n -c 3 -W 1 -w 5); nc_args=(-z -w 3) ;;
  *) echo 'Поддерживаются macOS и Linux с netcat-openbsd.' >&2; exit 1 ;;
esac
printf 'ICMP: %s (отказ может означать фильтрацию ping)\n' "$host"
if ! ping "${ping_args[@]}" "$host"; then echo 'Ответа ICMP нет; проверяю TCP независимо.'; fi
printf '\nTCP: %s:%s\n' "$host" "$port"
if nc "${nc_args[@]}" "$host" "$port"; then
  echo 'TCP-соединение установлено. Это не проверка TLS, VPN-маршрута или скорости.'
else
  echo 'TCP-соединение не установлено.' >&2
  exit 1
fi
