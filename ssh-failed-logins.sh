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

# Debian/Ubuntu log to auth.log, RHEL/CentOS to secure
if [ -r /var/log/auth.log ]; then
  LOGFILE=/var/log/auth.log
elif [ -r /var/log/secure ]; then
  LOGFILE=/var/log/secure
else
  echo "Cannot read auth.log or secure (run with sudo?)" >&2
  exit 1
fi

read_log() { cat "$LOGFILE"; }

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
