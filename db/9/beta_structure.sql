CREATE TABLE IF NOT EXISTS `cc_gmps` ( `id` int(11) NOT NULL auto_increment, `cardgroup_id` int(11) NOT NULL, `prefix` varchar(255) NOT NULL, `percent` int(11) NOT NULL default '100',  PRIMARY KEY  (`id`)  ) ENGINE=InnoDB DEFAULT CHARSET=utf8; 
ALTER TABLE devices ADD fake_ring TINYINT default 0 COMMENT 'Fake ring for this device?';
ALTER TABLE cardgroups ADD COLUMN `ghost_balance_perc` int default 100;
ALTER TABLE adnumbers ADD INDEX number_index(number);
ALTER TABLE adnumbers ADD INDEX campaign_id_index(campaign_id);
CREATE TABLE IF NOT EXISTS `call_logs` (`id` bigint(20) NOT NULL auto_increment, `uniqueid` varchar(20) NOT NULL,`log` blob, PRIMARY KEY  (`id`),  KEY `uniqueid_index` (`uniqueid`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE devices ADD save_call_log TINYINT default 0 COMMENT 'Save call log';
ALTER TABLE invoices ADD COLUMN comment BLOB COMMENT 'Comment on invoice';
ALTER TABLE sms_providers ADD sms_from varchar(255) default '' COMMENT 'SMS source address, sender ID';
ALTER TABLE cardgroups MODIFY ghost_balance_perc  DOUBLE NOT NULL DEFAULT 100;
ALTER TABLE devices ADD mailbox VARCHAR(255) default "";
ALTER TABLE users ADD hide_destination_end TINYINT default -1;
ALTER TABLE devices ADD server_id INT NOT NULL default 1 COMMENT 'points to servers.server_id';
ALTER TABLE acc_groups ADD COLUMN only_view TINYINT(1)  NOT NULL DEFAULT 0 COMMENT 'accountants can only view data';
ALTER TABLE users ADD warning_email_hour INT default -1 COMMENT 'warning balance email sending at hour';
ALTER TABLE providers ADD hidden INT default 0 COMMENT 'Provider hidden status';
ALTER TABLE providers ADD use_p_asserted_identity INT default 0 COMMENT 'P-Asserted-Identity usage, rfc3325';
ALTER TABLE devices ADD enable_mwi INT default 0 COMMENT 'MWI enable for device';
ALTER TABLE users ADD warning_balance_call INT default 0 COMMENT 'should system play warning balance on every call?';
ALTER TABLE users ADD warning_balance_sound_file_id INT default 0 COMMENT 'which file to play when balance drops lower then set value';
ALTER TABLE dids ADD sound_file_id INT default 0 COMMENT 'which file to play when did is reached';
ALTER TABLE ivr_voices ADD readonly INT default 0 COMMENT 'default languages-voices cannot be deleted';
CREATE TABLE IF NOT EXISTS monitorings ( `id` int(11) NOT NULL AUTO_INCREMENT, `active` tinyint(4) NOT NULL DEFAULT '1', `user_id` int(11) NOT NULL, `period_in_past` bigint(20) DEFAULT NULL COMMENT 'in minutes', `mtype` int(11) NOT NULL DEFAULT '0', `action` int(11) NOT NULL DEFAULT '0', `amount` double NOT NULL DEFAULT '0', PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE ivr_sound_files ADD readonly INT default 0 COMMENT 'default sound-files cannot be deleted';
ALTER TABLE activecalls ADD card_id INT default 0 COMMENT 'card which is making this call';
ALTER TABLE dialplans ADD sound_file_id INT default 0 COMMENT 'which file to play when dialplan is reached';
ALTER TABLE devicecodecs ADD priority INT default 0 COMMENT 'codec priority for device';
ALTER TABLE providercodecs ADD priority INT default 0 COMMENT 'codec priority for provider';
ALTER TABLE devices ADD authuser VARCHAR(100) default "";
ALTER TABLE devices ADD requirecalltoken VARCHAR(10) default "no";
CREATE TABLE IF NOT EXISTS monitorings_users( `monitoring_id` int(11) NOT NULL, `user_id` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE monitorings_users ADD UNIQUE INDEX monitoring_user (monitoring_id, user_id);
ALTER TABLE monitorings MODIFY COLUMN active tinyint(1) DEFAULT 1;
ALTER TABLE monitorings DROP COLUMN action;
ALTER TABLE monitorings DROP COLUMN user_id;
ALTER TABLE monitorings ADD COLUMN block tinyint(1) NOT NULL default 0;
ALTER TABLE monitorings ADD COLUMN email tinyint(1) NOT NULL default 0;
ALTER TABLE monitorings MODIFY COLUMN period_in_past bigint(2) NOT NULL default 30;
ALTER TABLE dids ALTER language SET DEFAULT "";
CREATE INDEX did_index ON dids(did);
CREATE INDEX did_index ON didrates(did_id);
ALTER TABLE cardgroups ADD COLUMN `use_external_function` int default 0;
ALTER TABLE `groups` ADD COLUMN owner_id INT(11) NOT NULL DEFAULT 0;
ALTER TABLE `groups` ADD COLUMN description TEXT NULL;
ALTER TABLE `usergroups` ADD COLUMN position INT(11) NOT NULL DEFAULT 0;
ALTER TABLE `activecalls` ADD COLUMN user_rate double DEFAULT NULL;
CREATE TABLE IF NOT EXISTS `cs_invoices` (  `id` int(11) NOT NULL AUTO_INCREMENT, `callshop_id` int(11) NOT NULL, `user_id` int(11) NOT NULL,  `state` VARCHAR(15) NOT NULL DEFAULT 'unpaid',          `invoice_type` varchar(10),            `balance` double NOT NULL DEFAULT 0,              `comment` blob COMMENT 'Comment on invoice', `paid_at` TIMESTAMP NULL, `updated_at` TIMESTAMP NOT NULL, `created_at` TIMESTAMP NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE monitorings ADD COLUMN user_type VARCHAR(20);
ALTER TABLE groups ADD COLUMN `translation_id` INT(11) DEFAULT 1;
ALTER TABLE dids ADD COLUMN `grace_time` INT(11) DEFAULT 0;
ALTER TABLE cardgroups ADD COLUMN `allow_loss_calls` tinyint default 0;
ALTER TABLE activecalls ADD localized_dst varchar(100) default NULL;
ALTER TABLE emails ADD owner_id INT(11) DEFAULT 0;
ALTER TABLE emails ADD callcenter INT(11) DEFAULT 0;
#speedup call shop
ALTER TABLE cs_invoices ADD INDEX user_id_index(user_id);
ALTER TABLE cs_invoices ADD INDEX callshop_id_index(callshop_id);
ALTER TABLE usergroups ADD INDEX user_id_index(user_id);
ALTER TABLE usergroups ADD INDEX group_id_index(group_id);
ALTER TABLE activecalls ADD INDEX user_id_index(user_id);
ALTER TABLE devices MODIFY ipaddr varchar(40); 
#---- this takes loooong time on large db -----------
ALTER TABLE calls ADD COLUMN dst_user_id INT DEFAULT NULL COMMENT 'users id which receives call';
ALTER TABLE calls ADD INDEX dst_user_id_index(dst_user_id);
#this one speedups incoming call lists
ALTER TABLE calls ADD INDEX did_id (did_id);
#Query OK, 9109839 rows affected (8 hours 2 min 4.84 sec)
# ----
# these are very slow, 1 alter 9mln calls 7h! - no real impact on speed - do not use!
#ALTER TABLE calls ADD INDEX card_id_calldate (card_id, calldate);
#ALTER TABLE calls ADD INDEX card_id_user_id_calldate (card_id,user_id,calldate);
CREATE INDEX rate_index ON aratedetails(rate_id);
DELETE rights.*  FROM rights WHERE id IN (select * from (SELECT id FROM rights GROUP BY controller, action having count(*) > 1) as tt);
DELETE role_rights.*  FROM role_rights WHERE id IN (select * from (SELECT id FROM role_rights GROUP BY role_id, right_id having count(*) > 1) as tt);
ALTER TABLE `adnumbers` ADD `uniqueid` VARCHAR( 30 ) NULL ;
## SQL sentences goes to the top ^^^^^ from this line
# make sure you press ENTER (to end line) after last SQL sentence!
# also whole SQL sentence should go into one line
# ------------ DO NOT WRITE NOTHING PAST THIS LINE ---------------
