-- Run after the batched migration. DROP INDEX CONCURRENTLY must run
-- outside an explicit transaction block.

DROP INDEX CONCURRENTLY IF EXISTS migrate_sale_order_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_purchase_order_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_account_move_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_res_partner_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_account_move_line_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_sale_order_line_null_edi_defaults_idx;
DROP INDEX CONCURRENTLY IF EXISTS migrate_stock_move_null_edi_defaults_idx;
