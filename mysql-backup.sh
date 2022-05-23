#!/usr/bin/env bash
#
# mysql-backup.sh - Dump every MySQL/MariaDB database to its own file.
#
# Credentials are read from ~/.my.cnf so no password ends up in the
# process list or in crontab:
#
#   [client]
#   user=backup
#   password=secret
#
# Usage: ./mysql-backup.sh DEST_DIR
#

set -euo pipefail

DEST="${1:?Usage: $0 DEST_DIR}"
STAMP=$(date '+%Y-%m-%d_%H%M')
OUT="$DEST/$STAMP"

command -v mysqldump > /dev/null || { echo "mysqldump not found." >&2; exit 1; }
mkdir -p "$OUT"

# Skip the internal schemas, they are not worth restoring
DBS=$(mysql -N -e 'SHOW DATABASES' | grep -vE '^(information_schema|performance_schema|sys)$')

for db in $DBS; do
  echo "$(date '+%F %T') dumping $db"
  # --single-transaction gives a consistent dump of InnoDB tables without locking
  mysqldump --single-transaction --routines --triggers --events "$db" > "$OUT/$db.sql"
done

echo "$(date '+%F %T') done: $(du -sh "$OUT" | cut -f1) in $OUT"
