#!/usr/bin/env bash
#
# netdiag.sh - Layer-by-layer connectivity check, from the NIC to the Internet.
#
# Walks the same steps you would do by hand on a "the Internet is down"
# ticket: interface -> IP -> gateway -> Internet -> DNS, and stops at the
# first layer that fails so you know where to look.
#
# Usage: ./netdiag.sh [test-ip]
#        (defaults to pinging 1.1.1.1 and resolving example.com)
#

set -u

TEST_IP="${1:-1.1.1.1}"
TEST_NAME="example.com"

# Colors only when writing to a terminal (not when piped to a file)
if [ -t 1 ]; then
  GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; NC=$'\e[0m'
else
  GREEN=""; RED=""; YELLOW=""; NC=""
fi

ok()   { printf '  %s[ OK ]%s %s\n' "$GREEN"  "$NC" "$1"; }
fail() { printf '  %s[FAIL]%s %s\n' "$RED"    "$NC" "$1"; }
warn() { printf '  %s[WARN]%s %s\n' "$YELLOW" "$NC" "$1"; }

for cmd in ip ping getent; do
  command -v "$cmd" > /dev/null || { echo "Missing '$cmd' (iproute2 / iputils packages)." >&2; exit 1; }
done

echo "== 1. Network interfaces =="
# Interfaces that are UP, ignoring loopback
mapfile -t IFACES < <(ip -o link show up | awk -F': ' '$2 != "lo" {print $2}' | cut -d@ -f1)
if [ ${#IFACES[@]} -eq 0 ]; then
  fail "No interface is up. Check the cable, Wi-Fi, or whether the NIC is disabled."
  exit 1
fi
ok "Interfaces up: ${IFACES[*]}"

echo "== 2. IP addresses =="
ADDRS=$(ip -o -4 addr show scope global | awk '{print $2": "$4}')
if [ -z "$ADDRS" ]; then
  fail "No interface has an IPv4 address. DHCP problem?"
  exit 1
fi
while read -r line; do
  ok "$line"
  # 169.254.x.x = APIPA: the box never got a lease from the DHCP server
  case "$line" in
    *169.254.*) warn "Link-local address (169.254.x.x): DHCP server did not answer." ;;
  esac
done <<< "$ADDRS"

echo "== 3. Default gateway =="
GW=$(ip route show default | awk '/default/ {print $3; exit}')
if [ -z "$GW" ]; then
  fail "No default route. The box does not know how to reach the Internet."
  exit 1
fi
if ping -c 2 -W 2 "$GW" > /dev/null 2>&1; then
  ok "Gateway $GW is reachable."
else
  warn "Gateway $GW does not answer ping (some routers block it)."
fi

echo "== 4. Internet (no DNS) =="
if ping -c 2 -W 3 "$TEST_IP" > /dev/null 2>&1; then
  ok "Internet is reachable ($TEST_IP answers)."
else
  fail "Cannot reach $TEST_IP. The problem is between the router and the ISP."
  exit 1
fi

echo "== 5. DNS resolution =="
if getent hosts "$TEST_NAME" > /dev/null 2>&1; then
  ok "DNS works: $TEST_NAME -> $(getent hosts "$TEST_NAME" | awk '{print $1; exit}')"
else
  fail "Internet works but names do not resolve. Check the DNS servers:"
  grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/        /'
  exit 1
fi

echo
echo "${GREEN}All good: the network works end to end.${NC}"
