#!/bin/bash
set -euo pipefail

usage() {
  cat <<'HELP'
Usage:
  ./scripts/ssh-tunnel.sh socks SSH_ALIAS [LOCAL_PORT=1080]
  ./scripts/ssh-tunnel.sh forward SSH_ALIAS LOCAL_PORT TARGET_HOST TARGET_PORT
SSH_ALIAS — имя из локального ~/.ssh/config. Bind: только 127.0.0.1.
Туннель работает на переднем плане; Ctrl-C закрывает его.
HELP
}
fail() { echo "$1" >&2; exit 2; }
valid_port() {
  [[ $1 =~ ^[0-9]{1,5}$ ]] || return 1
  (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
[[ $# -ge 2 ]] || { usage >&2; exit 2; }
mode=$1
alias_name=$2
[[ $alias_name =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || fail 'Нужно имя SSH Host без пробелов, user@ и опций.'
case "$mode" in
  socks)
    [[ $# -le 3 ]] || { usage >&2; exit 2; }
    local_port=${3:-1080}
    valid_port "$local_port" || fail 'Локальный порт должен быть числом 1–65535.'
    forwarding=(-D "127.0.0.1:$((10#$local_port))")
    ;;
  forward)
    [[ $# -eq 5 ]] || { usage >&2; exit 2; }
    local_port=$3
    target=$4
    target_port=$5
    if ! valid_port "$local_port" || ! valid_port "$target_port"; then
      fail 'Порты должны быть числами 1–65535.'
    fi
    [[ $target =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || fail 'TARGET_HOST: DNS-имя или IPv4.'
    forwarding=(-L "127.0.0.1:$((10#$local_port)):$target:$((10#$target_port))")
    ;;
  *) usage >&2; exit 2 ;;
esac
command -v ssh >/dev/null || { echo 'Нужен OpenSSH client.' >&2; exit 1; }
echo 'Открываю туннель на loopback; для остановки нажмите Ctrl-C.'
exec ssh -N -T -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  -o ControlMaster=no -o ControlPath=none -o GatewayPorts=no \
  "${forwarding[@]}" "$alias_name"
