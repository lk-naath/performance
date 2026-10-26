#!/usr/bin/env bash

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKERS="${WORKERS:-16}"
DATABASE="${PGDATABASE:-medik8-staging6jul26}"
LOG_DIR="$SCRIPT_DIR/logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"

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

mkdir -p "$LOG_DIR"
START=$SECONDS
declare -a PIDS=()
declare -a LOGS=()
FAILED=0

for ((i = 1; i <= WORKERS; i++)); do
    LOG_FILE="$LOG_DIR/${RUN_ID}_worker_${i}.log"
    LOGS+=("$LOG_FILE")
    PGAPPNAME="edi_migration_$i" \
    psql -X -v ON_ERROR_STOP=1 -d "$DATABASE" -f "$SCRIPT_DIR/worker.sql" 2>&1 \
      | tee "$LOG_FILE" &
    PIDS+=("$!")
done

for i in "${!PIDS[@]}"; do
    if ! wait "${PIDS[$i]}"; then
        echo "Worker $((i + 1)) failed; see ${LOGS[$i]}" >&2
        FAILED=1
    fi
done

ELAPSED=$((SECONDS - START))

printf '\n========== MIGRATION SUMMARY ==========\n'
printf 'Total elapsed time: %02d:%02d:%02d\n' \
    $((ELAPSED / 3600)) \
    $(((ELAPSED % 3600) / 60)) \
    $((ELAPSED % 60))

printf '\nWorker logs: %s\n' "$LOG_DIR"

if (( FAILED != 0 )); then
    echo "Migration failed. Resolve the worker error and rerun; completed rows are safe to skip." >&2
    exit 1
fi
