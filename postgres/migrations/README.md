# Parallel PostgreSQL backfill

Run the migration with four workers and the default database:

```sh
postgres/migrations/migrate.sh
```

Pass options to choose the worker count and database:

```sh
postgres/migrations/migrate.sh --workers 20 --database medik8-staging6jul26
```

You can also use `WORKERS` and `PGDATABASE` environment variables. Command-line options override those values. Defaults are four workers and database `medik8-staging6jul26`.

The runner creates a temporary non-unique partial index on `public.account_move(id)` for rows where `edi_status IS NULL`, starts the workers, checks worker exit status and remaining rows, and drops the index concurrently after a successful run. If a worker fails or rows remain, the index is left in place for diagnosis or retry. Logs are written under `postgres/migrations/logs/` with a timestamp and worker number.

The concurrent index build and drop avoid an exclusive lock that blocks normal table writes, but use I/O and the temporary index consumes disk space during the backfill. Compare worker counts such as 1, 2, 4, and 8 on comparable database load; more workers can increase contention.
