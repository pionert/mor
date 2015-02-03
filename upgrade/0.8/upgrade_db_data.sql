

#################### MOR 0.8 ############################


# --------------- INSERT VALUES -----------------

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_1', 'VAT', '1' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_1') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_2', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_2') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_3', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_3') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_4', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_4') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Total_tax_name', 'Tax', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Total_tax_name') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Banned_CLIs_default_IVR_id', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Banned_CLIs_default_IVR_id') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_1_Value', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_1_Value') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_2_Value', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_2_Value') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_3_Value', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_3_Value') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Tax_4_Value', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Tax_4_Value') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Total_Tax_Value', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Total_Tax_Value') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Show_logo_on_register_page', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Show_logo_on_register_page') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Email_Callback_Pop3_Server', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Email_Callback_Pop3_Server') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Email_Callback_Login', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Email_Callback_Login') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Email_Callback_Password', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Email_Callback_Password') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Web_Callback_Server', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Web_Callback_Server') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Show_logo_on_register_page', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Show_logo_on_register_page') = 0;

INSERT INTO emails (name, template, date_created, subject, body) SELECT 'calling_cards_data_to_paypal', 1, NOW(), 'Calling Card purchase', 0x203C7461626C653E0D0A093C74723E0D0A09202020203C74683E3C253D205F28274E756D6265722729253E3C2F74683E0D0A09202020203C74683E3C253D205F282750494E272920253E3C2F74683E0D0A09202020203C74683E3C253D205F28275072696365272920253E3C2F74683E0D0A093C2F74723E0D0A202020203C252069203D203020253E0D0A202020203C2520666F72206361726420696E20636172647320253E0D0A093C7472203E2020200D0A09202020203C746420616C69676E3D2763656E746572273E0D0A0909203C253D20636172642E6E756D626572253E0D0A09202020203C2F74643E0D0A09202020203C746420616C69676E3D2763656E746572273E0D0A202020200909203C253D20636172642E70696E20253E200D0A09202020203C2F74643E0D0A09202020203C746420616C69676E3D2763656E746572273E0D0A202020200909203C253D20636172642E6361726467726F75702E707269636520253E200D0A09202020203C2F74643E0D0A093C2F74723E0D0A093C252069202B3D2031253E0D0A202020203C25656E64253E0D0A20202020203C2F7461626C653E  FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'calling_cards_data_to_paypal') = 0;

INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'Dial Local',  'dial_local', 'mor_pbxfunctions', 'dial_local', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'Dial Local') = 0;

INSERT INTO emails (name, template, date_created, subject, body) SELECT 'warning_balance_email', 1, NOW(),'Warning',"Balance: <%=balance %>"  FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'warning_balance_email') = 0;


# upgrade main dial plan

DELETE FROM extlines WHERE context = 'mor' AND exten = '_X.';
INSERT INTO `extlines` (`context`, `exten`, `priority`, `app`, `appdata`, `device_id`) VALUES
    ('mor', '_X.', 1, 'NoOp', 'MOR starts', 0),
    ('mor', '_X.', 2, 'Set', 'TIMEOUT(response)=20', 0),
    ('mor', '_X.', 3, 'Set', 'TIMEOUT(digit)=10', 0),
    ('mor', '_X.', 4, 'mor', '${EXTEN}', 0),
    ('mor', '_X.', 5, 'GotoIf', '$["${MOR_CARD_USED}" != ""]?mor_callingcard|s|1', 0),
    ('mor', '_X.', 6, 'GotoIf', '$["${MOR_TRUNK}" = "1"]?HANGUP_NOW|1', 0),
    ('mor', '_X.', 7, 'GotoIf', '$[$["${DIALSTATUS}" = "CHANUNAVAIL"] | $["${DIALSTATUS}" = "CONGESTION"]]?FAILED|1', 0),
    ('mor', '_X.', 8, 'GotoIf', '$["${DIALSTATUS}" = "BUSY"]?BUSY|1:HANGUP|1', 0)
;

INSERT INTO `extlines` (`context`, `exten`, `priority`, `app`, `appdata`, `device_id`) SELECT 'mor', 'HANGUP_NOW', 1, 'Hangup', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM extlines WHERE exten = 'HANGUP_NOW') = 0;
			
UPDATE invoices LEFT JOIN users ON (invoices.user_id = users.id) SET invoices.invoice_type = CASE WHEN users.postpaid = 1 THEN 'postpaid' ELSE 'prepaid' END;
UPDATE c2c_invoices LEFT JOIN users ON (c2c_invoices.user_id = users.id) SET c2c_invoices.invoice_type = CASE WHEN users.postpaid = 1 THEN 'postpaid' ELSE 'prepaid' END;


DELETE FROM acc_rights;

INSERT INTO `acc_rights`(`id`,`name`, `nice_name`, `permission_group`) VALUES 
('1', 'user_create_opt_1', 'User_Password', 'User'),
('2', 'user_create_opt_2', 'User_Type', 'User'),
('3', 'user_create_opt_3', 'User_Lrc', 'User'),
('4', 'user_create_opt_4', 'User_Tariff', 'User'),
('5', 'user_create_opt_5', 'User_Balance', 'User'),
('6', 'user_create_opt_6', 'User_Payment_type', 'User'),
('7', 'user_create_opt_7', 'User_Call_limit', 'User'),
('8', 'device_edit_opt_1', 'Device_Extension', 'Device'),
('9', 'device_edit_opt_2', 'Device_Autentication', 'Device'),
('10', 'device_edit_opt_3', 'Decive_CallerID_Name', 'Device'),
('11', 'device_edit_opt_4', 'Device_CallerID_Number', 'Device'),
('12', 'Device_PIN', 'Device_PIN', 'Device'),
('13', 'Callingcard_PIN', 'Callingcard_PIN', 'Callingcard'),
('14', 'Device_Password', 'Device_Password', 'Device'),
('15', 'VoiceMail_Password', 'VoiceMail_Password', 'Device'),
('16', 'User_create', 'User_create', 'User'),
('17', 'Device_create', 'Device_create', 'Device'),
('18', 'Callingcard_manage', 'Callingcard_manage', 'Callingcard'),
('19', 'Tariff_manage', 'Tariff_manage', 'Tariff'),
('20', 'manage_dids_opt_1', 'Manage_DID', 'DID'),
('21', 'manage_subscriptions_opt_1', 'Manage_subscriptions', 'Subscription');


UPDATE conflines SET value = "" WHERE name = 'PayPal_Email' AND value = 'sales@kolmisoft.com';

UPDATE devices SET name = CONCAT("prov", devices.id) WHERE user_id = -1;
UPDATE devices SET port = 1720 WHERE user_id = -1 and device_type = 'H323';

#UPDATE recordings SET forced = 1, enabled = 1 WHERE enabled = 0 AND forced = 0;

# ----------------- DELETE VALUES --------------------
