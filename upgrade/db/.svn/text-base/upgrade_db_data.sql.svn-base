
USE mor;

#################### MOR PRO 0.6 ############################


# --------------- INSERT VALUES -----------------

INSERT INTO conflines (name, value) SELECT 'Reg_allow_user_enter_vat', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Reg_allow_user_enter_vat') = 0;
INSERT INTO conflines (name, value) SELECT 'CSV_Separator', ',' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'CSV_Separator') = 0;
INSERT INTO conflines (name, value) SELECT 'CSV_Decimal', '.' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'CSV_Decimal') = 0;
INSERT INTO conflines (name, value) SELECT 'Active_Calls_Refresh_Interval', '5' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Active_Calls_Refresh_Interval') = 0;
INSERT INTO conflines (name, value) SELECT 'WEB_Callback_CID', '' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WEB_Callback_CID') = 0;
INSERT INTO conflines (name, value) SELECT 'VM_Server_Active', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'VM_Server_Active') = 0;
INSERT INTO conflines (name, value) SELECT 'VM_Server_Device_ID', '' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'VM_Server_Device_ID') = 0;
INSERT INTO conflines (name, value) SELECT 'VM_Server_Retrieve_Extension', '*97' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'VM_Server_Retrieve_Extension') = 0;
INSERT INTO conflines (name, value) SELECT 'VM_Retrieve_Extension', '*97' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'VM_Retrieve_Extension') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Enabled", "1" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Enabled') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Default_Currency", "USD" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Default_Currency') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Min_Amount", "5" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Min_Amount') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Default_Amount", "10" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Default_Amount') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Test", "1" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Test') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_Purse", "Z616776332783" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_Purse') = 0;
INSERT INTO conflines (name, value) SELECT "WebMoney_SIM_MODE", "0" FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'WebMoney_SIM_MODE') = 0;
INSERT INTO conflines (name, value) SELECT 'Temp_Dir', '/tmp/' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Temp_Dir') = 0;
INSERT INTO conflines (name, value) SELECT 'Greetings_Folder', '/home/mor/public/c2c_greetings' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Greetings_Folder') = 0;
INSERT INTO conflines (name, value) SELECT 'Device_Range_MIN', '104' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Device_Range_MIN') = 0;
INSERT INTO conflines (name, value) SELECT 'Device_Range_MAX', '9999' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Device_Range_MAX') = 0;
INSERT INTO conflines (name, value) SELECT 'AD_Sounds_Folder', '/home/mor/public/ad_sounds' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'AD_Sounds_Folder') = 0;

INSERT INTO conflines (name, value) SELECT 'AMI_Host', '127.0.0.1' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'AMI_Host') = 0;
INSERT INTO conflines (name, value) SELECT 'AMI_Username', 'mor' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'AMI_Username') = 0;
INSERT INTO conflines (name, value) SELECT 'AMI_Secret', 'morsecret' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'AMI_Secret') = 0;


INSERT INTO translations (name, native_name, short_name, position, flag) SELECT 'Australian English','','au','102','aus' FROM dual WHERE (SELECT COUNT(*) FROM translations WHERE name = 'Australian English') = 0;
INSERT INTO translations (name, native_name, short_name, position, flag) SELECT 'Belarussian','','by','103','blr' FROM dual WHERE (SELECT COUNT(*) FROM translations WHERE name = 'Belarussian') = 0;
INSERT INTO translations (name, native_name, short_name, position, flag) SELECT 'Chinese','','zn','107','chn' FROM dual WHERE (SELECT COUNT(*) FROM translations WHERE name = 'Chinese') = 0;
INSERT INTO translations (name, native_name, short_name, position, flag) SELECT 'Urdu','','ur','108','pak' FROM dual WHERE (SELECT COUNT(*) FROM translations WHERE name = 'Urdu') = 0;

INSERT INTO codecs (name, long_name, codec_type) SELECT 'h264', 'H.264 Video', 'video' FROM dual WHERE (SELECT COUNT(*) FROM codecs  WHERE name = 'h264') = 0;

INSERT INTO dialplans (name, dptype) SELECT 'Quick Forward DIDs DP', 'quickforwarddids' FROM dual WHERE (SELECT COUNT(*) FROM dialplans WHERE name = 'Quick Forward DIDs DP') = 0;

INSERT INTO devicetypes (name, ast_name) SELECT 'Virtual', 'Virtual' FROM dual WHERE (SELECT COUNT(*) FROM devicetypes WHERE name = 'Virtual') = 0;

INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'Tell balance',  'tell_balance', 'mor_pbxfunctions', 'tell_balance', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'Tell balance') = 0;



#INSERT INTO  (name, value) SELECT '', '' FROM dual WHERE (SELECT COUNT(*) FROM   WHERE name = '') = 0;



UPDATE emails SET template = 1 WHERE name LIKE 'registration%';
UPDATE invoicedetails SET invdet_type = 0 WHERE name LIKE 'Calls%';

UPDATE calls SET card_id = 0 WHERE card_id IS NULL;
