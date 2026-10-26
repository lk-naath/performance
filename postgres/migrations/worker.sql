\set ON_ERROR_STOP on

-- Each worker repeatedly claims small, ordered batches with SKIP LOCKED.
-- A commit after every batch keeps transactions and row locks short while
-- allowing all workers to share the same work queue.
DO $$
DECLARE
    job RECORD;
    affected INTEGER;
    remaining BOOLEAN;
    total_updated BIGINT;
    started_at TIMESTAMPTZ;
BEGIN
    FOR job IN
        SELECT * FROM (VALUES
            ('sale_order',
             'edi_status = COALESCE(edi_status, ''draft''), edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00''), edi_fob_pay_code = COALESCE(edi_fob_pay_code, ''PP'')',
             'edi_status IS NULL OR edi_tset_purpose_code IS NULL OR edi_fob_pay_code IS NULL'),
            ('purchase_order',
             'edi_status = COALESCE(edi_status, ''draft''), edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00'')',
             'edi_status IS NULL OR edi_tset_purpose_code IS NULL'),
            ('account_move',
             'edi_status = COALESCE(edi_status, ''draft''), edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00''), edi_fob_pay_code = COALESCE(edi_fob_pay_code, ''PP'')',
             'edi_status IS NULL OR edi_tset_purpose_code IS NULL OR edi_fob_pay_code IS NULL'),
            ('res_partner',
             'edi_status = COALESCE(edi_status, ''draft''), edi_location_code_qualifier = COALESCE(edi_location_code_qualifier, ''92''), edi_invoice_on_delivery = COALESCE(edi_invoice_on_delivery, ''none'')',
             'edi_status IS NULL OR edi_location_code_qualifier IS NULL OR edi_invoice_on_delivery IS NULL'),
            ('account_move_line',
             'allow_chrg_percent_qual = ''1''',
             'allow_chrg_percent_qual IS NULL'),
            ('sale_order_line',
             'allow_chrg_percent_qual = ''1''',
             'allow_chrg_percent_qual IS NULL'),
            ('stock_move',
             'edi_pack_qualifier = ''OU''',
             'edi_pack_qualifier IS NULL')
        ) AS jobs(table_name, assignments, null_filter)
    LOOP
        total_updated := 0;
        started_at := clock_timestamp();

        LOOP
            EXECUTE format(
                'WITH batch AS (
                     SELECT id
                     FROM %I
                     WHERE %s
                     ORDER BY id
                     LIMIT 10000
                     FOR UPDATE SKIP LOCKED
                 )
                 UPDATE %I AS target
                 SET %s
                 FROM batch
                 WHERE target.id = batch.id',
                job.table_name, job.null_filter,
                job.table_name, job.assignments
            );

            GET DIAGNOSTICS affected = ROW_COUNT;
            total_updated := total_updated + affected;

            IF affected > 0 THEN
                COMMIT;
                RAISE NOTICE '% | elapsed: % | updated: %',
                    job.table_name, clock_timestamp() - started_at, total_updated;
                CONTINUE;
            END IF;

            -- An empty batch can mean another worker currently owns the
            -- remaining rows. Check after releasing this transaction's locks.
            EXECUTE format(
                'SELECT EXISTS (SELECT 1 FROM %I WHERE %s)',
                job.table_name, job.null_filter
            ) INTO remaining;

            IF remaining THEN
                COMMIT;
                PERFORM pg_sleep(0.2);
            ELSE
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
END
$$;
