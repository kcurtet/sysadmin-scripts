#!/usr/bin/env bash
#
# diskusage.sh - What is filling up the disk?
#
# Shows usage per filesystem and the biggest directories under a path.
# First thing to run on a "disk full" alert.
#
# Usage: ./diskusage.sh [PATH] [COUNT]
#        ./diskusage.sh            -> your home directory, top 10
#        sudo ./diskusage.sh / 15  -> whole system, top 15
#

set -u

TARGET="${1:-$HOME}"
TOP="${2:-10}"

echo "== Usage per filesystem =="
df -hP -x tmpfs -x devtmpfs -x squashfs -x overlay

echo
echo "== Top $TOP directories under $TARGET =="
# -x: stay on this filesystem, don't descend into other mounts
du -xh --max-depth=2 "$TARGET" 2>/dev/null | sort -rh | head -n "$TOP"

echo
echo "== Inode usage =="
# A disk can be "full" with free space left if it runs out of inodes
df -iP -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR==1 || $5+0 >= 80'

echo
echo "== Usual suspects =="
for dir in "$HOME/.cache" "$HOME/.local/share/Trash" /var/log /var/cache/apt/archives /var/cache/yum /tmp; do
  [ -d "$dir" ] && printf '%8s  %s\n' "$(du -sh "$dir" 2>/dev/null | cut -f1)" "$dir"
done

echo
echo "Ways to free some space:"
echo "  - User cache:         rm -rf ~/.cache/*   (rebuilt on demand)"
echo "  - systemd journal:    sudo journalctl --vacuum-size=200M"
echo "  - Old packages (apt): sudo apt-get autoremove && sudo apt-get clean"
echo "  - Old packages (yum): sudo yum clean all"
