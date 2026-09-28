#!/bin/bash
# Read-only macOS network diagnostics.
# Intended for comparing a healthy connection with an outage.
# Does not change network settings and does not require sudo.

VERSION="2026-09-28.1"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export LC_ALL=C
export LANG=C

OUTDIR="$HOME/Desktop"
[ -d "$OUTDIR" ] || OUTDIR="$HOME"
OUT="$OUTDIR/network_diag_$(date '+%Y-%m-%d_%H-%M-%S').txt"

exec > >(tee "$OUT") 2>&1

section() {
    printf '\n\n========== %s ==========\n' "$1"
}

echo "NETWORK DIAGNOSTICS"
echo "Version: $VERSION"
echo "Started: $(date)"
echo "Log: $OUT"


section "SYSTEM"

sw_vers 2>&1
echo
uptime 2>&1


section "DEFAULT ROUTE"

DEFAULT_ROUTE="$(route -n get default 2>&1)"
echo "$DEFAULT_ROUTE"

GATEWAY="$(echo "$DEFAULT_ROUTE" | awk '/gateway:/{print $2; exit}')"
INTERFACE="$(echo "$DEFAULT_ROUTE" | awk '/interface:/{print $2; exit}')"

echo
echo "Detected interface: ${INTERFACE:-NONE}"
echo "Detected gateway:   ${GATEWAY:-NONE}"


section "LOCAL INTERFACE"

if [ -n "$INTERFACE" ]; then
    echo "--- IPv4 address ---"
    ipconfig getifaddr "$INTERFACE" 2>&1

    echo
    echo "--- Interface state ---"
    ifconfig "$INTERFACE" 2>&1 | awk '
        /flags=/ ||
        /^[[:space:]]*inet / ||
        /^[[:space:]]*inet6 / ||
        /status:/
    '

    echo
    echo "--- DHCP information ---"
    ipconfig getpacket "$INTERFACE" 2>&1 | \
        egrep 'yiaddr|server_identifier|router|domain_name_server|lease_time' || true
else
    echo "No default interface detected."
fi


section "MACOS NETWORK STATE"

scutil --nwi 2>&1


section "ROUTES"

echo "--- IPv4 routing table ---"
netstat -rn -f inet 2>&1 | sed -n '1,60p'

echo
echo "--- Route to 1.1.1.1 ---"
route -n get 1.1.1.1 2>&1 | egrep 'destination:|gateway:|interface:|flags:' || true

echo
echo "--- Route to 8.8.8.8 ---"
route -n get 8.8.8.8 2>&1 | egrep 'destination:|gateway:|interface:|flags:' || true


section "PROXY AND VPN/TUNNEL STATE"

echo "--- macOS proxy settings ---"
scutil --proxy 2>&1

echo
echo "--- macOS VPN connections ---"
scutil --nc list 2>&1 || true

echo
echo "--- Tunnel interfaces ---"
FOUND_UTUN=0

for U in $(ifconfig -l 2>/dev/null | tr ' ' '\n' | grep '^utun'); do
    FOUND_UTUN=1
    echo
    echo "[$U]"
    ifconfig "$U" 2>&1 | awk '
        /flags=/ ||
        /^[[:space:]]*inet / ||
        /^[[:space:]]*inet6 / ||
        /status:/
    '
done

if [ "$FOUND_UTUN" -eq 0 ]; then
    echo "No utun interfaces found."
fi


section "LOCAL ROUTER TEST"

if [ -n "$GATEWAY" ]; then
    echo "Ping gateway: $GATEWAY"
    ping -n -c 3 -W 1000 "$GATEWAY" 2>&1
    echo "exit=$?"
else
    echo "No gateway detected."
fi


section "INTERNET BY IP"

echo "--- Ping 1.1.1.1 ---"
ping -n -c 3 -W 1000 1.1.1.1 2>&1
echo "exit=$?"

echo
echo "--- Ping 8.8.8.8 ---"
ping -n -c 3 -W 1000 8.8.8.8 2>&1
echo "exit=$?"

echo
echo "--- HTTPS to 1.1.1.1 without DNS ---"
curl -4 -k \
    --noproxy '*' \
    --connect-timeout 4 \
    --max-time 10 \
    -sS \
    -o /dev/null \
    -w 'HTTP=%{http_code} IP=%{remote_ip} CONNECT=%{time_connect}s TLS=%{time_appconnect}s TOTAL=%{time_total}s\n' \
    'https://1.1.1.1/cdn-cgi/trace'
echo "curl_exit=$?"


section "DNS CONFIGURATION"

scutil --dns 2>&1


section "DNS TESTS"

echo "--- macOS system resolver ---"
dscacheutil -q host -a name www.apple.com 2>&1
echo "exit=$?"

dns_test() {
    SERVER="$1"

    echo
    echo "--- DNS server: $SERVER ---"

    case "$SERVER" in
        *:*)
            echo "IPv6 resolver; direct dig test skipped."
            ;;
        *)
            dig @"$SERVER" www.apple.com A \
                +time=2 \
                +tries=1 \
                +noall \
                +comments \
                +answer \
                +stats 2>&1
            echo "dig_exit=$?"
            ;;
    esac
}

echo
echo "--- Configured DNS servers ---"

DNS_SERVERS="$(
    scutil --dns 2>/dev/null |
    awk '/nameserver\[[0-9]+\] : / {print $3}' |
    awk '!seen[$0]++' |
    head -6
)"

if [ -n "$DNS_SERVERS" ]; then
    for DNS in $DNS_SERVERS; do
        dns_test "$DNS"
    done
else
    echo "No DNS servers found in scutil output."
fi

echo
echo "--- Public DNS controls ---"
dns_test 1.1.1.1
dns_test 8.8.8.8

echo
echo "--- Public DNS over TCP: 1.1.1.1 ---"
dig @1.1.1.1 www.apple.com A \
    +tcp \
    +time=2 \
    +tries=1 \
    +noall \
    +comments \
    +answer \
    +stats 2>&1
echo "dig_tcp_exit=$?"


section "HTTP / HTTPS"

curl4() {
    LABEL="$1"
    URL="$2"

    echo
    echo "--- $LABEL ---"
    echo "$URL"

    curl -4 \
        --noproxy '*' \
        --connect-timeout 4 \
        --max-time 10 \
        -sS \
        -o /dev/null \
        -w 'HTTP=%{http_code} IP=%{remote_ip} DNS=%{time_namelookup}s CONNECT=%{time_connect}s TLS=%{time_appconnect}s TOTAL=%{time_total}s\n' \
        "$URL"

    echo "curl_exit=$?"
}

curl4 "Apple via DNS + HTTPS" "https://www.apple.com/"
curl4 "Google connectivity test via DNS + HTTPS" "https://www.google.com/generate_204"


section "IPV6"

echo "--- IPv6 default route ---"
route -n get -inet6 default 2>&1 || true

echo
echo "--- IPv6 HTTPS test ---"
echo "Failure here alone is normal on a network without IPv6."

curl -6 \
    --noproxy '*' \
    --connect-timeout 4 \
    --max-time 8 \
    -sS \
    -o /dev/null \
    -w 'HTTP=%{http_code} IP=%{remote_ip} DNS=%{time_namelookup}s CONNECT=%{time_connect}s TLS=%{time_appconnect}s TOTAL=%{time_total}s\n' \
    'https://www.apple.com/'
echo "curl_exit=$?"


section "SHORT TRACEROUTE"

echo "--- 1.1.1.1 ---"
traceroute -n -m 8 -w 1 -q 1 1.1.1 2>&1

echo
echo "--- 8.8.8.8 ---"
traceroute -n -m 8 -w 1 -q 1 8.8.8.8 2>&1


section "FINISHED"

echo "Finished: $(date)"
echo
echo "Diagnostic file:"
echo "$OUT"

# Reveal the result in Finder so a non-technical user can send it easily.
open -R "$OUT" >/dev/null 2>&1 || true
