# 2013-04-11 MK
# Logic behind all this is following:
# European currencies, which are changed to EUR, are recalculated by their last exchange rate and everywhere changed to EUR
# All other currencies are changed to new country curriency with proper exchange rate
# XAF, XAF - name fixes
# Modified currencies ATS, BEF, CYP, DEM, ESP, FIM, FRF, GRD, ITL, NLG, PTE, SIT, MTL, SKK, MGF, SRG, VEB, SDD, GHC, ROL, ZWD, XOF, XAF, EEK, KYD, MZM, BCEAO, BEAC

# ATS Austrian Schilling  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 13.7603, fee = fee / 13.7603,  gross = gross / 13.7603, tax = tax / 13.7603 WHERE currency = 'ATS';
UPDATE payments SET currency = 'EUR', amount = amount / 13.7603, fee = fee / 13.7603,  gross = gross / 13.7603, tax = tax / 13.7603 WHERE currency = 'ATS';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 13.7603 WHERE currency = 'ATS';

# BEF Belgian Franc  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 40.34, fee = fee / 40.34,  gross = gross / 40.34, tax = tax / 40.34 WHERE currency = 'BEF';
UPDATE payments SET currency = 'EUR', amount = amount / 40.34, fee = fee / 40.34,  gross = gross / 40.34, tax = tax / 40.34 WHERE currency = 'BEF';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 40.34 WHERE currency = 'BEF';

# CYP Cypriot Pound  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 0.585274, fee = fee / 0.585274,  gross = gross / 0.585274, tax = tax / 0.585274 WHERE currency = 'CYP';
UPDATE payments SET currency = 'EUR', amount = amount / 0.585274, fee = fee / 0.585274,  gross = gross / 0.585274, tax = tax / 0.585274 WHERE currency = 'CYP';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 0.585274 WHERE currency = 'CYP';

# DEM German Mark  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 1.95583, fee = fee / 1.95583,  gross = gross / 1.95583, tax = tax / 1.95583 WHERE currency = 'DEM';
UPDATE payments SET currency = 'EUR', amount = amount / 1.95583, fee = fee / 1.95583,  gross = gross / 1.95583, tax = tax / 1.95583 WHERE currency = 'DEM';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 1.955834 WHERE currency = 'DEM';

# ESP Spanish Peseta  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 166386, fee = fee / 166386,  gross = gross / 166386, tax = tax / 166386 WHERE currency = 'ESP';
UPDATE payments SET currency = 'EUR', amount = amount / 166386, fee = fee / 166386,  gross = gross / 166386, tax = tax / 166386 WHERE currency = 'ESP';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 166386 WHERE currency = 'ESP';

# FIM Finnish Markka  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 5.94573, fee = fee / 5.94573,  gross = gross / 5.94573, tax = tax / 5.94573 WHERE currency = 'FIM';
UPDATE payments SET currency = 'EUR', amount = amount / 5.94573, fee = fee / 5.94573,  gross = gross / 5.94573, tax = tax / 5.94573 WHERE currency = 'FIM';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 5.94573 WHERE currency = 'FIM';

# FRF French Franc  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 6.55957, fee = fee / 6.55957,  gross = gross / 6.55957, tax = tax / 6.55957 WHERE currency = 'FRF';
UPDATE payments SET currency = 'EUR', amount = amount / 166.559576386, fee = fee / 6.55957,  gross = gross / 6.55957, tax = tax / 6.55957 WHERE currency = 'FRF';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 6.55957 WHERE currency = 'FRF';

# GRD Greek Drachma  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 340750, fee = fee / 340750,  gross = gross / 340750, tax = tax / 340750 WHERE currency = 'GRD';
UPDATE payments SET currency = 'EUR', amount = amount / 340750, fee = fee / 340750,  gross = gross / 340750, tax = tax / 340750 WHERE currency = 'GRD';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 340750 WHERE currency = 'GRD';

# ITL Italian Lira  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 1936.27, fee = fee / 1936.27,  gross = gross / 1936.27, tax = tax / 1936.27 WHERE currency = 'ITL';
UPDATE payments SET currency = 'EUR', amount = amount / 1936.27, fee = fee / 1936.27,  gross = gross / 1936.27, tax = tax / 1936.27 WHERE currency = 'ITL';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 1936.27 WHERE currency = 'ITL';

# NLG Dutch Guilder  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 2.20371, fee = fee / 2.20371,  gross = gross / 2.20371, tax = tax / 2.20371 WHERE currency = 'NLG';
UPDATE payments SET currency = 'EUR', amount = amount / 2.20371, fee = fee / 2.20371,  gross = gross / 2.20371, tax = tax / 2.20371 WHERE currency = 'NLG';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 2.20371 WHERE currency = 'NLG';

# PTE Portuguese Escudo  -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 200.482, fee = fee / 200.482,  gross = gross / 200.482, tax = tax / 200.482 WHERE currency = 'PTE';
UPDATE payments SET currency = 'EUR', amount = amount / 200.482, fee = fee / 200.482,  gross = gross / 200.482, tax = tax / 200.482 WHERE currency = 'PTE';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 200.482 WHERE currency = 'PTE';

# SIT Slovenian Tolar   -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 239.640, fee = fee / 239.640,  gross = gross / 239.640, tax = tax / 239.640 WHERE currency = 'SIT';
UPDATE payments SET currency = 'EUR', amount = amount / 239.640, fee = fee / 239.640,  gross = gross / 239.640, tax = tax / 239.640 WHERE currency = 'SIT';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 239.640 WHERE currency = 'SIT';

# MTL Maltese Pound   -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 0.429300, fee = fee / 0.429300,  gross = gross / 0.429300, tax = tax / 0.429300 WHERE currency = 'MTL';
UPDATE payments SET currency = 'EUR', amount = amount / 0.429300, fee = fee / 0.429300,  gross = gross / 0.429300, tax = tax / 0.429300 WHERE currency = 'MTL';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 0.429300 WHERE currency = 'MTL';

# SKK Slovak Koruna   -> EUR
UPDATE ccorders SET currency = 'EUR', amount = amount / 30.1260, fee = fee / 30.1260,  gross = gross / 30.1260, tax = tax / 30.1260 WHERE currency = 'SKK';
UPDATE payments SET currency = 'EUR', amount = amount / 30.1260, fee = fee / 30.1260,  gross = gross / 30.1260, tax = tax / 30.1260 WHERE currency = 'SKK';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 30.1260 WHERE currency = 'SKK';

# EEK Estonian kroon
UPDATE ccorders SET currency = 'EUR', amount = amount / 15.6466, fee = fee / 15.6466,  gross = gross / 15.6466, tax = tax / 15.6466 WHERE currency = 'EEK';
UPDATE payments SET currency = 'EUR', amount = amount / 15.6466, fee = fee / 15.6466,  gross = gross / 15.6466, tax = tax / 15.6466 WHERE currency = 'EEK';
UPDATE vouchers SET currency = 'EUR', credit_with_vat = credit_with_vat / 15.6466 WHERE currency = 'EEK';

UPDATE cardgroups SET tell_balance_in_currency = 'EUR' WHERE tell_balance_in_currency IN ('ATS','BEF','CYP','DEM','ESP','FIM','FRF','GRD','ITL','NLG','PTE','SIT','MTL','SKK', 'EEK');
UPDATE sms_tariffs SET currency = 'EUR' WHERE currency IN ('ATS','BEF','CYP','DEM','ESP','FIM','FRF','GRD','ITL','NLG','PTE','SIT','MTL','SKK', 'EEK');
UPDATE tariffs SET currency = 'EUR' WHERE currency IN ('ATS','BEF','CYP','DEM','ESP','FIM','FRF','GRD','ITL','NLG','PTE','SIT','MTL','SKK', 'EEK');

UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'ATS');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'BEF');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'CYP');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'DEM');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'ESP');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'FIM');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'FRF');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'GRD');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'ITL');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'NLG');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'PTE');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'SIT');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'MTL');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'SKK');
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'EUR') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'EEK');


DELETE FROM currencies WHERE name IN ('ATS','BEF','CYP','DEM','ESP','FIM','FRF','GRD','ITL','NLG','PTE','SIT','MTL','SKK', 'EEK');



#----

UPDATE currencies SET full_name = 'West African CFA Franc' WHERE name = 'XOF';
UPDATE currencies SET full_name = 'Central African CFA Franc' WHERE name = 'XAF';

# MGF Malagasy Franc -> MGA Malagasy Ariary
UPDATE currencies SET full_name = 'Malagasy Ariary', name = 'MGA', exchange_rate = exchange_rate  * 5 WHERE name = 'MGF';
UPDATE cardgroups SET tell_balance_in_currency = 'MGA' WHERE tell_balance_in_currency = 'MGF';
UPDATE ccorders SET currency = 'MGA', amount = amount * 5, fee = fee * 5,  gross = gross * 5, tax = tax * 5 WHERE currency = 'MGF';
UPDATE payments SET currency = 'MGA', amount = amount * 5, fee = fee * 5,  gross = gross * 5, tax = tax * 5 WHERE currency = 'MGF';
UPDATE sms_tariffs SET currency = 'MGA' WHERE currency = 'MGF';
UPDATE tariffs SET currency = 'MGA' WHERE currency = 'MGF';
UPDATE vouchers SET currency = 'MGA', credit_with_vat = credit_with_vat * 5 WHERE currency = 'MGF';

# SRG Suriname Guilder -> SRD Surinamese dollar
UPDATE currencies SET full_name = 'Surinamese dollar', name = 'SRD', exchange_rate = exchange_rate  * 1000 WHERE name = 'SRG';
UPDATE cardgroups SET tell_balance_in_currency = 'SRD' WHERE tell_balance_in_currency = 'SRG';
UPDATE ccorders SET currency = 'SRD', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'SRG';
UPDATE payments SET currency = 'SRD', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'SRG';
UPDATE sms_tariffs SET currency = 'SRD' WHERE currency = 'SRG';
UPDATE tariffs SET currency = 'SRD' WHERE currency = 'SRG';
UPDATE vouchers SET currency = 'SRD', credit_with_vat = credit_with_vat * 1000 WHERE currency = 'SRG';

# VEB Venezuelan Bolivar -> VEF Venezuelan Bolivar
UPDATE currencies SET full_name = 'Venezuelan bolivar', name = 'VEF', exchange_rate = exchange_rate  * 1000 WHERE name = 'VEB';
UPDATE cardgroups SET tell_balance_in_currency = 'VEF' WHERE tell_balance_in_currency = 'VEB';
UPDATE ccorders SET currency = 'VEF', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'VEB';
UPDATE payments SET currency = 'VEF', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'VEB';
UPDATE sms_tariffs SET currency = 'VEF' WHERE currency = 'VEB';
UPDATE tariffs SET currency = 'VEF' WHERE currency = 'VEB';
UPDATE vouchers SET currency = 'VEF', credit_with_vat = credit_with_vat * 1000 WHERE currency = 'VEB';

# SDD Sudanese Dinar  -> SDG Sudanese Pound
UPDATE currencies SET full_name = 'Sudanese Pound', name = 'SDG', exchange_rate = exchange_rate  * 1000 WHERE name = 'SDD';
UPDATE cardgroups SET tell_balance_in_currency = 'SDG' WHERE tell_balance_in_currency = 'SDD';
UPDATE ccorders SET currency = 'SDG', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'SDD';
UPDATE payments SET currency = 'SDG', amount = amount * 1000, fee = fee * 1000,  gross = gross * 1000, tax = tax * 1000 WHERE currency = 'SDD';
UPDATE sms_tariffs SET currency = 'SDG' WHERE currency = 'SDD';
UPDATE tariffs SET currency = 'SDG' WHERE currency = 'SDD';
UPDATE vouchers SET currency = 'SDG', credit_with_vat = credit_with_vat * 1000 WHERE currency = 'SDD';

# GHC Ghanaian Cedi  -> GHS Ghana cedi
UPDATE currencies SET full_name = 'Ghana cedi', name = 'GHS', exchange_rate = exchange_rate  * 10000 WHERE name = 'GHC';
UPDATE cardgroups SET tell_balance_in_currency = 'GHS' WHERE tell_balance_in_currency = 'GHC';
UPDATE ccorders SET currency = 'GHS', amount = amount * 10000, fee = fee * 10000,  gross = gross * 10000, tax = tax * 10000 WHERE currency = 'GHC';
UPDATE payments SET currency = 'GHS', amount = amount * 10000, fee = fee * 10000,  gross = gross * 10000, tax = tax * 10000 WHERE currency = 'GHC';
UPDATE sms_tariffs SET currency = 'GHS' WHERE currency = 'GHC';
UPDATE tariffs SET currency = 'GHS' WHERE currency = 'GHC';
UPDATE vouchers SET currency = 'GHS', credit_with_vat = credit_with_vat * 10000 WHERE currency = 'GHC';

# ROL Romanian Leu  -> RON Romanian leu
UPDATE currencies SET full_name = 'Romanian leu', name = 'RON', exchange_rate = exchange_rate  * 10000 WHERE name = 'ROL';
UPDATE cardgroups SET tell_balance_in_currency = 'RON' WHERE tell_balance_in_currency = 'ROL';
UPDATE ccorders SET currency = 'RON', amount = amount * 10000, fee = fee * 10000,  gross = gross * 10000, tax = tax * 10000 WHERE currency = 'ROL';
UPDATE payments SET currency = 'RON', amount = amount * 10000, fee = fee * 10000,  gross = gross * 10000, tax = tax * 10000 WHERE currency = 'ROL';
UPDATE sms_tariffs SET currency = 'RON' WHERE currency = 'ROL';
UPDATE tariffs SET currency = 'RON' WHERE currency = 'ROL';
UPDATE vouchers SET currency = 'RON', credit_with_vat = credit_with_vat * 10000 WHERE currency = 'ROL';

# ZWD Zimbabwean Dollar  -> ZWL Zimbabwean Dollar, exchange rate 1 ZWL=10^25 ZWD, will not convert..
UPDATE currencies SET full_name = 'Zimbabwean Dollar', name = 'ZWL' WHERE name = 'ZWD';
UPDATE cardgroups SET tell_balance_in_currency = 'ZWL' WHERE tell_balance_in_currency = 'ZWD';
UPDATE ccorders SET currency = 'ZWL' WHERE currency = 'ZWD';
UPDATE payments SET currency = 'ZWL' WHERE currency = 'ZWD';
UPDATE sms_tariffs SET currency = 'ZWL' WHERE currency = 'ZWD';
UPDATE tariffs SET currency = 'ZWL' WHERE currency = 'ZWD';
UPDATE vouchers SET currency = 'ZWL' WHERE currency = 'ZWD';

# BCEAO
UPDATE cardgroups SET tell_balance_in_currency = 'XOF' WHERE tell_balance_in_currency = 'BCEAO';
UPDATE ccorders SET currency = 'XOF' WHERE currency = 'BCEAO';
UPDATE payments SET currency = 'XOF' WHERE currency = 'BCEAO';
UPDATE sms_tariffs SET currency = 'XOF' WHERE currency = 'BCEAO';
UPDATE tariffs SET currency = 'XOF' WHERE currency = 'BCEAO';
UPDATE vouchers SET currency = 'XOF' WHERE currency = 'BCEAO';
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'XOF') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'BCEAO');

# BEAC
UPDATE cardgroups SET tell_balance_in_currency = 'XAF' WHERE tell_balance_in_currency = 'BEAC';
UPDATE ccorders SET currency = 'XAF' WHERE currency = 'BEAC';
UPDATE payments SET currency = 'XAF' WHERE currency = 'BEAC';
UPDATE sms_tariffs SET currency = 'XAF' WHERE currency = 'BEAC';
UPDATE tariffs SET currency = 'XAF' WHERE currency = 'BEAC';
UPDATE vouchers SET currency = 'XAF' WHERE currency = 'BEAC';
UPDATE users SET currency_id = (SELECT id FROM currencies WHERE name = 'XAF') WHERE currency_id = (SELECT id FROM currencies WHERE name = 'BEAC');

DELETE FROM currencies WHERE name IN ('BCEAO', 'BEAC');

# MZM Mozambican metical -> MZN
UPDATE currencies SET full_name = 'Mozambican metical ', name = 'MZN', curr_update=0 WHERE name = 'MZM';
UPDATE cardgroups SET tell_balance_in_currency = 'MZN' WHERE tell_balance_in_currency = 'MZM';
UPDATE ccorders SET currency = 'MZN' WHERE currency = 'MZM';
UPDATE payments SET currency = 'MZN' WHERE currency = 'MZM';
UPDATE sms_tariffs SET currency = 'MZN' WHERE currency = 'MZM';
UPDATE tariffs SET currency = 'MZN' WHERE currency = 'MZM';
UPDATE vouchers SET currency = 'MZN' WHERE currency = 'MZM';

UPDATE currencies SET full_name = 'Cayman Islands Dollar ', curr_update=0 WHERE name = 'KYD';
