
#!/usr/bin/env bash

START=$SECONDS

for i in 1 2 3 4; do
    PGAPPNAME="edi_migration_$i" \
    psql -d medik8-staging6jul26 -f worker.sql 2>&1 \
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
ls -lh worker_{1..4}.log

printf '\nRemaining NULL records:\n'
psql -d medik8-staging6jul26 -t -A -c \
  "SELECT COUNT(*) FROM account_move WHERE edi_status IS NULL;"

