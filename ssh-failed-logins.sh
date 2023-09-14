#!/usr/bin/env bash
#
# ssh-failed-logins.sh - Who is hammering SSH on this box?
#
# Counts failed SSH logins per source IP and per username, so you can
# decide what to block (or whether it is time to install fail2ban).
#
# Usage: sudo ./ssh-failed-logins.sh [TOP]
#

set -u

TOP="${1:-10}"

# Debian/Ubuntu log to auth.log, RHEL/CentOS to secure. Newer systems
# may only have the systemd journal, so fall back to that.
if [ -r /var/log/auth.log ]; then
  read_log() { cat /var/log/auth.log; }
elif [ -r /var/log/secure ]; then
  read_log() { cat /var/log/secure; }
elif command -v journalctl > /dev/null; then
  read_log() { journalctl -q --no-pager -u ssh -u sshd --since "-7 days" 2>/dev/null; }
else
  echo "No auth.log, secure or journal available (run with sudo?)" >&2
  exit 1
fi

FAILED=$(read_log | grep -E 'Failed password|Invalid user')

if [ -z "$FAILED" ]; then
  echo "No failed SSH logins found."
  exit 0
fi

echo "Total failed attempts: $(echo "$FAILED" | wc -l)"

echo
echo "== Top $TOP source IPs =="
echo "$FAILED" | grep -oE 'from [0-9a-fA-F.:]+' | awk '{print $2}' \
  | sort | uniq -c | sort -rn | head -n "$TOP"

echo
echo "== Top $TOP usernames tried =="
echo "$FAILED" | sed -nE 's/.*(Failed password for (invalid user )?|Invalid user )([^ ]+) from.*/\3/p' \
  | sort | uniq -c | sort -rn | head -n "$TOP"
