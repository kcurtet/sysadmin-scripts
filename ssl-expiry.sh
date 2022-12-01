#!/usr/bin/env bash
#
# ssl-expiry.sh - Warn before TLS certificates expire.
#
# Connects to each host with openssl and prints how many days are left.
# Exit code is 1 if any certificate expires within the warning window.
#
# Usage: ./ssl-expiry.sh host[:port] ...
#        ./ssl-expiry.sh -f hosts.txt     (one host[:port] per line, # comments ok)
#        WARN_DAYS=30 ./ssl-expiry.sh example.com mail.example.com:993
#

set -u

WARN_DAYS="${WARN_DAYS:-21}"

if [ "${1:-}" = "-f" ]; then
  [ -r "${2:-}" ] || { echo "Cannot read hosts file '${2:-}'" >&2; exit 2; }
  mapfile -t HOSTS < <(grep -vE '^\s*(#|$)' "$2")
else
  HOSTS=("$@")
fi

if [ ${#HOSTS[@]} -eq 0 ]; then
  echo "Usage: $0 host[:port] ..." >&2
  exit 2
fi

command -v openssl > /dev/null || { echo "openssl not found." >&2; exit 2; }

RC=0
NOW=$(date +%s)
for entry in "${HOSTS[@]}"; do
  host="${entry%%:*}"
  port="${entry##*:}"
  [ "$port" = "$entry" ] && port=443

  END=$(echo | timeout 10 openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$END" ]; then
    printf '  [ERR ] %-35s could not get certificate\n' "$host:$port"
    RC=1
    continue
  fi

  DAYS=$(( ( $(date -d "$END" +%s) - NOW ) / 86400 ))
  if [ "$DAYS" -lt "$WARN_DAYS" ]; then
    printf '  [WARN] %-35s %4d days left (%s)\n' "$host:$port" "$DAYS" "$END"
    RC=1
  else
    printf '  [ OK ] %-35s %4d days left\n' "$host:$port" "$DAYS"
  fi
done

exit "$RC"
