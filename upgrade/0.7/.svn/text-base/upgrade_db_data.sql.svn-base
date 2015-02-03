

#################### MOR PRO 0.7 ############################


# --------------- INSERT VALUES -----------------

INSERT INTO `emails` (name, subject, date_created, body, template) SELECT 'cyberplat_announce', 'Cyberplat payment announce', '2008-07-03 17:32:14', 0x5468616E6B20796F7520666F72207573696E67206379626572706C61742E3C6272202F3E0D0A436F6D70616E79206E616D653A203C253D20636F6D70616E795F6E616D6520253E3C6272202F3E0D0A44657369676E6174696F6E3A20566F49503C6272202F3E0D0A55524C3A203C253D2075726C20253E3C6272202F3E0D0A436F6D70616E795F456D61696C3A203C253D20656D61696C253E3C6272202F3E0D0A416D6F756E742B5641543A203C253D20616D6F756E7420253E203C253D2063757272656E637920253E3C6272202F3E0D0A5472616E73616374696F6E20646174653A203C253D206461746520253E3C6272202F3E0D0A417574686F72697A6174696F6E20436F64653A203C253D20617574685F636F646520253E3C6272202F3E0D0A5472616E73616374696F6E204964656E746966696572203C253D207472616E735F696420253E3C6272202F3E0D0A437573746F6D6572204E616D65203C253D20637573746F6D65725F6E616D6520253E3C6272202F3E0D0A4F7065726174696F6E20547970653A2042616C616E6365205570646174653C6272202F3E0D0A4465736372697074696F6E3A203C253D206465736372697074696F6E20253E, '1' FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'cyberplat_announce') = 0;

INSERT INTO conflines (name, value) SELECT 'Cyberplat_Enabled', 1 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Enabled') = 0;
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Default_Currency', 'RUB' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Default_Currency') = 0;
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Min_Amount', 3 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Min_Amount') = 0;
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Default_Amount', 10 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Default_Amount') = 0;
INSERT INTO conflines (name, value) SELECT 'Cyberplat_ShopIP', '' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_ShopIP') = 0; 
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Temporary_Directory', '/tmp' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Temporary_Directory') = 0; 
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Test', 1 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Test') = 0;
INSERT INTO conflines (name, value) SELECT 'Cyberplat_Transacton_Fee', 5 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Transacton_Fee') = 0;
INSERT INTO conflines (name, value2) SELECT 'Cyberplat_Crap', '' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Cyberplat_Crap') = 0;

INSERT INTO conflines (name, value) SELECT "Google_Fullscreen", 0 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Google_Fullscreen') = 0;
INSERT INTO conflines (name, value) SELECT "Google_ReloadTime", 10 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Google_ReloadTime') = 0;
INSERT INTO conflines (name, value) SELECT "Google_Width", 1200 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Google_Width') = 0;
INSERT INTO conflines (name, value) SELECT "Google_Height", 700 FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Google_Height') = 0;


INSERT INTO translations (name, native_name, short_name, position, flag) SELECT 'Croatian','','cr','108','hrv' FROM dual WHERE (SELECT COUNT(*) FROM translations WHERE name = 'Croatian') = 0;
INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'Use Voucher',  'use_voucher', 'mor_pbxfunctions', 'use_voucher', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'Use Voucher') = 0;
INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'Milliwatt',  'milliwatt', 'mor_pbxfunctions', 'milliwatt', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'Milliwatt') = 0;


INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_dtmfmode', 'rfc2833', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_dtmfmode') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_works_not_logged', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_works_not_logged') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_location_id', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_location_id') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_ani', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_ani') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_istrunk', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_istrunk') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_record', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_record') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_call_limit', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_call_limit') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_cid_name', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_cid_name') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_cid_number', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_cid_number') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_host', 'dynamic', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_host') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_port', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_port') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_canreinvite', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_canreinvite') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_nat', 'yes', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_nat') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_qualify', '1000', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_qualify') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_qualify_time', '2000', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_qualify_time') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_callgroup', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_callgroup') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_pickupgroup', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_pickupgroup') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_voicemail_active', null, '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_voicemail_active') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_voicemail_box', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_voicemail_box') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_voicemail_box_email', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_voicemail_box_email') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_voicemail_box_password', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_voicemail_box_password') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_fromuser', null, '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_fromuser') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_fromdomain', null, '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_fromdomain') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_trustrpid', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_trustrpid') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_sendrpid', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_sendrpid') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_t38pt_udptl', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_t38pt_udptl') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_promiscredir', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_promiscredir') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_progressinband', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_progressinband') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_videosupport', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_videosupport') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_allow_duplicate_calls', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_allow_duplicate_calls') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_tell_balance', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_tell_balance') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_tell_time', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_tell_time') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_tell_rtime_when_left', '60', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_tell_rtime_when_left') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_repeat_rtime_every', '60', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_repeat_rtime_every') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_permits', '0.0.0.0/0.0.0.0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_permits') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_type', 'SIP', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_type') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_timeout', '60', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_timeout') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_ipaddr', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_ipaddr') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_regseconds', 'no', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_regseconds') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_insecure', null, '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_insecure') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_process_sipchaninfo', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_process_sipchaninfo') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_alaw', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_alaw') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_ulaw', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_ulaw') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_g723', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_g723') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_g726', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_g726') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_g729', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_g729') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_gsm', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_gsm') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_ilbc', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_ilbc') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_lpc10', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_lpc10') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_speex', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_speex') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_adpcm', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_adpcm') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_slin', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_slin') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_h261', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_h261') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_h263', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_h263') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_h263p', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_h263p') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_h264', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_h264') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_jpeg', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_jpeg') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Default_device_codec_png', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Default_device_codec_png') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Active_Calls_Maximum_Calls', '100', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Active_Calls_Maximum_Calls') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Active_Calls_Refresh_Interval', '5', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Active_Calls_Refresh_Interval') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'CSV_Decimal', '.', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'CSV_Decimal') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Fax2Email_Folder', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Fax2Email_Folder') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'IVR_Voice_Dir', '/home/mor/public/ivr_voices/', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'IVR_Voice_Dir') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_Folder', '/usr/local/mor/backups', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_Folder') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_number', '7', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_number') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_disk_space', '10', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_disk_space') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_shedule', '0', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_shedule') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_month', 'Every_month', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_month') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_month_day', 'Every_day', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_month_day') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_week_day', 'Every_day', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_week_day') = 0;
INSERT INTO `conflines` (`name`, `value`, `owner_id`, `value2`) SELECT 'Backup_hour', '24', 0, NULL FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_hour') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Email_Pop3_server', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Email_Pop3_server') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Email_port', '25', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Email_port') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Invoice_Balance_Line', 'Your balance', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Invoice_Balance_Line') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Exception_Support_Email', 'support@kolmisoft.com', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Exception_Support_Email') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Exception_Send_Email', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Exception_Send_Email') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Show_Full_Src', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Show_Full_Src') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'CCShop_show_values_without_VAT_for_user', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'CCShop_show_values_without_VAT_for_user') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_Folder', '/usr/local/mor/backups/guidb', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_Folder') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_number', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_number') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_disk_space', '10', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_disk_space') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_shedule', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_shedule') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_month', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_month') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_month_day', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_month_day') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_week_day', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_week_day') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_hour', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_hour') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Backup_minute', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Backup_minute') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Server_to_use_for_call_center', '1', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Server_to_use_for_call_center') = 0;

INSERT INTO `conflines` (name, value, owner_id) SELECT 'Crash_log_file', '/tmp/mor_crash.log', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Crash_log_file') = 0;
INSERT INTO `conflines` (name, value, owner_id) SELECT 'Webmoney_skip_prerequest', '0', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = 'Webmoney_skip_prerequest') = 0;


INSERT INTO emails (name, template, date_created, subject, body) SELECT 'invoices', 1, NOW(),'Invoices',"Invoices are attached." FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'invoices') = 0;
INSERT INTO emails (name, template, date_created, subject, body) SELECT 'c2c_invoices', 1, NOW(),'Invoices',"Invoices are attached." FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'c2c_invoices') = 0;

INSERT INTO extlines (context, exten, priority, app, appdata, device_id) SELECT 'mor_local', '_X.', '1', 'Goto', 'mor|${EXTEN}|1', 0 FROM dual WHERE (SELECT COUNT(*) FROM extlines WHERE context = 'mor_local' AND exten = '_X.') = 0;
INSERT INTO extlines (context, exten, priority, app, appdata, device_id) SELECT 'mor_local', '_*X.', '1', 'Goto', 'mor|${EXTEN}|1', 0 FROM dual WHERE (SELECT COUNT(*) FROM extlines WHERE context = 'mor_local' AND exten = '_*X.') = 0;


INSERT INTO emails (name, template, date_created, subject, body) SELECT 'c2c_invoices', 1, NOW(),'Invoices',"Invoices are attached." FROM dual WHERE (SELECT COUNT(*) FROM emails WHERE name = 'c2c_invoices') = 0;

INSERT INTO servers (`id`, `server_ip`, `stats_url`, `server_type`, `active`, `comment`, `hostname`, `maxcalllimit`, `server_id`, `ami_port`, `ami_secret`, `ami_username`, `port`, `ssh_username`, `ssh_secret`, `ssh_port`) SELECT 1, '127.0.0.1', '', 'main', 1, 'main system', '127.0.0.1', 500, 1, '5038', 'morsecret', 'mor', 5060, 'root', '', 22 FROM dual WHERE (SELECT COUNT(*) FROM servers) = 0;


INSERT INTO directions (name, code) SELECT 'Montenegro', 'MBX' FROM dual WHERE (SELECT COUNT(*) FROM directions WHERE name = 'Montenegro') = 0;
INSERT INTO directions (name, code) SELECT 'Kosovo', 'KOS' FROM dual WHERE (SELECT COUNT(*) FROM directions WHERE name = 'Kosovo') = 0;



#INSERT INTO `conflines` (name, value, owner_id) SELECT '', '100', '0' FROM dual WHERE (SELECT COUNT(*) FROM conflines WHERE name = '') = 0;

#INSERT INTO  (name, value) SELECT '', '' FROM dual WHERE (SELECT COUNT(*) FROM   WHERE name = '') = 0;



UPDATE emails SET template = 1 WHERE name LIKE 'registration%';
UPDATE invoicedetails SET invdet_type = 0 WHERE name LIKE 'Calls%';

UPDATE pbxfunctions SET extension = 'tell_balance' WHERE pf_type = 'tell_balance';

UPDATE devices SET context = 'mor_local' WHERE context = 'mor' AND user_id > -1;
UPDATE extlines SET context = 'mor_local' WHERE device_id > 0 AND context = 'mor';
UPDATE extlines SET context = 'mor_local' WHERE exten like '*%' AND context = 'mor';

UPDATE conflines SET value = '/home/mor/public/ad_sounds' WHERE name ='AD_Sounds_Folder';


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

# upgrade vm dial plan

DELETE FROM extlines WHERE context = 'mor_voicemail' AND exten = '_X.';
INSERT INTO `extlines` (`context`, `exten`, `priority`, `app`, `appdata`, `device_id`) VALUES
    ('mor_voicemail', '_X.', 1, 'VoiceMail', '${EXTEN}|${MOR_VM}', 0),
    ('mor_voicemail', '_X.', 2, 'Hangup', '', 0);


# simple hangup, no congestion to return correct error code
DELETE FROM extlines WHERE context = 'mor' AND exten = 'HANGUP';
INSERT INTO `extlines` (`context`, `exten`, `priority`, `app`, `appdata`, `device_id`) VALUES ('mor', 'HANGUP', 1, 'Hangup', '', 0);


INSERT INTO `extlines` (`context`, `exten`, `priority`, `app`, `appdata`, `device_id`) SELECT 'mor', 'HANGUP_NOW', 1, 'Hangup', '', '0' FROM dual WHERE (SELECT COUNT(*) FROM extlines WHERE exten = 'HANGUP_NOW
') = 0;


INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'Dial Local',  'dial_local', 'mor_pbxfunctions', 'dial_local', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'Dial Local') = 0;
INSERT INTO pbxfunctions (name, pf_type, context, extension, priority) SELECT 'DTMF Test',  'dtmf_test', 'mor_pbxfunctions', 'dtmf_test', 1 FROM dual WHERE (SELECT COUNT(*) FROM pbxfunctions WHERE name = 'DTMF Test') = 0;

UPDATE conflines SET value = "" WHERE name = 'PayPal_Email' AND value = 'sales@kolmisoft.com';

# ----------------- DELETE VALUES --------------------

DELETE FROM sessions;
#DELETE FROM conflines WHERE name = 'AMI_Host';
#DELETE FROM conflines WHERE name = 'AMI_Username';
#DELETE FROM conflines WHERE name = 'AMI_Secret';