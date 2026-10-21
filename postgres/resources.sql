-- PostgreSQL resource and planner settings for a dedicated 8-core, 32 GB host.
-- These are starting values, not workload-verified optimal settings.
-- Review storage and PostgreSQL version before applying. Settings marked
-- "restart" require a PostgreSQL restart; the rest can be reloaded.
--
-- Apply with an administrator connection, for example:
--   psql -d postgres -v ON_ERROR_STOP=1 -f postgres/resources.sql
-- Then restart PostgreSQL for shared_buffers. ALTER SYSTEM writes
-- postgresql.auto.conf, which takes precedence over postgresql.conf.

-- Memory (dedicated database host)
ALTER SYSTEM SET shared_buffers = '8GB';              -- restart required
ALTER SYSTEM SET effective_cache_size = '24GB';       -- planner estimate only
ALTER SYSTEM SET work_mem = '8MB';                    -- per sort/hash operation; can multiply
ALTER SYSTEM SET maintenance_work_mem = '1GB';

-- WAL and checkpoints (starting point for a write-heavy workload)
ALTER SYSTEM SET wal_buffers = '-1';                  -- automatic sizing based on shared_buffers
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET checkpoint_completion_target = '0.9';

-- Planner and I/O: verify SSD/NVMe and filesystem first.
-- 1.1 is a plausible SSD/NVMe starting point; use a higher value for HDD.
ALTER SYSTEM SET random_page_cost = '1.1';
-- Leave effective_io_concurrency at the PostgreSQL default until the storage
-- type is known; on supported SSD/NVMe systems, benchmark a higher value.

-- Maintenance
ALTER SYSTEM SET autovacuum_max_workers = '4';
ALTER SYSTEM SET autovacuum_vacuum_cost_limit = '1000';
ALTER SYSTEM SET autovacuum_vacuum_cost_delay = '2ms';

-- Do not reset shared_preload_libraries blindly: extensions may depend on it.
-- Reload settings that do not require restart:
SELECT pg_reload_conf();

-- account_move example (run in the target database, after confirming the
-- actual schema/table and observing vacuum lag). Uncomment only when suitable.
-- ALTER TABLE public.account_move SET (
--   autovacuum_vacuum_scale_factor = 0.02,
--   autovacuum_vacuum_threshold = 5000,
--   autovacuum_analyze_scale_factor = 0.01,
--   autovacuum_analyze_threshold = 5000
-- );
