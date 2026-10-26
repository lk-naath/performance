#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKERS="${WORKERS:-16}"
DATABASE="${PGDATABASE:-medik8-staging6jul26}"

usage() {
    echo "Usage: $0 [--workers COUNT] [--database NAME]" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workers)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            WORKERS="$2"; shift 2 ;;
        --database)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            DATABASE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

if ! [[ "$WORKERS" =~ ^[1-9][0-9]*$ ]]; then
    echo "--workers must be a positive integer" >&2
    exit 2
fi

START=$SECONDS
declare -a PIDS=()
FAILED=0

printf 'Database: %s | workers: %s\n' "$DATABASE" "$WORKERS"

for ((i = 1; i <= WORKERS; i++)); do
    psql -X -v ON_ERROR_STOP=1 -d "$DATABASE" -f "$SCRIPT_DIR/worker.sql" &
    PIDS+=("$!")
done

for i in "${!PIDS[@]}"; do
    if ! wait "${PIDS[$i]}"; then
        echo "Worker $((i + 1)) failed." >&2
        FAILED=1
    fi
done

ELAPSED=$((SECONDS - START))

printf '\n========== MIGRATION SUMMARY ==========\n'
printf 'Total elapsed time: %02d:%02d:%02d\n' \
    $((ELAPSED / 3600)) \
    $(((ELAPSED % 3600) / 60)) \
    $((ELAPSED % 60))

if (( FAILED != 0 )); then
    echo "Migration failed. Fix the error and rerun; completed rows are safe to skip." >&2
    exit 1
fi

echo "Migration completed successfully."
