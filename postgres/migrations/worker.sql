\set ON_ERROR_STOP on

-- Add or edit backfill rules in the table below. Each rule has:
--   1. table_name: the table to update (must have an id column)
--   2. assignments: values to set, using COALESCE to preserve existing values
--   3. rows_to_fix: the condition that identifies rows needing an update
--
-- The procedure is temporary to this psql session, so nothing is installed
-- permanently in the database. It commits after each batch, which a function
-- cannot do; call it directly (without wrapping this file in BEGIN/COMMIT).
CREATE PROCEDURE pg_temp.run_backfill()
LANGUAGE plpgsql
AS $$
DECLARE
    job RECORD;
    affected INTEGER;
    remaining BOOLEAN;
    total_updated BIGINT;
    started_at TIMESTAMPTZ;
BEGIN
    -- ================================================================
    -- BACKFILL RULES: add one row here for each table.
    -- Example:
    --   ('my_table', 'my_field = COALESCE(my_field, ''default'')',
    --    'my_field IS NULL'),
    -- ================================================================
    FOR job IN
        SELECT *
        FROM (VALUES
            ('sale_order',
             'edi_status = COALESCE(edi_status, ''draft''), ' ||
             'edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00''), ' ||
             'edi_fob_pay_code = COALESCE(edi_fob_pay_code, ''PP'')',
             'edi_status IS NULL OR ' ||
             'edi_tset_purpose_code IS NULL OR ' ||
             'edi_fob_pay_code IS NULL'),
            ('purchase_order',
             'edi_status = COALESCE(edi_status, ''draft''), ' ||
             'edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00'')',
             'edi_status IS NULL OR edi_tset_purpose_code IS NULL'),
            ('account_move',
             'edi_status = COALESCE(edi_status, ''draft''), ' ||
             'edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, ''00''), ' ||
             'edi_fob_pay_code = COALESCE(edi_fob_pay_code, ''PP'')',
             'edi_status IS NULL OR ' ||
             'edi_tset_purpose_code IS NULL OR ' ||
             'edi_fob_pay_code IS NULL'),
            ('res_partner',
             'edi_status = COALESCE(edi_status, ''draft''), ' ||
             'edi_location_code_qualifier = COALESCE(edi_location_code_qualifier, ''92''), ' ||
             'edi_invoice_on_delivery = COALESCE(edi_invoice_on_delivery, ''none'')',
             'edi_status IS NULL OR ' ||
             'edi_location_code_qualifier IS NULL OR ' ||
             'edi_invoice_on_delivery IS NULL'),
            ('account_move_line',
             'allow_chrg_percent_qual = ''1''',
             'allow_chrg_percent_qual IS NULL'),
            ('sale_order_line',
             'allow_chrg_percent_qual = ''1''',
             'allow_chrg_percent_qual IS NULL'),
            ('stock_move',
             'edi_pack_qualifier = ''OU''',
             'edi_pack_qualifier IS NULL')
        ) AS backfill_rules(table_name, assignments, rows_to_fix)
    LOOP
        total_updated := 0;
        started_at := clock_timestamp();

        -- Keep taking batches from this table until no matching rows remain.
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
                job.table_name, job.rows_to_fix,
                job.table_name, job.assignments
            );

            GET DIAGNOSTICS affected = ROW_COUNT;
            total_updated := total_updated + affected;

            IF affected > 0 THEN
                COMMIT;
                CONTINUE;
            END IF;

            -- An empty batch can mean another worker currently owns the
            -- remaining rows. Check after releasing this transaction's locks.
            EXECUTE format(
                'SELECT EXISTS (SELECT 1 FROM %I WHERE %s)',
                job.table_name, job.rows_to_fix
            ) INTO remaining;

            IF remaining THEN
                COMMIT;
                PERFORM pg_sleep(0.2);
            ELSE
                EXIT;
            END IF;
        END LOOP;

        IF total_updated > 0 THEN
            RAISE NOTICE '%: updated % rows in %',
                job.table_name, total_updated, clock_timestamp() - started_at;
        END IF;
    END LOOP;
END
$$;

CALL pg_temp.run_backfill();
