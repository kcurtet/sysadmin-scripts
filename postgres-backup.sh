#!/usr/bin/env bash
#
# postgres-backup.sh - Dump every PostgreSQL database to its own file,
# plus the cluster-wide roles and tablespaces.
#
# Easiest is to run it as the postgres system user (peer auth, no password):
#
#   sudo -u postgres ./postgres-backup.sh /var/backups/postgres
#
# For a remote server or a dedicated user, use the standard libpq variables
# (PGHOST, PGPORT, PGUSER) and keep the password in ~/.pgpass (chmod 600)
# so it never ends up in the process list or in crontab:
#
#   db01:5432:*:backup:secret
#
# Dumps use pg_dump's custom format (already compressed). Restore with:
#
#   gunzip -c globals.sql.gz | psql -d postgres
#   pg_restore --create -d postgres mydb.dump
#
# Usage: ./postgres-backup.sh DEST_DIR [DAYS_TO_KEEP]
#        ./postgres-backup.sh /var/backups/postgres 14
#

set -euo pipefail

DEST="${1:?Usage: $0 DEST_DIR [DAYS_TO_KEEP]}"
KEEP_DAYS="${2:-14}"
STAMP=$(date '+%Y-%m-%d_%H%M')
OUT="$DEST/$STAMP"

for cmd in psql pg_dump pg_dumpall; do
  command -v "$cmd" > /dev/null || { echo "$cmd not found." >&2; exit 1; }
done
mkdir -p "$OUT"

# Roles and tablespaces live outside any database, pg_dump does not include them
echo "$(date '+%F %T') dumping globals (roles, tablespaces)"
pg_dumpall --globals-only | gzip > "$OUT/globals.sql.gz"

# Every database that accepts connections, minus the templates
DBS=$(psql -d postgres -AtX -c \
  "SELECT datname FROM pg_database WHERE datallowconn AND NOT datistemplate ORDER BY 1")

# Read line by line: database names may contain spaces
while IFS= read -r db; do
  [[ -n "$db" ]] || continue
  echo "$(date '+%F %T') dumping $db"
  # pg_dump runs in a single snapshot, so the dump is consistent without locking writers
  pg_dump --format=custom --file="$OUT/$db.dump" "$db"
done <<< "$DBS"

# Drop dumps older than KEEP_DAYS
find "$DEST" -mindepth 1 -maxdepth 1 -type d -name '????-??-??_????' -mtime +"$KEEP_DAYS" \
  -exec rm -rf -- {} +

echo "$(date '+%F %T') done: $(du -sh "$OUT" | cut -f1) in $OUT"
