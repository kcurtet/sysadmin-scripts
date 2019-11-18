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

ok()   { echo "  [ OK ] $1"; }
fail() { echo "  [FAIL] $1"; }
warn() { echo "  [WARN] $1"; }

for cmd in ip ping getent; do
  command -v "$cmd" > /dev/null || { echo "Missing '$cmd' (iproute2 / iputils packages)." >&2; exit 1; }
done

echo "== 1. Default gateway =="
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

echo "== 2. Internet (no DNS) =="
if ping -c 2 -W 3 "$TEST_IP" > /dev/null 2>&1; then
  ok "Internet is reachable ($TEST_IP answers)."
else
  fail "Cannot reach $TEST_IP. The problem is between the router and the ISP."
  exit 1
fi

echo "== 3. DNS resolution =="
if getent hosts "$TEST_NAME" > /dev/null 2>&1; then
  ok "DNS works: $TEST_NAME -> $(getent hosts "$TEST_NAME" | awk '{print $1; exit}')"
else
  fail "Internet works but names do not resolve. Check the DNS servers:"
  grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/        /'
  exit 1
fi

echo
echo "All good: the network works end to end."
