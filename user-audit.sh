#!/usr/bin/env bash
#
# user-audit.sh - Quick local account audit.
#
# Lists human accounts with their last login, who has sudo/root rights,
# and flags the classic problems: extra UID 0 accounts, empty passwords
# and accounts that never logged in.
#
# Usage: sudo ./user-audit.sh
#

set -u

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: /etc/shadow is needed for the password checks." >&2
  exit 1
fi

MIN_UID=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs 2>/dev/null)
MIN_UID="${MIN_UID:-1000}"

echo "== Human accounts (UID >= $MIN_UID) =="
printf '  %-15s %-6s %-20s %s\n' USER UID SHELL "LAST LOGIN"
while IFS=: read -r user _ uid _ _ _ shell; do
  [ "$uid" -ge "$MIN_UID" ] && [ "$uid" -lt 65534 ] || continue
  last_login=$(lastlog -u "$user" 2>/dev/null | awk 'NR==2 {print ($2 ~ /Never/) ? "never" : $4" "$5" "$6" "$9}')
  printf '  %-15s %-6s %-20s %s\n' "$user" "$uid" "$shell" "${last_login:-unknown}"
done < /etc/passwd

echo
echo "== Accounts with UID 0 =="
awk -F: '$3 == 0 {print "  " $1}' /etc/passwd

echo
echo "== sudo / wheel / admin members =="
for group in sudo wheel admin; do
  members=$(getent group "$group" | cut -d: -f4)
  [ -n "$members" ] && echo "  $group: $members"
done
grep -hE '^[^#%].*ALL' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sed 's/^/  sudoers: /'

echo
echo "== Problems =="
PROBLEMS=0
while IFS=: read -r user _ uid _; do
  if [ "$uid" -eq 0 ] && [ "$user" != "root" ]; then
    echo "  [!] $user has UID 0"
    PROBLEMS=$((PROBLEMS + 1))
  fi
done < /etc/passwd
while IFS=: read -r user hash _; do
  if [ -z "$hash" ]; then
    echo "  [!] $user has an EMPTY password"
    PROBLEMS=$((PROBLEMS + 1))
  fi
done < /etc/shadow
[ "$PROBLEMS" -eq 0 ] && echo "  None found."
