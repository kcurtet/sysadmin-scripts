#!/usr/bin/env bash
#
# port-check.sh - Is that TCP port open from here?
#
# Uses bash's /dev/tcp, so it works on minimal boxes without nc, nmap
# or telnet installed. Good for "is the firewall letting me through?".
#
# Usage: ./port-check.sh host port [port ...]
#        ./port-check.sh db01 3306
#        ./port-check.sh web01 22 80 443
#        TIMEOUT=10 ./port-check.sh vpn.example.com 1194
#

set -u

if [ $# -lt 2 ]; then
  echo "Usage: $0 host port [port ...]" >&2
  exit 2
fi

HOST="$1"
shift
TIMEOUT="${TIMEOUT:-3}"

RC=0
for port in "$@"; do
  if timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/$HOST/$port" 2>/dev/null; then
    printf '  [OPEN  ] %s:%s\n' "$HOST" "$port"
  else
    printf '  [CLOSED] %s:%s (or filtered / timed out after %ss)\n' "$HOST" "$port" "$TIMEOUT"
    RC=1
  fi
done

exit "$RC"
