#!/usr/bin/env bash
#
# backup.sh - Incremental snapshots with rsync, one directory per run.
#
# Each run creates a dated directory (e.g. 2019-06-21_0300). Unchanged
# files are hard-linked (--link-dest) against the previous snapshot, so
# every snapshot looks complete but only takes the space of what changed.
# Only the last N snapshots are kept.
#
# Usage: ./backup.sh SOURCE DEST [KEEP]
#        ./backup.sh /home/kevin/docs /mnt/backup/docs 7
#
# Cron example (every day at 03:00):
#   0 3 * * * /opt/sysadmin-scripts/backup.sh /home/kevin/docs /mnt/backup/docs 7
#

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 SOURCE DEST [KEEP]" >&2
  exit 1
fi

SRC="${1%/}"
DEST="${2%/}"
KEEP="${3:-7}"
STAMP=$(date '+%Y-%m-%d_%H%M')

command -v rsync > /dev/null || { echo "rsync not found, install it first." >&2; exit 1; }
[ -d "$SRC" ] || { echo "Source $SRC does not exist." >&2; exit 1; }
mkdir -p "$DEST"
# Absolute path: rsync resolves a relative --link-dest against DEST itself
DEST=$(cd "$DEST" && pwd)

NEW="$DEST/$STAMP"
LATEST="$DEST/latest"   # symlink to the most recent snapshot
LOG="$DEST/backup.log"

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

log "Start: $SRC -> $NEW"

# Use the previous snapshot as the base so unchanged files are not copied again
LINK_OPT=()
[ -d "$LATEST" ] && LINK_OPT=(--link-dest="$LATEST")

rsync -a --delete \
  --exclude='.cache/' --exclude='*.tmp' \
  "${LINK_OPT[@]}" \
  "$SRC/" "$NEW/"

ln -sfn "$STAMP" "$LATEST"
log "Done: $(du -sh "$NEW" | cut -f1) in $NEW"

# Rotation: drop the oldest snapshots, keep only the last $KEEP
mapfile -t SNAPS < <(find "$DEST" -mindepth 1 -maxdepth 1 -type d \
  -name '????-??-??_????' | sort)
EXTRA=$(( ${#SNAPS[@]} - KEEP ))
for (( i = 0; i < EXTRA; i++ )); do
  log "Removing old snapshot: ${SNAPS[i]}"
  rm -rf -- "${SNAPS[i]}"
done

log "Finished. Snapshots kept: $(( ${#SNAPS[@]} - (EXTRA > 0 ? EXTRA : 0) ))"
