# Parallel PostgreSQL update

The migration query lives in [`worker.sql`](worker.sql). The Bash runner starts independent `psql` sessions; `FOR UPDATE SKIP LOCKED` lets each session claim a different batch.

## Run with four workers

```sh
postgres/migrations/run.sh --workers 4 --database medik8-staging6jul26
```

The defaults are four workers, database `medik8-staging6jul26` (or `PGDATABASE`), and `worker.sql` in this folder. Logs are saved under `postgres/migrations/logs/` with a timestamp and worker number. The runner prints elapsed time, checks worker failures, and reports how many `account_move` rows still have a `NULL` EDI status.

Try worker counts such as 1, 2, 4, and 8 on comparable data and database load. More workers can increase contention, so compare elapsed time and database load rather than assuming the largest count is fastest.

## Change the work

Edit `worker.sql` to change the target table, assignment, predicate, or batch size. Every worker executes the same SQL file. The selected rows should stop matching the `WHERE` condition after update so workers eventually finish.
