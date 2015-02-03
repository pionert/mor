# DB CLEANING
#
# Comments:
# Currently optimized for X4 resellers (NOT RS PRO!!!)
# LEFT entities
# number pools, numbers
# all ivrs, mohs, queues, ringgroups (deleted devices removed from queueagents and ringgroup_devices)
# DELETED entities
# vouchers
# all lcrs, one with id=1 is created as dummy
# all providers, created dummy 1
# all servers, created 1 dummy, fixed device/provider connections
# blacklisting info
#
# USERS CLEAN
# delete all users except admin, reseller and his users (why we are leaving admin here? just in case...)
DELETE FROM users WHERE id NOT IN (0, 5) AND owner_id != 5;
#
# DEVICES CLEAN
# delete resellers' devices
DELETE FROM devices WHERE user_id IN(0,  5); 
# delete all devices without users, (inc. providers devices), leave resellers user devices 
DELETE FROM devices WHERE user_id NOT IN (SELECT id FROM users) ;
#
# CALLS CLEAN
# disable indexes on calls table with small hope it will increase DELETE
ALTER TABLE calls DISABLE KEYS;
# delete Calls not associated with our Reseller. This can take a long long time....... Please wait and be patient..... 
DELETE FROM calls WHERE src_device_id NOT IN (SELECT id FROM devices) AND dst_device_id NOT IN (SELECT id FROM devices); 
#
# enabling indexes back again
ALTER TABLE calls ENABLE KEYS;
# Call cleaning completed!
#
DELETE FROM call_details WHERE id NOT IN (SELECT id FROM calls);
#
# CALLS_OLD CLEAN
# disable indexes on calls table with small hope it will increase DELETE
ALTER TABLE calls_old DISABLE KEYS;
# delete Calls not associated with our Reseller
DELETE FROM calls_old WHERE src_device_id NOT IN (SELECT id FROM devices) AND dst_device_id NOT IN (SELECT id FROM devices); 
# enabling indexes back again
ALTER TABLE calls_old ENABLE KEYS;
# Old Call cleaning completed
# these should be fast, usually not so much data in these tables
DELETE FROM call_details WHERE id NOT IN (SELECT id FROM calls);
DELETE FROM call_logs WHERE uniqueid NOT IN (SELECT uniqueid FROM calls);
#
# ACCOUNTANT PERMISSIONS CLEAN
# info.sh complains: FAILED Upgrade to MOR 11 was not made and reseller permissions are now missing. Do upgrade to MOR 11 to fix this. Run info.sh again to test after all.
#DELETE FROM acc_groups WHERE group_type = 'reseller' AND id NOT IN (SELECT acc_group_id FROM users);
#DELETE FROM acc_group_rights WHERE acc_group_id NOT IN (SELECT id FROM acc_groups);
#DELETE FROM acc_permissions  WHERE acc_group_id NOT IN (SELECT id FROM acc_groups);
#DELETE FROM acc_rights WHERE id NOT IN (SELECT acc_group_id FROM acc_group_rights);
#
TRUNCATE actions;
TRUNCATE activecalls;
TRUNCATE active_calls_data;
#
DELETE FROM addresses WHERE id NOT IN (SELECT address_id FROM users);
#
DELETE FROM aggregates WHERE user_id != 5 AND reseller_id != 5;
#
# ALERTS CLEAN 
# delete everything because resellers cannot have their own alerts
DELETE FROM alerts WHERE owner_id != 5; # for the future, usually deletes everything now
TRUNCATE alert_contacts;
TRUNCATE alert_contact_groups;
TRUNCATE alert_groups;
TRUNCATE alert_schedules;
TRUNCATE alert_schedule_periods;
UPDATE alerts SET owner_id = 0;
#
TRUNCATE background_tasks;
TRUNCATE backups;
TRUNCATE blanks;
#
# BLACKLISTING CLEAN 
# only admin can use, so reseller can't have any data, empty all
TRUNCATE bl_dst_new_score;
TRUNCATE bl_dst_scoring;
TRUNCATE bl_ip_new_score;
TRUNCATE bl_ip_scoring;
TRUNCATE bl_src_new_score;
TRUNCATE bl_src_scoring;
#
DELETE FROM callerids WHERE device_id NOT IN (SELECT id FROM devices);
#
DELETE FROM callflows WHERE device_id NOT IN (SELECT id FROM devices);
#
# CARDS CLEAN
DELETE FROM cardgroups WHERE owner_id != 5;
DELETE FROM cards WHERE owner_id != 5 AND user_id NOT IN (SELECT id FROM users);
DELETE FROM cclineitems WHERE card_id NOT IN (SELECT id FROM cards);
DELETE FROM ccorders WHERE id NOT IN (SELECT ccorder_id FROM cclineitems);
DELETE FROM cc_gmps WHERE cardgroup_id NOT IN (SELECT id FROM cardgroups);
UPDATE cardgroups SET owner_id = 0;
UPDATE cards SET owner_id = 0;
# delete cc payments
DELETE FROM payments WHERE id IN (SELECT payment_id FROM cc_invoices WHERE ccorder_id NOT IN (SELECT id FROM ccorders));
DELETE FROM cc_invoices WHERE ccorder_id NOT IN (SELECT id FROM ccorders);
UPDATE cc_invoices SET owner_id = 0; # not quite sure about this one
#
TRUNCATE cdr; # not sure if this table is used at all
#
DELETE FROM conflines WHERE owner_id NOT IN (0, 5);
#
DELETE FROM credit_notes WHERE user_id NOT IN (SELECT id FROM users);
#
TRUNCATE cron_actions;
TRUNCATE cron_settings;
#
DELETE FROM cs_invoices WHERE user_id NOT IN (SELECT id FROM users);
#
DELETE FROM devicecodecs WHERE device_id NOT IN (SELECT id FROM devices);
DELETE FROM devicegroups WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM devicerules WHERE device_id NOT IN (SELECT id FROM devices);
DELETE FROM devicerules WHERE device_id NOT IN (SELECT id FROM devices);
#
DELETE FROM dialplans WHERE user_id NOT IN (SELECT id FROM users);
#
# device_id=0 means it is global system extline
DELETE FROM extlines WHERE device_id NOT IN (SELECT id FROM devices) AND device_id > 0;
#
TRUNCATE gateways; # what is this?
#
DELETE FROM groups WHERE owner_id != 5;
DELETE FROM usergroups WHERE user_id NOT IN (SELECT id FROM users) OR group_id NOT IN (SELECT id FROM groups);
#
DELETE FROM pdffaxemails WHERE device_id NOT IN (SELECT id FROM devices);
DELETE FROM pdffaxes WHERE device_id NOT IN (SELECT id FROM devices);
#
DELETE FROM phonebooks WHERE user_id NOT IN (SELECT id FROM users) AND card_id NOT IN (SELECT id FROM cards);
#
DELETE FROM recordings WHERE call_id NOT IN (SELECT id FROM calls);
#
DELETE FROM services WHERE owner_id != 5;
DELETE FROM subscriptions WHERE user_id NOT IN (SELECT id FROM users);
#
# SMS
DELETE FROM sms_campaigns WHERE owner_id NOT IN (SELECT id FROM users);
DELETE FROM sms_adactions WHERE sms_campaign_id NOT IN (SELECT id FROM sms_campaigns);
DELETE FROM sms_adnumbers WHERE sms_campaign_id NOT IN (SELECT id FROM sms_campaigns);
DELETE FROM sms_tariffs WHERE owner_id NOT IN (SELECT id FROM users);
DELETE FROM sms_rates WHERE sms_tariff_id NOT IN (SELECT id FROM sms_tariffs);
DELETE FROM sms_providers WHERE sms_tariff_id NOT IN (SELECT id FROM sms_tariffs);
DELETE FROM sms_messages WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM sms_lcrproviders WHERE sms_provider_id NOT IN (SELECT id FROM sms_providers);
DELETE FROM sms_lcrs WHERE id NOT IN (SELECT sms_lcr_id FROM users);
UPDATE sms_messages SET reseller_id = 0;
#
DELETE FROM taxes WHERE id NOT IN (SELECT tax_id FROM users);
#
DELETE FROM user_translations WHERE user_id NOT IN (SELECT id FROM users);
#
DELETE FROM voicemail_boxes WHERE device_id NOT IN (SELECT id FROM devices);
#
TRUNCATE vouchers;
#
DELETE FROM queue_agents WHERE device_id NOT IN (SELECT id FROM devices);
DELETE FROM ringgroups_devices WHERE device_id NOT IN (SELECT id FROM devices);
#
DELETE FROM invoices WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM invoicedetails WHERE invoice_id NOT IN (SELECT id FROM invoices);
#
DELETE FROM flatrate_data WHERE subscription_id NOT IN (SELECT id FROM subscriptions);
DELETE FROM flatrate_destinations WHERE service_id NOT IN (SELECT id FROM services);
#
TRUNCATE server_loadstats;
#
DELETE FROM user_translations WHERE user_id NOT IN (SELECT id FROM users);
#
#
# DATA FIXING
#
# LCR
# delete all lcr, create dummy one, fill relation with dummy provider
TRUNCATE lcrproviders;
TRUNCATE  lcr_partials;
TRUNCATE  lcr_timeperiods;
DELETE FROM lcrs; # truncate spits foreign key error
INSERT INTO lcrs (id , name , `order` , user_id ) VALUES ('1', 'PRIMARY_LCR', 'price', '0'); 
ALTER TABLE lcrs AUTO_INCREMENT = 1;
INSERT INTO lcrproviders (`id` ,`lcr_id` ,`provider_id` ,`active` ,`priority` ,`percent` )VALUES ('1', '1', '1', '1', '1', '0');
#
# Servers
# leave 1 dummy server, fix connections accordingly
TRUNCATE servers;
ALTER TABLE servers AUTO_INCREMENT = 1;
INSERT INTO servers (`id` ,`server_ip` ,`stats_url` ,`server_type` ,`active` ,`comment` ,`hostname` ,`maxcalllimit` ,`server_id` ,`ami_port` ,`ami_secret` ,`ami_username` ,`port` ,`ssh_username` ,`ssh_secret` ,`ssh_port` ,`gateway_active` ,`version` ,`uptime` ,`gui` ,`db` ,`core` ,`load_ok` ) VALUES ('1', '127.0.0.1', NULL , 'asterisk', '0', 'PRIMARY', '127.0.0.1', '1000', '1', '5038', 'morsecret', 'mor', '5060', 'root', NULL , '22', '0', NULL , NULL , '1', '1', '1', '1');
#
# new server device
INSERT INTO devices (name, host, context, ipaddr, port, accountcode, extension, username, device_type, user_id, disallow, allow, dtmfmode, fromuser, trustrpid, sendrpid, insecure, location_id, server_id, transport, proxy_port, defaultuser, type) VALUES ('mor_server_1', '127.0.0.1', 'mor_direct', '127.0.0.1', '5060', 1, 'mor_server_1', 'mor_server_1', 'SIP', 0, 'all', 'alaw;g729', 'rfc2833', 'mor_server_1', 'no', 'no', 'no', 1, 1, 'udp', '5060', 'mor_server_1', 'friend');
#
DELETE FROM server_devices WHERE device_id NOT IN (SELECT id FROM devices);
UPDATE server_devices SET server_id = 1;
#
TRUNCATE serverproviders;
ALTER TABLE serverproviders AUTO_INCREMENT = 1;
INSERT INTO serverproviders (`id` ,`server_id` ,`provider_id` )VALUES ('1', '1', '1');
#
# Providers
DELETE FROM providers; # truncate spits foreign key error
ALTER TABLE lcrs AUTO_INCREMENT = 1;
INSERT INTO providers (id , name , tech, server_ip, port ) VALUES ('1', 'PRIMARY_PROVIDER', 'SIP', '8.8.8.8', '5060'); 
UPDATE providers SET tariff_id = (SELECT id FROM `tariffs` WHERE purpose = 'provider' LIMIT 1)WHERE id = 1;
#
# providers device
INSERT INTO devices (name, host, context, ipaddr, port, accountcode, extension, username, device_type, user_id, disallow, allow, dtmfmode, fromuser, trustrpid, sendrpid, insecure, location_id, server_id, transport, proxy_port, defaultuser, type) VALUES ('prov1', '8.8.8.8', 'mor', '8.8.8.8', '5060', 1, 'f89dksmn45na0d', '', 'SIP', '-1', 'all', 'alaw;g729', 'rfc2833', '', 'yes', 'no', 'port,invite', 1, 1, 'udp', '5060', '', 'friend');
UPDATE providers SET device_id = (SELECT id FROM devices WHERE name = "prov1") WHERE id = 1;
#
DELETE FROM providercodecs WHERE provider_id != 1;
TRUNCATE providerrules;
TRUNCATE common_use_providers;
TRUNCATE terminators;
#
# DIDS
DELETE FROM dids WHERE reseller_id != 5;
UPDATE dids SET provider_id = 1, reseller_id = 0;
DELETE FROM didrates WHERE did_id NOT IN (SELECT id FROM dids);
DELETE FROM quickforwarddids WHERE user_id NOT IN (SELECT id FROM users) OR did_id NOT IN (SELECT id FROM dids);
DELETE FROM quickforwards_rules WHERE user_id NOT IN (SELECT id FROM users);
#
# localization
# remove other users locations, leave Global (id 0)
DELETE FROM locations WHERE user_id NOT IN (SELECT id FROM users) AND user_id > 0;
# delete also where device is not present
DELETE FROM locationrules WHERE location_id NOT IN (SELECT id FROM locations) OR device_id NOT IN (SELECT id FROM devices);
UPDATE locationrules SET lcr_id = 1 WHERE lcr_id > 0;
UPDATE locationrules SET did_id = NULL WHERE did_id NOT IN (SELECT id FROM dids);
UPDATE locations SET user_id = 0;
#
# AutoDialer
DELETE FROM campaigns  WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM adnumbers WHERE campaign_id NOT IN (SELECT id FROM campaigns);
DELETE FROM adactions WHERE campaign_id NOT IN (SELECT id FROM campaigns);
UPDATE campaigns SET owner_id = 0;
#
# Emails
# delete everything except admin and rs, then merge them with rs priority (remove duplicates)
DELETE FROM emails WHERE owner_id NOT IN (0, 5);
DELETE FROM emails USING emails, emails as vtable WHERE (emails.id < vtable.id) AND (emails.name = vtable.name);
UPDATE emails SET owner_id = 0;
#
# Conflines
# delete everything except admin and rs, then merge them with rs priority (remove duplicates)
DELETE FROM conflines WHERE owner_id NOT IN (0, 5);
DELETE FROM conflines USING conflines, conflines as vtable WHERE (conflines.id < vtable.id) AND (conflines.name = vtable.name);
UPDATE conflines SET owner_id = 0;
#
# Payments
DELETE FROM payments WHERE user_id NOT IN (SELECT id FROM users) AND owner_id != 5;
UPDATE payments SET user_id = 0 WHERE user_id = 5;
#
# Services
DELETE FROM services WHERE owner_id != 5;
UPDATE services SET owner_id = 0;
#
# Tariffs
DELETE FROM tariffs WHERE owner_id != 5;
DELETE FROM rates WHERE tariff_id NOT IN (SELECT id FROM tariffs);
DELETE FROM ratedetails WHERE rate_id NOT IN (SELECT id FROM rates);
DELETE FROM aratedetails WHERE rate_id NOT IN (SELECT id FROM rates);
DELETE FROM customrates WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM acustratedetails WHERE customrate_id NOT IN (SELECT id FROM customrates);
UPDATE tariffs SET owner_id = 0;
#
# dummy tariff for dummy Provider
INSERT INTO tariffs (`name` ,`purpose` ,`owner_id` ,`currency` )VALUES ('PROVIDER_TARIFF', 'provider', '0', 'USD');
UPDATE providers SET tariff_id = (SELECT id FROM tariffs WHERE name = 'PROVIDER_TARIFF' LIMIT 1);
#
# fix tariffs for DIDs
UPDATE dids SET owner_tariff_id = 0 WHERE owner_tariff_id NOT IN (SELECT id FROM tariffs);
UPDATE dids SET cc_tariff_id = 0 WHERE cc_tariff_id NOT IN (SELECT id FROM tariffs);
#
# Users
UPDATE users SET owner_id = 0 WHERE owner_id = 5;
DELETE FROM users WHERE id = 0;
UPDATE users SET id = 0 WHERE id = 5;
UPDATE users SET usertype = "admin", tariff_id = 0 WHERE id = 0;
#
# Calls
#
# disable indexes on calls table with small hope it will increase operations speed
ALTER TABLE calls DISABLE KEYS;
#
# change calls owners and call rates, prices, billsec
UPDATE calls SET provider_id = 1, server_id = 1, reseller_id = 0, provider_rate = reseller_rate, provider_billsec = reseller_billsec, provider_price = reseller_price, reseller_rate = 0, reseller_billsec = 0, reseller_price = 0;
#
# hide loose ends
UPDATE calls SET did_id = 0 WHERE did_id NOT IN (SELECT id FROM dids);
UPDATE calls SET user_id = 0 WHERE user_id NOT IN (SELECT id FROM users);
UPDATE calls SET dst_user_id = 0 WHERE dst_user_id NOT IN (SELECT id FROM users);
UPDATE calls SET src_device_id = 0 WHERE src_device_id NOT IN (SELECT id FROM devices);
UPDATE calls SET dst_device_id = NULL WHERE dst_device_id NOT IN (SELECT id FROM devices);
#
# enabling indexes back again
ALTER TABLE calls ENABLE KEYS;
#
# Old Calls
#
# disable indexes on calls table with small hope it will increase operations speed
ALTER TABLE calls_old  DISABLE KEYS;
#
# change calls owners and details (takes a lot of time...)
UPDATE calls_old SET provider_id = 1, server_id = 1, reseller_id = 0, provider_rate = reseller_rate, provider_billsec = reseller_billsec, provider_price = reseller_price, reseller_rate = 0, reseller_billsec = 0, reseller_price = 0;
#
# hide loose ends
UPDATE calls_old SET did_id = 0 WHERE did_id NOT IN (SELECT id FROM dids);
UPDATE calls_old SET user_id = 0 WHERE user_id NOT IN (SELECT id FROM users);
UPDATE calls_old SET dst_user_id = 0 WHERE dst_user_id NOT IN (SELECT id FROM users);
UPDATE calls_old SET src_device_id = 0 WHERE src_device_id NOT IN (SELECT id FROM devices);
UPDATE calls_old SET dst_device_id = NULL WHERE dst_device_id NOT IN (SELECT id FROM devices);
#
# enabling indexes back again
ALTER TABLE calls_old ENABLE KEYS;
#
# ALL TASKS FINISHED!
