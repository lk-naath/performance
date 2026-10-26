-- Run before the batched migration. CREATE INDEX CONCURRENTLY must run
-- outside an explicit transaction block.

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_sale_order_null_edi_defaults_idx
    ON sale_order (id)
    WHERE edi_status IS NULL
       OR edi_tset_purpose_code IS NULL
       OR edi_fob_pay_code IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_purchase_order_null_edi_defaults_idx
    ON purchase_order (id)
    WHERE edi_status IS NULL
       OR edi_tset_purpose_code IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_account_move_null_edi_defaults_idx
    ON account_move (id)
    WHERE edi_status IS NULL
       OR edi_tset_purpose_code IS NULL
       OR edi_fob_pay_code IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_res_partner_null_edi_defaults_idx
    ON res_partner (id)
    WHERE edi_status IS NULL
       OR edi_location_code_qualifier IS NULL
       OR edi_invoice_on_delivery IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_account_move_line_null_edi_defaults_idx
    ON account_move_line (id)
    WHERE allow_chrg_percent_qual IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_sale_order_line_null_edi_defaults_idx
    ON sale_order_line (id)
    WHERE allow_chrg_percent_qual IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS migrate_stock_move_null_edi_defaults_idx
    ON stock_move (id)
    WHERE edi_pack_qualifier IS NULL;
