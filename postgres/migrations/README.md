# Parallel PostgreSQL backfill

`worker.sql` contains the complete backfill from the project-root `migrate.sql`.
It processes all seven tables in batches of 10,000 rows. Each batch is committed
independently, and `FOR UPDATE SKIP LOCKED` lets concurrent workers claim
different rows without duplicating work. The updates only fill NULL values, so
the migration can be safely rerun after an interruption. Its helper procedure
is temporary to each worker's database session.

Run with 16 workers and the default database:

```sh
postgres/migrations/migrate.sh
```

Choose a worker count and database as needed:

```sh
postgres/migrations/migrate.sh --workers 16 --database medik8-staging6jul26
```

The runner also accepts `WORKERS` and `PGDATABASE` environment variables;
command-line options take precedence. It prints table row counts, total runtime,
and errors, and returns a failure status if any worker fails.

The default is 16 workers. More workers can increase I/O and lock contention,
so lower the count if the database is already under heavy load. The SQL batch
limit is set to 10,000 rows.
