#!/usr/bin/env bash

WORKERS=10
DATABASE="medik8-staging6jul26"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workers) WORKERS="$2"; shift 2 ;;
        --database) DATABASE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

START=$SECONDS

for ((i = 1; i <= WORKERS; i++)); do
    PGAPPNAME="edi_migration_$i" \
    psql -d "$DATABASE" -f worker.sql 2>&1 \
      | tee "worker_$i.log" &
done

wait

ELAPSED=$((SECONDS - START))

printf '\n========== MIGRATION SUMMARY ==========\n'
printf 'Total elapsed time: %02d:%02d:%02d\n' \
    $((ELAPSED / 3600)) \
    $(((ELAPSED % 3600) / 60)) \
    $((ELAPSED % 60))

printf '\nWorker logs:\n'
for ((i = 1; i <= WORKERS; i++)); do
    ls -lh "worker_$i.log"
done
