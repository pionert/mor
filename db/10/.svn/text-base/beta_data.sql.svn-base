# removing the mark that DB is updated from script
DELETE FROM conflines WHERE name = 'DB_Update_From_Script';
# DATA
SET @admin_id = (SELECT id FROM roles WHERE name = 'admin');
SET @accountant_id = (SELECT id FROM roles WHERE name = 'accountant');
SET @reseller_id = (SELECT id FROM roles WHERE name = 'reseller');
SET @user_id = (SELECT id FROM roles WHERE name = 'user');
SET @guest_id = (SELECT id FROM roles WHERE name = 'guest');
INSERT IGNORE INTO acc_rights (name, nice_name, permission_group, right_type) SELECT 'calling_cards', 'Calling_Cards', 'Plugins', 'reseller' FROM dual WHERE (SELECT COUNT(*) FROM acc_rights WHERE name = 'calling_cards' AND permission_group = 'Plugins' AND right_type = 'reseller') = 0;
INSERT IGNORE INTO acc_rights (name, nice_name, permission_group, right_type) SELECT 'call_shop', 'Call_Shop', 'Plugins', 'reseller' FROM dual WHERE (SELECT COUNT(*) FROM acc_rights WHERE name = 'call_shop' AND permission_group = 'Plugins' AND right_type = 'reseller') = 0;
INSERT IGNORE INTO acc_rights (name, nice_name, permission_group, right_type) SELECT 'sms_addon', 'SMS', 'Plugins', 'reseller' FROM dual WHERE (SELECT COUNT(*) FROM acc_rights WHERE name = 'sms_addon' AND permission_group = 'Plugins' AND right_type = 'reseller') = 0;
INSERT IGNORE INTO acc_rights (name, nice_name, permission_group, right_type) SELECT 'payment_gateways', 'Payment_Gateways', 'Plugins', 'reseller' FROM dual WHERE (SELECT COUNT(*) FROM acc_rights WHERE name= 'payment_gateways' AND permission_group = 'Plugins' AND right_type = 'reseller') = 0;
INSERT IGNORE INTO currencies (name, full_name, active) SELECT 'KZT', 'Kazakhstani Tenge', 0 FROM dual WHERE (SELECT COUNT(*) FROM currencies WHERE name = 'KZT' ) = 0;
INSERT IGNORE INTO emails (`name`, `format`, `body`, `owner_id`, `subject`, `template`, `callcenter`, `date_created`) SELECT 'password_reminder', 'html', 'Settings to login to MOR interface:  Login URL: <%= login_url %> Username: <%= login_username %> Password: <%= login_password %>', 0, 'password_reminder', 1, 0, NOW() FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'password_reminder' AND owner_id = 0) = 0;
UPDATE cardgroups SET tell_balance_in_currency = (SELECT name from currencies order by id asc limit 1) where tell_balance_in_currency in ('', NULL);
INSERT IGNORE INTO user_translations (user_id, translation_id, position, active) SELECT 0, translations.id, translations.position, translations.active FROM translations WHERE (SELECT COUNT(*) FROM user_translations) = 0;
# pbxfunction
INSERT IGNORE INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'External DID', 'external_did', 'mor_pbxfunctions', 'external_did', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'External DID') = 0;
UPDATE conflines SET value = 1 WHERE name = 'Default_device_works_not_logged';
UPDATE devices SET context = 'mor_local' WHERE context = 'please_login';
UPDATE devices SET works_not_logged = 1;
UPDATE conflines SET value = 'MOR 10' WHERE value = 'MOR 9' AND name = 'Admin_Browser_Title';
UPDATE conflines SET value = 'MOR 10' WHERE value = 'MOR 9' AND name = 'Version';
UPDATE extlines SET app = 'NoOp' WHERE context = 'mor' AND app = 'Congestion';
INSERT IGNORE INTO conflines(name, value, owner_id) SELECT 'Invoice_page_limit', '20', '0' FROM DUAL WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Invoice_page_limit' AND owner_id = 0) = 0; 
INSERT IGNORE INTO conflines(name, value, owner_id) SELECT 'Prepaid_Invoice_page_limit', '20', '0' FROM DUAL WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Prepaid_Invoice_page_limit' AND owner_id = 0) = 0;
#move main extensions from DB to .conf
UPDATE extlines SET exten='disabled_X.' WHERE context = 'mor' AND exten = '_X.';
DELETE FROM extlines WHERE context = 'mor' AND exten IN ('HANGUP_NOW', 'HANGUP','FAILED','BUSY');
update emails set body =  0x596f7572206465766963652073657474696e67733a200d0a0d0a5365727665722049503a203c253d207365727665725f697020253e0d0a44657669636520747970653a203c253d206465766963655f7479706520253e0d0a557365726e616d653a203c253d206465766963655f757365726e616d6520253e0d0a50617373776f72643a203c253d206465766963655f70617373776f726420253e0d0a0d0a2d2d2d2d0d0a0d0a53657474696e677320746f206c6f67696e20746f204d4f5220696e746572666163653a0d0a0d0a4c6f67696e2055524c3a203c253d206c6f67696e5f75726c20253e0d0a557365726e616d653a203c253d206c6f67696e5f757365726e616d6520253e0d0a50617373776f72643a203c253d206c6f67696e5f70617373776f726420253e0d0a0d0a5468616e6b20796f7520666f72207265676973746572696e6721 where body = 0x596f75206465766963652073657474696e67733a200d0a0d0a5365727665722049503a203c253d207365727665725f697020253e0d0a44657669636520747970653a203c253d206465766963655f7479706520253e0d0a557365726e616d653a203c253d206465766963655f757365726e616d6520253e0d0a50617373776f72643a203c253d206465766963655f70617373776f726420253e0d0a0d0a2d2d2d2d0d0a0d0a53657474696e677320746f206c6f67696e20746f204d4f5220696e746572666163653a0d0a0d0a4c6f67696e2055524c3a203c253d206c6f67696e5f75726c20253e0d0a557365726e616d653a203c253d206c6f67696e5f757365726e616d6520253e0d0a50617373776f72643a203c253d206c6f67696e5f70617373776f726420253e0d0a0d0a5468616e6b20796f7520666f72207265676973746572696e6721;
UPDATE hangupcausecodes SET description = '<b>218 - Reseller does not allow loss calls</b><br>This happens when reseller sets lower price for his user compared to the price he buys from system owner and user is not allowed to make loss calls.<br>System saves reseller from getting loss. Set higher rate or allow loss calls for resellers user to fix this problem.<br>For more information please consult online manual at wiki.kolmisoft.com<br>' WHERE code = '218';
update conflines set value="" where name = 'WebMoney_Purse' and value = "Z616776332783";
INSERT IGNORE INTO translations (name, native_name, short_name, position, active, flag) SELECT 'Česká republika', '', 'cz', 32, 0, 'cze' FROM dual WHERE (SELECT COUNT(*) FROM translations where flag = 'cze') = 0;
INSERT IGNORE INTO user_translations (user_id, translation_id, position, active) SELECT 0, translations.id, translations.position, translations.active FROM translations WHERE (SELECT COUNT(*) FROM user_translations where translation_id = (select id from translations where flag = 'cze')) = 0 and flag = 'cze';
UPDATE conflines set value = '' WHERE name = 'Last_Crash_Exception_Class';
UPDATE conflines SET value = 'MOR 10' WHERE value = 'MOR 0.8' AND name = 'Admin_Browser_Title';
UPDATE conflines SET value = 'MOR 10' WHERE value = 'MOR 0.8' AND name = 'Version';
UPDATE conflines SET value = ' by <a href=\'http://www.kolmisoft.com\' target=\"_blank\">KolmiSoft </a> 2006-2012' WHERE value = ' by <a href=\'http://www.kolmisoft.com\' target=\"_blank\">KolmiSoft </a> 2006-2008' AND name = 'Copyright_Title';
INSERT IGNORE INTO voicemail_boxes (device_id, mailbox, password, fullname, context, email, pager, dialout, callback) SELECT devices.id AS device_id, devices.extension AS mailbox, (SELECT value FROM   conflines WHERE  name = 'Default_device_voicemail_box_password' AND owner_id = users.owner_id) AS password, CONCAT(users.first_name, ' ', users.last_name) AS full_name, 'default' AS context, IF(LENGTH(addresses.email) > 0, addresses.email, (SELECT value FROM   conflines  WHERE  name = 'Default_device_voicemail_box_email' AND owner_id = users.owner_id)) AS email,'' AS pager, '' AS dialout, '' AS callback FROM devices LEFT JOIN users ON users.id = devices.user_id LEFT JOIN addresses ON users.address_id = addresses.id LEFT JOIN voicemail_boxes ON devices.id = voicemail_boxes.device_id WHERE devices.user_id != -1 AND voicemail_boxes.uniqueid IS NULL;
UPDATE devices SET insecure = NULL WHERE id = 2;
# ^^^^^^ WRITE ABOVE THIS LINE ^^^^^
# marking that DB is updated from script
INSERT INTO conflines (name, value) VALUES ('DB_Update_From_Script', 1);
