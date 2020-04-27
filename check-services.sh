#!/usr/bin/env bash
#
# check-services.sh - Are the services that should be running actually running?
#
# Works with systemd (systemctl) and falls back to SysV init (service)
# on older boxes. Exit code is the number of services that are down, so
# it can be used from cron or a monitoring check.
#
# Usage: ./check-services.sh [service ...]
#        ./check-services.sh sshd nginx mysql
#

set -u

if [ $# -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=(sshd cron rsyslog)
fi

if command -v systemctl > /dev/null && [ -d /run/systemd/system ]; then
  is_running() { systemctl is-active --quiet "$1"; }
else
  is_running() { service "$1" status > /dev/null 2>&1; }
fi

DOWN=0
for svc in "${SERVICES[@]}"; do
  if is_running "$svc"; then
    printf '  [ UP ] %s\n' "$svc"
  else
    printf '  [DOWN] %s\n' "$svc"
    DOWN=$((DOWN + 1))
  fi
done

exit "$DOWN"
