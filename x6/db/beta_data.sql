# removing the mark that DB is updated from script
DELETE FROM conflines WHERE name = 'DB_Update_From_Script';
#  DATA
UPDATE rates JOIN destinations ON destinations.id = rates.destination_id SET rates.prefix = destinations.prefix, rates.name = destinations.name WHERE rates.name = '' AND rates.prefix = '';
INSERT INTO roles (name) SELECT 'partner' FROM DUAL WHERE (SELECT COUNT(*) FROM roles WHERE name = 'partner') = 0;
INSERT IGNORE INTO acc_rights (name, nice_name, permission_group, right_type) VALUES ('payment_gateways', 'Payment_Gateways', 'Plugins', 'reseller');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_number', 'G2' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_number');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_issue_date', 'G3' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_issue_date');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_period_start', 'A7' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_period_start');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_period_end', 'D7' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_period_end');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_timezone', 'G7' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_timezone');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_name', 'A2' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_name');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details1', 'A3' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details1');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details2', 'B3' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details2');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details3', 'C3' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details3');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details4', 'A4' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details4');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details5', 'B4' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details5');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_client_details6', 'A5' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_client_details6');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_destination_number', 'A13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_destination_number');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_prefix', 'B13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_prefix');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_name', 'F13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_name');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_quantity', 'I13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_quantity');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_total_time', 'H13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_total_time');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_details_price', 'J13' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_details_price');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_price', 'E25' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_price');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_price_with_vat', 'E26' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_price_with_vat');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_comment', 'D27' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_comment');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_debt', 'D12' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_debt');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_debt_tax', 'F12' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_debt_tax');
INSERT INTO conflines (name, value) SELECT 'Cell_x6_inv_total_amount_due', 'I26' FROM dual WHERE NOT EXISTS (SELECT * FROM conflines WHERE name = 'Cell_x6_inv_total_amount_due');
INSERT INTO partner_groups (name, `comment`) SELECT 'Default', 'Default Partner group' FROM dual WHERE NOT EXISTS (SELECT * FROM partner_groups WHERE name = 'Default');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '249','<b>249 - Partners call limit reached.</b><br>Partner is not allowed to make more simultaneous calls.<br>Increase his limit in users settings if you want to allow him to make more simultaneous calls.<br>For more information please consult online manual at wiki.kolmisoft.com<br>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '249');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '250','<b>250 - Partner is blocked</b><br>Unblock partner to allow him and his users to make calls.<br>For more information please consult online manual at wiki.kolmisoft.com<br>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '250');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '251','<b>251 - Low balance for partner</b><br>Increase balance for partner to allow him and his users to make calls.<br>For more information please use Call Tracing or consult online manual at wiki.kolmisoft.com<br>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '251');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '252','<b>252 - Too low balance for partner for more simultaneous calls</b><br>Increase balance for partner to allow him and his users to make more calls at the same time.<br> For more information please use Call Tracing or consult online manual at wiki.kolmisoft.com<br>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '252');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '253','<b>253 - Partner does not allow loss calls</b><br>This happens when partner sets lower price for his user compared to the price he buys from system owner and user is not allowed to make loss calls.<br>System saves partner from getting loss. Set higher rate or allow loss calls for partners user to fix this problem.<br>For more information please consult online manual at wiki.kolmisoft.com<br> ' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '253');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '254','<b>254 - No Rates for Partner</b><br/>This cause indicates, that partner does not have rates for the call destination.<br/><br/>What you can do:<br/><ol><li>Check which tariff plan Partner is using.</li><li>Apply the correct rates for your destination.</li><li>Use Call Tracing to find the exact problem.</li></ol> ' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '254');
INSERT INTO `pbx_pools` (`id`, `name`, `comment`, `owner_id`) VALUES (1, 'Global', 'Global PBX Pool is a set of Extensions which will be used if Extension is not found in other PBX Pools', 0);
DELETE FROM conflines WHERE name = 'Default_device_qualify_time';
UPDATE role_rights SET permission = 1 WHERE role_id = (SELECT id from roles where name = 'reseller') and right_id = (SELECT id from rights where action = 'recordings' and controller = 'recordings');
UPDATE role_rights SET permission = 1 WHERE role_id = (SELECT id from roles where name = 'reseller') and right_id = (SELECT id from rights where action = 'bulk_management' and controller = 'recordings');
UPDATE role_rights SET permission = 1 WHERE role_id = (SELECT id from roles where name = 'reseller') and right_id = (SELECT id from rights where action = 'bulk_delete' and controller = 'recordings');
DELETE FROM conflines WHERE name = 'Prepaid_Invoice_Show_Balance_Line';
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '255','<b>255 - Destination is in blacklist</b>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '255');
INSERT IGNORE INTO hangupcausecodes (code, description) SELECT '256','<b>256 - Destination is not in whitelist</b>' FROM dual WHERE NOT EXISTS (SELECT * FROM hangupcausecodes WHERE code = '256');
# ^^^^^^ WRITE ABOVE THIS LINE ^^^^^
# marking that DB is updated from script
INSERT INTO conflines (name, value) VALUES ('DB_Update_From_Script', 1);
