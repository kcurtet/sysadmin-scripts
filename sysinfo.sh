#!/usr/bin/env bash
#
# sysinfo.sh - Quick summary of a Linux box, ready to paste into a ticket.
#
# Gathers in one place what the next support tier always asks for:
# OS, hardware, memory, disks, network and uptime.
#
# Usage: ./sysinfo.sh
#        ./sysinfo.sh > "$(hostname)-info.txt"
#

set -u

section() { printf '\n== %s ==\n' "$1"; }

section "System"
echo "Hostname:  $(hostname -f 2>/dev/null || hostname)"
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "OS:        ${PRETTY_NAME:-unknown}"
elif [ -r /etc/redhat-release ]; then
  echo "OS:        $(cat /etc/redhat-release)"
fi
echo "Kernel:    $(uname -r) ($(uname -m))"
echo "Uptime:    $(uptime -p 2>/dev/null || uptime)"
echo "Date:      $(date '+%Y-%m-%d %H:%M %Z')"

section "CPU"
CPU=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
echo "Model:     ${CPU:-unknown}"
echo "Cores:     $(nproc)"
echo "Load avg:  $(cut -d' ' -f1-3 /proc/loadavg) (1, 5, 15 min)"
if command -v systemd-detect-virt > /dev/null; then
  # Prints "none" on bare metal
  echo "Virt:      $(systemd-detect-virt 2>/dev/null)"
fi

section "Memory"
free -h | awk 'NR==1 || /^Mem|^Swap/'

section "Disks"
# Real filesystems only, skip tmpfs and container overlays
df -hP -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null
# Shout if any filesystem is above 90%
df -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
  | awk 'NR>1 {gsub("%","",$5); if ($5 >= 90) print "WARNING: " $6 " is at " $5 "%"}'

section "Network"
if command -v ip > /dev/null; then
  ip -br -4 addr show scope global
  echo "Gateway:   $(ip route show default | awk '/default/ {print $3; exit}')"
else
  # Old boxes (CentOS 6 and friends) only ship net-tools
  ifconfig -a | awk '/inet / && $2 !~ /^127\./ {print $2}'
  echo "Gateway:   $(route -n | awk '$1 == "0.0.0.0" {print $2; exit}')"
fi
echo "DNS:       $(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null)"

section "Logged in users"
who || true
