#!/usr/bin/env bash
#
# check-services.sh - Are the services that should be running actually running?
#
# Works with systemd (systemctl) and falls back to SysV init (service)
# on older boxes. Exit code is the number of services that are down, so
# it can be used from cron or a monitoring check.
#
# Usage: ./check-services.sh [-r] [service ...]
#        ./check-services.sh sshd nginx mysql
#        sudo ./check-services.sh -r nginx   -> try to restart it if down
#

set -u

RESTART=0
if [ "${1:-}" = "-r" ]; then
  RESTART=1
  shift
fi

if [ $# -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=(sshd cron rsyslog)
fi

if command -v systemctl > /dev/null && [ -d /run/systemd/system ]; then
  is_running() { systemctl is-active --quiet "$1"; }
  restart()    { systemctl restart "$1"; }
else
  is_running() { service "$1" status > /dev/null 2>&1; }
  restart()    { service "$1" restart; }
fi

DOWN=0
for svc in "${SERVICES[@]}"; do
  if is_running "$svc"; then
    printf '  [ UP ] %s\n' "$svc"
  else
    printf '  [DOWN] %s\n' "$svc"
    if [ "$RESTART" -eq 1 ]; then
      if restart "$svc" && is_running "$svc"; then
        printf '         %s restarted OK\n' "$svc"
        logger -t check-services "$svc was down, restarted"
        continue
      fi
      printf '         restart of %s FAILED\n' "$svc"
    fi
    DOWN=$((DOWN + 1))
  fi
done

exit "$DOWN"
