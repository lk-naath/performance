-- Restore values for records where fields affected by removed defaults are NULL.
-- This covers shared mixin fields on their concrete models as well as model fields.

UPDATE sale_order
SET edi_status = COALESCE(edi_status, 'draft'),
    edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, '00'),
    edi_fob_pay_code = COALESCE(edi_fob_pay_code, 'PP')
WHERE edi_status IS NULL
   OR edi_tset_purpose_code IS NULL
   OR edi_fob_pay_code IS NULL;

UPDATE purchase_order
SET edi_status = COALESCE(edi_status, 'draft'),
    edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, '00')
WHERE edi_status IS NULL
   OR edi_tset_purpose_code IS NULL;

UPDATE account_move
SET edi_status = COALESCE(edi_status, 'draft'),
    edi_tset_purpose_code = COALESCE(edi_tset_purpose_code, '00'),
    edi_fob_pay_code = COALESCE(edi_fob_pay_code, 'PP')
WHERE edi_status IS NULL
   OR edi_tset_purpose_code IS NULL
   OR edi_fob_pay_code IS NULL;

UPDATE res_partner
SET edi_status = COALESCE(edi_status, 'draft'),
    edi_location_code_qualifier = COALESCE(edi_location_code_qualifier, '92'),
    edi_invoice_on_delivery = COALESCE(edi_invoice_on_delivery, 'none')
WHERE edi_status IS NULL
   OR edi_location_code_qualifier IS NULL
   OR edi_invoice_on_delivery IS NULL;

UPDATE account_move_line
SET allow_chrg_percent_qual = '1'
WHERE allow_chrg_percent_qual IS NULL;

UPDATE sale_order_line
SET allow_chrg_percent_qual = '1'
WHERE allow_chrg_percent_qual IS NULL;

UPDATE stock_move
SET edi_pack_qualifier = 'OU'
WHERE edi_pack_qualifier IS NULL;
