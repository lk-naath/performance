\set ON_ERROR_STOP on

DO $$
DECLARE
    affected INTEGER;
    total_updated BIGINT := 0;
    started_at TIMESTAMPTZ := clock_timestamp();
BEGIN
    LOOP
        WITH batch AS (
            SELECT id
            FROM account_move
            WHERE edi_status IS NULL
            ORDER BY id
            LIMIT 10000
            FOR UPDATE SKIP LOCKED
        )
        UPDATE account_move AS am
        SET edi_status = 'draft'
        FROM batch
        WHERE am.id = batch.id
          AND am.edi_status IS NULL;

        GET DIAGNOSTICS affected = ROW_COUNT;

        total_updated := total_updated + affected;

        IF affected > 0 THEN
            COMMIT;

            RAISE NOTICE
                'Elapsed: % | Updated: %',
                clock_timestamp() - started_at,
                total_updated;
        ELSE
            -- Zero rows may mean another worker holds locks.
            IF EXISTS (
                SELECT 1
                FROM account_move
                WHERE edi_status IS NULL
            ) THEN
                COMMIT;
                PERFORM pg_sleep(0.2);
            ELSE
                EXIT;
            END IF;
        END IF;
    END LOOP;
END
$$;
