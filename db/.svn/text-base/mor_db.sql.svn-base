USE mor;

SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `days` (
  `id` int(11) NOT NULL auto_increment,
  `date` date default NULL,
  `daytype` enum('FD','WD') default 'FD' COMMENT 'Free Day or Work Day?',
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	  


CREATE TABLE `invoicedetails` (
  `id` int(11) NOT NULL auto_increment,
  `invoice_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `quantity` int(11) default NULL,
  `price` double default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `period_start` date NOT NULL COMMENT 'when start to bill',
  `period_end` date NOT NULL COMMENT 'till when bill',
  `issue_date` date NOT NULL COMMENT 'when invoice issued',
  `paid` tinyint(4) NOT NULL default '0',
  `paid_date` datetime default NULL,
  `price` double NOT NULL default '0',
  `price_with_vat` double NOT NULL default '0',
  `payment_id` int(11) default NULL,
  `number` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `customrates` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `destinationgroup_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `acustratedetails` (
  `id` int(11) NOT NULL auto_increment,
  `from` int(11) default NULL,
  `duration` int(11) default NULL,
  `artype` enum('event','minute') default NULL,
  `round` int(11) default NULL,
  `price` double default NULL,
  `customrate_id` int(11) default NULL,
  `start_time` time default '00:00:00',
  `end_time` time default '23:59:59',
  `daytype` enum('','FD','WD') default '',  
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
		

CREATE TABLE `locations` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `locationrules` (
  `id` int(11) NOT NULL auto_increment,
  `location_id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  `enabled` tinyint(4) NOT NULL default '1',
  `cut` varchar(255) default NULL,
  `add` varchar(255) default NULL,
  `minlen` int(11) NOT NULL default '1',
  `maxlen` int(11) NOT NULL default '100',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for actions
-- ----------------------------
CREATE TABLE `actions`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`user_id` int(11) NOT NULL DEFAULT '0',
`date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`action` varchar(50) NOT NULL DEFAULT '0',
`data` varchar(255) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for addresses
-- ----------------------------
CREATE TABLE `addresses`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`direction_id` int(11) ,
`state` varchar(30) ,
`county` varchar(30) ,
`city` varchar(30) ,
`postcode` varchar(20) ,
`address` varchar(100) ,
`phone` varchar(30) ,
`mob_phone` varchar(30) ,
`fax` varchar(30) ,
`email` varchar(50) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for aratedetails
-- ----------------------------
CREATE TABLE `aratedetails`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`from` int(11) ,
`duration` int(11) ,
`artype` enum('event','minute') ,
`round` int(11) ,
`price` double ,
`rate_id` int(11),
`start_time` time default '00:00:00',
`end_time` time default '23:59:59',
`daytype` enum('','FD','WD') default '',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for calls
-- ----------------------------
CREATE TABLE `calls`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`calldate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`clid` varchar(80) NOT NULL ,
`src` varchar(80) NOT NULL ,
`dst` varchar(80) NOT NULL ,
`dcontext` varchar(80) NOT NULL ,
`channel` varchar(80) NOT NULL ,
`dstchannel` varchar(80) NOT NULL ,
`lastapp` varchar(80) NOT NULL ,
`lastdata` varchar(80) NOT NULL ,
`duration` int(11) NOT NULL DEFAULT '0',
`billsec` int(11) NOT NULL DEFAULT '0',
`disposition` varchar(45) NOT NULL ,
`amaflags` int(11) NOT NULL DEFAULT '0',
`accountcode` varchar(20) NOT NULL ,
`uniqueid` varchar(32) NOT NULL ,
`userfield` varchar(255) NOT NULL ,
`src_device_id` int(11) NOT NULL DEFAULT '0',
`dst_device_id` int(11) NOT NULL DEFAULT '0',
`processed` tinyint(4) NOT NULL DEFAULT '0',
`did_price` double NOT NULL DEFAULT '0',
`card_id` int(11) ,
`provider_id` int(11) ,
`provider_rate` double ,
`provider_billsec` int(11) ,
`provider_price` double ,
`user_id` int(11) ,
`user_rate` double ,
`user_billsec` int(11) ,
`user_price` double ,
`reseller_id` int(11) ,
`reseller_rate` double ,
`reseller_billsec` int(11) ,
`reseller_price` double ,
`partner_id` int(11) ,
`partner_rate` double ,
`partner_billsec` int(11) ,
`partner_price` double ,
`prefix` varchar(50) ,
PRIMARY KEY (`id`),
KEY `7` (`calldate`,`src_device_id`),
KEY `3` (`calldate`,`dst_device_id`,`disposition`),
KEY `2` (`calldate`,`src_device_id`,`disposition`),
KEY `5` (`calldate`,`src_device_id`,`dst_device_id`,`disposition`),
KEY `calldate` (`calldate`,`src_device_id`,`dst_device_id`),
KEY `9` (`dst_device_id`,`disposition`,`calldate`,`processed`),
KEY `4` (`calldate`,`disposition`),
KEY `id` (`id`),
KEY `calldate_2` (`calldate`,`dst_device_id`),
KEY `calldate_3` (`calldate`),
KEY `dst` (`dst`),
KEY `src_device_id` (`src_device_id`),
KEY `dst_device_id` (`dst_device_id`),
KEY `src` (`src`,`disposition`),
KEY `dst_2` (`dst`,`disposition`),
KEY `provider_id` USING BTREE (`provider_id`),
KEY `card_id` USING BTREE (`card_id`) 
)TYPE=InnoDB;

-- ----------------------------
-- Table structure for cardgroups
-- ----------------------------
CREATE TABLE `cardgroups`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`description` varchar(255) NOT NULL ,
`price` double NOT NULL DEFAULT '0',
`setup_fee` double NOT NULL DEFAULT '0',
`ghost_min_perc` double NOT NULL DEFAULT '100',
`daily_charge` double NOT NULL DEFAULT '0',
`tariff_id` int(11) NOT NULL DEFAULT '0',
`lcr_id` int(11) NOT NULL DEFAULT '0',
`created_at` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`valid_from` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`valid_till` datetime NOT NULL DEFAULT '2010-01-01 00:00:00',
`vat_percent` double NOT NULL DEFAULT '0',
`number_length` int(11) NOT NULL DEFAULT '10',
`pin_length` int(11) NOT NULL DEFAULT '4',
`dialplan_id` int(11) NOT NULL DEFAULT '0',
`image` varchar(255) DEFAULT 'example.jpg',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for cards
-- ----------------------------
CREATE TABLE `cards`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`balance` double NOT NULL DEFAULT '0',
`cardgroup_id` int(11) NOT NULL DEFAULT '0',
`sold` tinyint(4) NOT NULL DEFAULT '0',
`number` varchar(255) NOT NULL DEFAULT '0',
`pin` varchar(255) NOT NULL ,
`first_use` datetime DEFAULT '0000-00-00 00:00:00',
`daily_charge_paid_till` datetime DEFAULT '0000-00-00 00:00:00',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for cclineitems
-- ----------------------------
CREATE TABLE `cclineitems`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`cardgroup_id` int(11) ,
`quantity` int(11) NOT NULL DEFAULT '0',
`ccorder_id` int(11) ,
`card_id` int(11) ,
`price` double NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for ccorders
-- ----------------------------
CREATE TABLE `ccorders`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`amount` double NOT NULL DEFAULT '0',
`currency` varchar(5) NOT NULL DEFAULT 'USD',
`ordertype` varchar(255) ,
`email` varchar(255) ,
`date_added` datetime ,
`completed` tinyint(4) NOT NULL DEFAULT '0',
`transaction_id` varchar(255) ,
`shipped_at` datetime ,
`fee` double DEFAULT '0',
`gross` double DEFAULT '0',
`first_name` varchar(255) ,
`last_name` varchar(255) ,
`payer_email` varchar(255) ,
`residence_country` varchar(255) ,
`payer_status` varchar(255) ,
`tax` double DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for cdr
-- ----------------------------
CREATE TABLE `cdr`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`calldate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`clid` varchar(80) NOT NULL ,
`src` varchar(80) NOT NULL ,
`dst` varchar(80) NOT NULL ,
`dcontext` varchar(80) NOT NULL ,
`channel` varchar(80) NOT NULL ,
`dstchannel` varchar(80) NOT NULL ,
`lastapp` varchar(80) NOT NULL ,
`lastdata` varchar(80) NOT NULL ,
`duration` int(11) NOT NULL DEFAULT '0',
`billsec` int(11) NOT NULL DEFAULT '0',
`disposition` varchar(45) NOT NULL ,
`amaflags` int(11) NOT NULL DEFAULT '0',
`accountcode` varchar(20) NOT NULL ,
`uniqueid` varchar(32) NOT NULL ,
`userfield` varchar(255) NOT NULL ,
`mor_processed` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`),
KEY calldate (calldate),
KEY dst (dst),
KEY accountcode (accountcode)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for codecs
-- ----------------------------
CREATE TABLE `codecs`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`long_name` varchar(255) NOT NULL ,
`codec_type` varchar(255) NOT NULL DEFAULT 'audio',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for destinationgroups
-- ----------------------------
CREATE TABLE `destinationgroups`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) ,
`desttype` varchar(10) ,
`flag` varchar(10) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for destinations
-- ----------------------------
CREATE TABLE `destinations`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`prefix` varchar(255) ,
`direction_code` varchar(20) ,
`subcode` varchar(255) ,
`name` varchar(255) ,
`city` varchar(255) ,
`state` varchar(255) ,
`lata` varchar(255) ,
`tier` int(11) ,
`ocn` varchar(255) ,
`destinationgroup_id` int(11) DEFAULT '0',
PRIMARY KEY (`id`),
UNIQUE KEY prefix (prefix),
KEY id (id)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for devicecodecs
-- ----------------------------
CREATE TABLE `devicecodecs`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`device_id` int(11) NOT NULL DEFAULT '0',
`codec_id` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for devicegroups
-- ----------------------------
CREATE TABLE `devicegroups`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`user_id` int(11) ,
`address_id` int(11) ,
`name` varchar(100) ,
`added` timestamp DEFAULT CURRENT_TIMESTAMP,
`primary` tinyint(4) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for devices
-- ----------------------------
CREATE TABLE `devices`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(100) NOT NULL ,
`host` varchar(100) NOT NULL DEFAULT 'dynamic',
`secret` varchar(50) NOT NULL ,
`context` varchar(100) NOT NULL ,
`ipaddr` varchar(15) ,
`port` int(11) NOT NULL DEFAULT '0',
`regseconds` int(11) NOT NULL DEFAULT '0',
`accountcode` int(11) NOT NULL DEFAULT '0',
`callerid` varchar(100) ,
`extension` varchar(50) NOT NULL ,
`voicemail_active` tinyint(4) NOT NULL DEFAULT '0',
`username` varchar(60) NOT NULL ,
`device_type` varchar(10) NOT NULL DEFAULT 'SIP',
`user_id` int(11) NOT NULL DEFAULT '0',
`primary_did_id` int(11) NOT NULL DEFAULT '0',
`works_not_logged` tinyint(4) NOT NULL DEFAULT '1',
`forward_to` int(11) NOT NULL DEFAULT '0',
`record` tinyint(4) NOT NULL DEFAULT '0',
`transfer` varchar(255) NOT NULL DEFAULT 'no',
`disallow` varchar(255) NOT NULL DEFAULT 'all',
`allow` varchar(255) NOT NULL DEFAULT 'alaw;ulaw;g729',
`deny` varchar(255) NOT NULL DEFAULT '0.0.0.0/0.0.0.0',
`permit` varchar(255) NOT NULL DEFAULT '0.0.0.0/0.0.0.0',
`nat` varchar(5) NOT NULL DEFAULT 'yes',
`qualify` varchar(10) NOT NULL DEFAULT 'yes',
`fullcontact` varchar(80) ,
`canreinvite` varchar(255) NOT NULL DEFAULT 'no',
`devicegroup_id` int(11) ,
`dtmfmode` varchar(255) default 'rfc2833',
`callgroup` int(11) default NULL,
`pickupgroup` int(11) default NULL,
`fromuser` varchar(255) default NULL,
`fromdomain` varchar(255) default NULL,
`trustrpid` varchar(255) default 'no',
`sendrpid` varchar(255) default 'no',
`insecure` varchar(255) default 'no',
`progressinband` varchar(255) default 'never',
`videosupport` varchar(255) default 'no',
`location_id` int(11) NOT NULL default '1',
`description` varchar(255) default NULL,
`istrunk` int(11) default '0',
PRIMARY KEY (`id`),
KEY id (id),
KEY user_id (user_id, id)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for devicetypes
-- ----------------------------
CREATE TABLE `devicetypes`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(20) NOT NULL ,
`ast_name` varchar(20) NOT NULL ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for dialplans
-- ----------------------------
CREATE TABLE `dialplans`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`dptype` varchar(255) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for didrates
-- ----------------------------
CREATE TABLE `didrates`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`start_time` time NOT NULL DEFAULT '00:00:00',
`end_time` time NOT NULL DEFAULT '23:59:59',
`rate` double NOT NULL DEFAULT '0',
`connection_fee` double NOT NULL DEFAULT '0',
`increment_s` int(11) NOT NULL DEFAULT '1',
`min_time` int(11) NOT NULL DEFAULT '0',
`did_id` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for dids
-- ----------------------------
CREATE TABLE `dids`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`did` varchar(50) NOT NULL ,
`status` varchar(255) NOT NULL DEFAULT 'free',
`user_id` int(11) NOT NULL DEFAULT '0',
`device_id` int(11) NOT NULL DEFAULT '0',
`subscription_id` int(11) NOT NULL DEFAULT '0',
`reseller_id` int(11) NOT NULL DEFAULT '0',
`closed_till` datetime NOT NULL DEFAULT '2006-01-01 00:00:00',
`dialplan_id` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for directions
-- ----------------------------
CREATE TABLE `directions`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`code` varchar(255) NOT NULL ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for extlines
-- ----------------------------
CREATE TABLE `extlines`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`context` varchar(20) NOT NULL ,
`exten` varchar(20) NOT NULL ,
`priority` int(4) NOT NULL DEFAULT '0',
`app` varchar(20) NOT NULL ,
`appdata` varchar(128) NOT NULL ,
`device_id` int(11) ,
PRIMARY KEY (`id`, `context`, `exten`, `priority`),
KEY id (id)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for groups
-- ----------------------------
CREATE TABLE `groups`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`grouptype` varchar(255) NOT NULL DEFAULT 'simple',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for lcrproviders
-- ----------------------------
CREATE TABLE `lcrproviders`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`lcr_id` bigint(20) NOT NULL DEFAULT '0',
`provider_id` bigint(20) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for lcrs
-- ----------------------------
CREATE TABLE `lcrs`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`order` varchar(255) NOT NULL DEFAULT 'price',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for payments
-- ----------------------------
CREATE TABLE `payments`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`paymenttype` varchar(255) ,
`amount` double NOT NULL DEFAULT '0',
`currency` varchar(5) NOT NULL DEFAULT 'USD',
`email` varchar(255) ,
`date_added` datetime ,
`completed` tinyint(4) NOT NULL DEFAULT '0',
`transaction_id` varchar(255) ,
`shipped_at` datetime ,
`fee` double DEFAULT '0',
`gross` double DEFAULT '0',
`first_name` varchar(255) ,
`last_name` varchar(255) ,
`payer_email` varchar(255) ,
`residence_country` varchar(255) ,
`payer_status` varchar(255) ,
`tax` double DEFAULT '0',
`user_id` int(11) ,
`pending_reason` varchar(255) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for phonebooks
-- ----------------------------
CREATE TABLE `phonebooks`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`user_id` int(11) NOT NULL DEFAULT '0',
`number` varchar(255) NOT NULL ,
`name` varchar(255) NOT NULL ,
`added` datetime NOT NULL ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for providercodecs
-- ----------------------------
CREATE TABLE `providercodecs`(
`id` int(20) NOT NULL AUTO_INCREMENT ,
`provider_id` int(20) NOT NULL DEFAULT '0',
`codec_id` int(20) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for providerrules
-- ----------------------------
CREATE TABLE `providerrules`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`provider_id` int(11) NOT NULL DEFAULT '0',
`start` varchar(255) ,
`length` int(11) NOT NULL DEFAULT '0',
`add` varchar(255) ,
`cut` int(11) NOT NULL DEFAULT '0',
`comment` varchar(255) ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for providers
-- ----------------------------
CREATE TABLE `providers`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`tech` varchar(255) NOT NULL ,
`channel` varchar(255),
`login` varchar(255) NOT NULL ,
`password` varchar(255) NOT NULL ,
`server_ip` varchar(255) NOT NULL ,
`port` varchar(255) NOT NULL DEFAULT '4569',
`priority` int(11) NOT NULL DEFAULT '1',
`quality` int(11) NOT NULL DEFAULT '1',
`tariff_id` bigint(20) NOT NULL DEFAULT '0',
`cut_a` int(11) NOT NULL DEFAULT '0',
`cut_b` int(11) NOT NULL DEFAULT '0',
`add_a` varchar(255),
`add_b` varchar(255),
`device_id` bigint(20) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for providertypes
-- ----------------------------
CREATE TABLE `providertypes`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(20) NOT NULL ,
`ast_name` varchar(20) NOT NULL ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for ratedetails
-- ----------------------------
CREATE TABLE `ratedetails`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`start_time` time NOT NULL DEFAULT '00:00:00',
`end_time` time NOT NULL DEFAULT '23:59:59',
`rate` double NOT NULL DEFAULT '0',
`connection_fee` double NOT NULL DEFAULT '0',
`rate_id` bigint(20) NOT NULL DEFAULT '0',
`increment_s` int(11) NOT NULL DEFAULT '1',
`min_time` int(11) NOT NULL DEFAULT '0',
`daytype` enum('','FD','WD') default '',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for rates
-- ----------------------------
CREATE TABLE `rates`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`tariff_id` bigint(20) NOT NULL DEFAULT '0',
`destination_id` bigint(20) NOT NULL DEFAULT '0',
`destinationgroup_id` int(11) ,
PRIMARY KEY (`id`),
KEY tariff (tariff_id),
KEY dst (destination_id),
KEY id (id)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for recordings
-- ----------------------------
CREATE TABLE `recordings`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`datetime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
`src` varchar(255) NOT NULL ,
`dst` varchar(255) NOT NULL ,
`src_device_id` bigint(20) NOT NULL DEFAULT '0',
`dst_device_id` bigint(20) NOT NULL DEFAULT '0',
`call_id` bigint(20) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for services
-- ----------------------------
CREATE TABLE `services`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) ,
`servicetype` varchar(255) NOT NULL DEFAULT 'dialing',
`destinationgroup_id` int(11) ,
`periodtype` varchar(255) NOT NULL DEFAULT 'day',
`price` double NOT NULL DEFAULT '0',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for subscriptions
-- ----------------------------
CREATE TABLE `subscriptions`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`service_id` int(11) ,
`user_id` int(11) ,
`device_id` int(11) ,
`activation_start` datetime ,
`activation_end` datetime ,
`added` datetime ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for tariffs
-- ----------------------------
CREATE TABLE `tariffs`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`name` varchar(255) NOT NULL ,
`purpose` varchar(255) NOT NULL DEFAULT 'user',
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for usergroups
-- ----------------------------
CREATE TABLE `usergroups`(
`id` bigint(20) NOT NULL AUTO_INCREMENT ,
`user_id` bigint(20) NOT NULL DEFAULT '0',
`group_id` bigint(20) NOT NULL DEFAULT '0',
`gusertype` varchar(255) NOT NULL ,
PRIMARY KEY (`id`)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for users
-- ----------------------------
CREATE TABLE `users`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`username` varchar(30) NOT NULL ,
`password` varchar(100) NOT NULL ,
`usertype` varchar(20) NOT NULL DEFAULT 'user',
`logged` tinyint(4) NOT NULL DEFAULT '0',
`first_name` varchar(50) NOT NULL ,
`last_name` varchar(50) NOT NULL ,
`calltime_normative` double NOT NULL DEFAULT '3',
`show_in_realtime_stats` tinyint(4) NOT NULL DEFAULT '0',
`balance` double NOT NULL DEFAULT '0',
`frozen_balance` double NOT NULL DEFAULT '0',
`lcr_id` bigint(20) NOT NULL DEFAULT '0',
`postpaid` tinyint(4) NOT NULL DEFAULT '1',
`blocked` tinyint(4) NOT NULL DEFAULT '0',
`tariff_id` bigint(20) NOT NULL DEFAULT '0',
`month_plan_perc` double NOT NULL DEFAULT '0',
`month_plan_updated` datetime DEFAULT '0000-00-00 00:00:00',
`sales_this_month` int(11) NOT NULL DEFAULT '0',
`sales_this_month_planned` int(11) NOT NULL DEFAULT '0',
`show_billing_info` tinyint(4) NOT NULL DEFAULT '1',
`primary_device_id` int(11) NOT NULL DEFAULT '0',
`credit` double DEFAULT '-1',
`clientid` varchar(30) ,
`agreement_number` varchar(20) ,
`agreement_date` date ,
`language` varchar(10) ,
`taxation_country` int(11) ,
`vat_number` varchar(30) ,
`vat_percent` double NOT NULL default '0',
`address_id` int(11) ,
`accounting_number` varchar(30) ,
PRIMARY KEY (`id`),
KEY id (id)) TYPE=InnoDB;

-- ----------------------------
-- Table structure for voicemail_boxes
-- ----------------------------
CREATE TABLE `voicemail_boxes`(
`id` int(11) NOT NULL AUTO_INCREMENT ,
`context` varchar(50) NOT NULL ,
`mailbox` varchar(11) NOT NULL DEFAULT '0',
`password` varchar(5) NOT NULL DEFAULT '0',
`fullname` varchar(150) NOT NULL ,
`email` varchar(50) NOT NULL ,
`pager` varchar(50) NOT NULL ,
`tz` varchar(10) NOT NULL DEFAULT 'central',
`attach` varchar(4) NOT NULL DEFAULT 'yes',
`saycid` varchar(4) NOT NULL DEFAULT 'yes',
`dialout` varchar(10) NOT NULL ,
`callback` varchar(10) NOT NULL ,
`review` varchar(4) NOT NULL DEFAULT 'no',
`operator` varchar(4) NOT NULL DEFAULT 'no',
`envelope` varchar(4) NOT NULL DEFAULT 'no',
`sayduration` varchar(4) NOT NULL DEFAULT 'no',
`saydurationm` tinyint(4) NOT NULL DEFAULT '1',
`sendvoicemail` varchar(4) NOT NULL DEFAULT 'no',
`delete` varchar(4) NOT NULL DEFAULT 'no',
`nextaftercmd` varchar(4) NOT NULL DEFAULT 'yes',
`forcename` varchar(4) NOT NULL DEFAULT 'no',
`forcegreetings` varchar(4) NOT NULL DEFAULT 'no',
`hidefromdir` varchar(4) NOT NULL DEFAULT 'yes',
`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`device_id` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`id`),
KEY mailbox (mailbox, context)) TYPE=InnoDB;



-- ----------------------------
-- Records 
-- ----------------------------
INSERT INTO `addresses` VALUES ('1', '1', '', '', '', '', '', '', '', '', '');
INSERT INTO `codecs` VALUES ('1', 'alaw', 'G.711 A-law', 'audio');
INSERT INTO `codecs` VALUES ('2', 'ulaw', 'G.711 u-law', 'audio');
INSERT INTO `codecs` VALUES ('4', 'g726', 'G.726', 'audio');
INSERT INTO `codecs` VALUES ('3', 'g723', 'G.723.1', 'audio');
INSERT INTO `codecs` VALUES ('5', 'g729', 'G.729', 'audio');
INSERT INTO `codecs` VALUES ('6', 'gsm', 'GSM', 'audio');
INSERT INTO `codecs` VALUES ('7', 'ilbc', 'iLBC', 'audio');
INSERT INTO `codecs` VALUES ('8', 'lpc10', 'LPC10', 'audio');
INSERT INTO `codecs` VALUES ('9', 'speex', 'Speex', 'audio');
INSERT INTO `codecs` VALUES ('10', 'adpcm', 'ADPCM', 'audio');
INSERT INTO `codecs` VALUES ('11', 'slin', '16 bit Signed Linear PCM', 'audio');
INSERT INTO `codecs` VALUES ('12', 'h261', 'H.261 Video', 'video');
INSERT INTO `codecs` VALUES ('13', 'h263', 'H.263 Video', 'video');
INSERT INTO `codecs` VALUES ('14', 'h263p', 'H.263+ Video', 'video');
INSERT INTO `codecs` VALUES ('15', 'jpeg', 'JPEG image', 'image');
INSERT INTO `codecs` VALUES ('16', 'png', 'PNG image', 'image');
INSERT INTO `devicetypes` VALUES ('1', 'SIP', 'SIP');
INSERT INTO `devicetypes` VALUES ('2', 'IAX2', 'IAX2');
INSERT INTO `devicetypes` VALUES ('3', 'H323', 'OOH323');
INSERT INTO `devicetypes` VALUES ('4', 'ZAP', 'ZAP');
INSERT INTO `directions` VALUES ('1', 'Afghanistan', 'AFG');
INSERT INTO `directions` VALUES ('2', 'Albania', 'ALB');
INSERT INTO `directions` VALUES ('3', 'Algeria', 'DZA');
INSERT INTO `directions` VALUES ('4', 'American Samoa', 'ASM');
INSERT INTO `directions` VALUES ('5', 'Andorra', 'AND');
INSERT INTO `directions` VALUES ('6', 'Angola', 'AGO');
INSERT INTO `directions` VALUES ('7', 'Anguilla', 'AIA');
INSERT INTO `directions` VALUES ('8', 'Antarctica', 'ATA');
INSERT INTO `directions` VALUES ('9', 'Antigua And Barbuda', 'ATG');
INSERT INTO `directions` VALUES ('10', 'Argentina', 'ARG');
INSERT INTO `directions` VALUES ('11', 'Armenia', 'ARM');
INSERT INTO `directions` VALUES ('12', 'Aruba', 'ABW');
INSERT INTO `directions` VALUES ('13', 'Australia', 'AUS');
INSERT INTO `directions` VALUES ('14', 'Austria', 'AUT');
INSERT INTO `directions` VALUES ('15', 'Azerbaijan', 'AZE');
INSERT INTO `directions` VALUES ('16', 'Bahamas', 'BHS');
INSERT INTO `directions` VALUES ('17', 'Bahrain', 'BHR');
INSERT INTO `directions` VALUES ('18', 'Bangladesh', 'BGD');
INSERT INTO `directions` VALUES ('19', 'Barbados', 'BRB');
INSERT INTO `directions` VALUES ('20', 'Belarus', 'BLR');
INSERT INTO `directions` VALUES ('21', 'Belgium', 'BEL');
INSERT INTO `directions` VALUES ('22', 'Belize', 'BLZ');
INSERT INTO `directions` VALUES ('23', 'Benin', 'BEN');
INSERT INTO `directions` VALUES ('24', 'Bermuda', 'BMU');
INSERT INTO `directions` VALUES ('25', 'Bhutan', 'BTN');
INSERT INTO `directions` VALUES ('26', 'Bolivia', 'BOL');
INSERT INTO `directions` VALUES ('27', 'Bosnia And Herzegovina', 'BIH');
INSERT INTO `directions` VALUES ('28', 'Botswana', 'BWA');
INSERT INTO `directions` VALUES ('30', 'Brazil', 'BRA');
INSERT INTO `directions` VALUES ('32', 'Brunei Darussalam', 'BRN');
INSERT INTO `directions` VALUES ('33', 'Bulgaria', 'BGR');
INSERT INTO `directions` VALUES ('34', 'Burkina Faso', 'BFA');
INSERT INTO `directions` VALUES ('35', 'Burundi', 'BDI');
INSERT INTO `directions` VALUES ('36', 'Cambodia', 'KHM');
INSERT INTO `directions` VALUES ('37', 'Cameroon', 'CMR');
INSERT INTO `directions` VALUES ('38', 'Canada', 'CAN');
INSERT INTO `directions` VALUES ('39', 'Cape Verde', 'CPV');
INSERT INTO `directions` VALUES ('40', 'Cayman Islands', 'CYM');
INSERT INTO `directions` VALUES ('41', 'Central African Republic', 'CAF');
INSERT INTO `directions` VALUES ('42', 'Chad', 'TCD');
INSERT INTO `directions` VALUES ('43', 'Chile', 'CHL');
INSERT INTO `directions` VALUES ('44', 'China', 'CHN');
INSERT INTO `directions` VALUES ('45', 'Christmas Island', 'CXR');
INSERT INTO `directions` VALUES ('46', 'Cocos (Keeling) Islands', 'CCK');
INSERT INTO `directions` VALUES ('47', 'Colombia', 'COL');
INSERT INTO `directions` VALUES ('48', 'Comoros', 'COM');
INSERT INTO `directions` VALUES ('49', 'Congo', 'COG');
INSERT INTO `directions` VALUES ('50', 'Congo, The Democratic Republic Of The', 'COD');
INSERT INTO `directions` VALUES ('51', 'Cook Islands', 'COK');
INSERT INTO `directions` VALUES ('52', 'Costa Rica', 'CRI');
INSERT INTO `directions` VALUES ('53', 'Ivory Cost', 'CIV');
INSERT INTO `directions` VALUES ('54', 'Croatia', 'HRV');
INSERT INTO `directions` VALUES ('55', 'Cuba', 'CUB');
INSERT INTO `directions` VALUES ('56', 'Cyprus', 'CYP');
INSERT INTO `directions` VALUES ('57', 'Czech Republic', 'CZE');
INSERT INTO `directions` VALUES ('58', 'Denmark', 'DNK');
INSERT INTO `directions` VALUES ('59', 'Djibouti', 'DJI');
INSERT INTO `directions` VALUES ('60', 'Dominica', 'DMA');
INSERT INTO `directions` VALUES ('61', 'Dominican Republic', 'DOM');
INSERT INTO `directions` VALUES ('62', 'Ecuador', 'ECU');
INSERT INTO `directions` VALUES ('63', 'Egypt', 'EGY');
INSERT INTO `directions` VALUES ('64', 'El Salvador', 'SLV');
INSERT INTO `directions` VALUES ('65', 'Equatorial Guinea', 'GNQ');
INSERT INTO `directions` VALUES ('66', 'Eritrea', 'ERI');
INSERT INTO `directions` VALUES ('67', 'Estonia', 'EST');
INSERT INTO `directions` VALUES ('68', 'Ethiopia', 'ETH');
INSERT INTO `directions` VALUES ('69', 'Falkland Islands (Malvinas)', 'FLK');
INSERT INTO `directions` VALUES ('70', 'Faroe Islands', 'FRO');
INSERT INTO `directions` VALUES ('71', 'Fiji', 'FJI');
INSERT INTO `directions` VALUES ('72', 'Finland', 'FIN');
INSERT INTO `directions` VALUES ('73', 'France', 'FRA');
INSERT INTO `directions` VALUES ('74', 'French Guiana', 'GUF');
INSERT INTO `directions` VALUES ('75', 'French Polynesia', 'PYF');
INSERT INTO `directions` VALUES ('77', 'Gabon', 'GAB');
INSERT INTO `directions` VALUES ('78', 'Gambia', 'GMB');
INSERT INTO `directions` VALUES ('79', 'Georgia', 'GEO');
INSERT INTO `directions` VALUES ('80', 'Germany', 'DEU');
INSERT INTO `directions` VALUES ('81', 'Ghana', 'GHA');
INSERT INTO `directions` VALUES ('82', 'Gibraltar', 'GIB');
INSERT INTO `directions` VALUES ('83', 'Greece', 'GRC');
INSERT INTO `directions` VALUES ('84', 'Greenland', 'GRL');
INSERT INTO `directions` VALUES ('85', 'Grenada', 'GRD');
INSERT INTO `directions` VALUES ('86', 'Guadeloupe', 'GLP');
INSERT INTO `directions` VALUES ('87', 'Guam', 'GUM');
INSERT INTO `directions` VALUES ('88', 'Guatemala', 'GTM');
INSERT INTO `directions` VALUES ('89', 'Guinea', 'GIN');
INSERT INTO `directions` VALUES ('90', 'Guinea-Bissau', 'GNB');
INSERT INTO `directions` VALUES ('91', 'Guyana', 'GUY');
INSERT INTO `directions` VALUES ('92', 'Haiti', 'HTI');
INSERT INTO `directions` VALUES ('94', 'Vatican City', 'VAT');
INSERT INTO `directions` VALUES ('95', 'Honduras', 'HND');
INSERT INTO `directions` VALUES ('96', 'Hong Kong', 'HKG');
INSERT INTO `directions` VALUES ('97', 'Hungary', 'HUN');
INSERT INTO `directions` VALUES ('98', 'Iceland', 'ISL');
INSERT INTO `directions` VALUES ('99', 'India', 'IND');
INSERT INTO `directions` VALUES ('100', 'Indonesia', 'IDN');
INSERT INTO `directions` VALUES ('101', 'Iran', 'IRN');
INSERT INTO `directions` VALUES ('102', 'Iraq', 'IRQ');
INSERT INTO `directions` VALUES ('103', 'Ireland', 'IRL');
INSERT INTO `directions` VALUES ('104', 'Israel', 'ISR');
INSERT INTO `directions` VALUES ('105', 'Italy', 'ITA');
INSERT INTO `directions` VALUES ('106', 'Jamaica', 'JAM');
INSERT INTO `directions` VALUES ('107', 'Japan', 'JPN');
INSERT INTO `directions` VALUES ('108', 'Jordan', 'JOR');
INSERT INTO `directions` VALUES ('109', 'Kazakhstan', 'KAZ');
INSERT INTO `directions` VALUES ('110', 'Kenya', 'KEN');
INSERT INTO `directions` VALUES ('111', 'Kiribati', 'KIR');
INSERT INTO `directions` VALUES ('112', 'Korea, Democratic People\'s Republic Of', 'PRK');
INSERT INTO `directions` VALUES ('113', 'Korea, Republic of', 'KOR');
INSERT INTO `directions` VALUES ('114', 'Kuwait', 'KWT');
INSERT INTO `directions` VALUES ('115', 'Kyrgyzstan', 'KGZ');
INSERT INTO `directions` VALUES ('116', 'Laos', 'LAO');
INSERT INTO `directions` VALUES ('117', 'Latvia', 'LVA');
INSERT INTO `directions` VALUES ('118', 'Lebanon', 'LBN');
INSERT INTO `directions` VALUES ('119', 'Lesotho', 'LSO');
INSERT INTO `directions` VALUES ('120', 'Liberia', 'LBR');
INSERT INTO `directions` VALUES ('121', 'Libyan Arab Jamahiriya', 'LBY');
INSERT INTO `directions` VALUES ('122', 'Liechtenstein', 'LIE');
INSERT INTO `directions` VALUES ('123', 'Lithuania', 'LTU');
INSERT INTO `directions` VALUES ('124', 'Luxembourg', 'LUX');
INSERT INTO `directions` VALUES ('125', 'Macao', 'MAC');
INSERT INTO `directions` VALUES ('126', 'Macedonia', 'MKD');
INSERT INTO `directions` VALUES ('127', 'Madagascar', 'MDG');
INSERT INTO `directions` VALUES ('128', 'Malawi', 'MWI');
INSERT INTO `directions` VALUES ('129', 'Malaysia', 'MYS');
INSERT INTO `directions` VALUES ('130', 'Maldives', 'MDV');
INSERT INTO `directions` VALUES ('131', 'Mali', 'MLI');
INSERT INTO `directions` VALUES ('132', 'Malta', 'MLT');
INSERT INTO `directions` VALUES ('133', 'Marshall islands', 'MHL');
INSERT INTO `directions` VALUES ('134', 'Martinique', 'MTQ');
INSERT INTO `directions` VALUES ('135', 'Mauritania', 'MRT');
INSERT INTO `directions` VALUES ('136', 'Mauritius', 'MUS');
INSERT INTO `directions` VALUES ('137', 'Mayotte', 'MYT');
INSERT INTO `directions` VALUES ('138', 'Mexico', 'MEX');
INSERT INTO `directions` VALUES ('139', 'Micronesia', 'FSM');
INSERT INTO `directions` VALUES ('140', 'Moldova', 'MDA');
INSERT INTO `directions` VALUES ('141', 'Monaco', 'MCO');
INSERT INTO `directions` VALUES ('142', 'Mongolia', 'MNG');
INSERT INTO `directions` VALUES ('143', 'Montserrat', 'MSR');
INSERT INTO `directions` VALUES ('144', 'Morocco', 'MAR');
INSERT INTO `directions` VALUES ('145', 'Mozambique', 'MOZ');
INSERT INTO `directions` VALUES ('146', 'Myanmar', 'MMR');
INSERT INTO `directions` VALUES ('147', 'Namibia', 'NAM');
INSERT INTO `directions` VALUES ('148', 'Nauru', 'NRU');
INSERT INTO `directions` VALUES ('149', 'Nepal', 'NPL');
INSERT INTO `directions` VALUES ('150', 'Netherlands', 'NLD');
INSERT INTO `directions` VALUES ('151', 'Netherlands Antilles', 'ANT');
INSERT INTO `directions` VALUES ('152', 'New Caledonia', 'NCL');
INSERT INTO `directions` VALUES ('153', 'New Zealand', 'NZL');
INSERT INTO `directions` VALUES ('154', 'Nicaragua', 'NIC');
INSERT INTO `directions` VALUES ('155', 'Niger', 'NER');
INSERT INTO `directions` VALUES ('156', 'Nigeria', 'NGA');
INSERT INTO `directions` VALUES ('157', 'Niue', 'NIU');
INSERT INTO `directions` VALUES ('158', 'Norfolk Island', 'NFK');
INSERT INTO `directions` VALUES ('159', 'Northern Mariana Islands', 'MNP');
INSERT INTO `directions` VALUES ('160', 'Norway', 'NOR');
INSERT INTO `directions` VALUES ('161', 'Oman', 'OMN');
INSERT INTO `directions` VALUES ('162', 'Pakistan', 'PAK');
INSERT INTO `directions` VALUES ('163', 'Palau', 'PLW');
INSERT INTO `directions` VALUES ('164', 'Palestine', 'PSE');
INSERT INTO `directions` VALUES ('165', 'Panama', 'PAN');
INSERT INTO `directions` VALUES ('166', 'Papua New Guinea', 'PNG');
INSERT INTO `directions` VALUES ('167', 'Paraguay', 'PRY');
INSERT INTO `directions` VALUES ('168', 'Peru', 'PER');
INSERT INTO `directions` VALUES ('169', 'Philippines', 'PHL');
INSERT INTO `directions` VALUES ('171', 'Poland', 'POL');
INSERT INTO `directions` VALUES ('172', 'Portugal', 'PRT');
INSERT INTO `directions` VALUES ('173', 'Puerto Rico', 'PRI');
INSERT INTO `directions` VALUES ('174', 'Qatar', 'QAT');
INSERT INTO `directions` VALUES ('175', 'Reunion', 'REU');
INSERT INTO `directions` VALUES ('176', 'Romania', 'ROU');
INSERT INTO `directions` VALUES ('177', 'Russian Federation', 'RUS');
INSERT INTO `directions` VALUES ('178', 'Rwanda', 'RWA');
INSERT INTO `directions` VALUES ('179', 'Saint Helena', 'SHN');
INSERT INTO `directions` VALUES ('180', 'Saint Kitts And Nevis', 'KNA');
INSERT INTO `directions` VALUES ('181', 'Saint Lucia', 'LCA');
INSERT INTO `directions` VALUES ('182', 'Saint Pierre And Miquelon', 'SPM');
INSERT INTO `directions` VALUES ('183', 'Saint Vincent And The Grenadines', 'VCT');
INSERT INTO `directions` VALUES ('184', 'Samoa', 'WSM');
INSERT INTO `directions` VALUES ('185', 'San Marino', 'SMR');
INSERT INTO `directions` VALUES ('186', 'Sao Tome And Principe', 'STP');
INSERT INTO `directions` VALUES ('187', 'Saudi Arabia', 'SAU');
INSERT INTO `directions` VALUES ('188', 'Senegal', 'SEN');
INSERT INTO `directions` VALUES ('189', 'Seychelles', 'SYC');
INSERT INTO `directions` VALUES ('190', 'Sierra Leone', 'SLE');
INSERT INTO `directions` VALUES ('191', 'Singapore', 'SGP');
INSERT INTO `directions` VALUES ('192', 'Slovakia', 'SVK');
INSERT INTO `directions` VALUES ('193', 'Slovenia', 'SVN');
INSERT INTO `directions` VALUES ('194', 'Solomon Islands', 'SLB');
INSERT INTO `directions` VALUES ('195', 'Somalia', 'SOM');
INSERT INTO `directions` VALUES ('196', 'South Africa', 'ZAF');
INSERT INTO `directions` VALUES ('198', 'Spain', 'ESP');
INSERT INTO `directions` VALUES ('199', 'Sri Lanka', 'LKA');
INSERT INTO `directions` VALUES ('200', 'Sudan', 'SDN');
INSERT INTO `directions` VALUES ('201', 'Suriname', 'SUR');
INSERT INTO `directions` VALUES ('203', 'Swaziland', 'SWZ');
INSERT INTO `directions` VALUES ('204', 'Sweden', 'SWE');
INSERT INTO `directions` VALUES ('205', 'Switzerland', 'CHE');
INSERT INTO `directions` VALUES ('206', 'Syrian Arab Republic', 'SYR');
INSERT INTO `directions` VALUES ('207', 'Taiwan', 'TWN');
INSERT INTO `directions` VALUES ('208', 'Tajikistan', 'TJK');
INSERT INTO `directions` VALUES ('209', 'Tanzania', 'TZA');
INSERT INTO `directions` VALUES ('210', 'Thailand', 'THA');
INSERT INTO `directions` VALUES ('212', 'Togo', 'TGO');
INSERT INTO `directions` VALUES ('213', 'Tokelau', 'TKL');
INSERT INTO `directions` VALUES ('214', 'Tonga', 'TON');
INSERT INTO `directions` VALUES ('215', 'Trinidad And Tobago', 'TTO');
INSERT INTO `directions` VALUES ('216', 'Tunisia', 'TUN');
INSERT INTO `directions` VALUES ('217', 'Turkey', 'TUR');
INSERT INTO `directions` VALUES ('218', 'Turkmenistan', 'TKM');
INSERT INTO `directions` VALUES ('219', 'Turks And Caicos Islands', 'TCA');
INSERT INTO `directions` VALUES ('220', 'Tuvalu', 'TUV');
INSERT INTO `directions` VALUES ('221', 'Uganda', 'UGA');
INSERT INTO `directions` VALUES ('222', 'Ukraine', 'UKR');
INSERT INTO `directions` VALUES ('223', 'United Arab Emirates', 'ARE');
INSERT INTO `directions` VALUES ('224', 'United Kingdom', 'GBR');
INSERT INTO `directions` VALUES ('225', 'United States', 'USA');
INSERT INTO `directions` VALUES ('227', 'Uruguay', 'URY');
INSERT INTO `directions` VALUES ('228', 'Uzbekistan', 'UZB');
INSERT INTO `directions` VALUES ('229', 'Vanuatu', 'VUT');
INSERT INTO `directions` VALUES ('230', 'Venezuela', 'VEN');
INSERT INTO `directions` VALUES ('231', 'Vietnam', 'VNM');
INSERT INTO `directions` VALUES ('232', 'Virgin Islands, British', 'VGB');
INSERT INTO `directions` VALUES ('233', 'Virgin Islands, U.S.', 'VIR');
INSERT INTO `directions` VALUES ('234', 'Wallis And Futuna', 'WLF');
INSERT INTO `directions` VALUES ('236', 'Yemen', 'YEM');
INSERT INTO `directions` VALUES ('238', 'Zambia', 'ZMB');
INSERT INTO `directions` VALUES ('239', 'Zimbabwe', 'ZWE');
INSERT INTO `directions` VALUES ('240', 'Ascension Island', 'ASC');
INSERT INTO `directions` VALUES ('241', 'Diego Garcia', 'DGA');
INSERT INTO `directions` VALUES ('242', 'Inmarsat', 'XNM');
INSERT INTO `directions` VALUES ('243', 'East Timor', 'TMP');
INSERT INTO `directions` VALUES ('246', 'Iridium', 'IRI');
INSERT INTO `directions` VALUES ('247', 'Serbia and Montenegro', 'SCG');
INSERT INTO `directions` VALUES ('250', 'Emsat', 'EMS');
INSERT INTO `directions` VALUES ('251', 'Ellipso-3', 'EL3');
INSERT INTO `directions` VALUES ('252', 'Globalstar', 'GS8');
INSERT INTO `extlines` (`id`, `context`, `exten`, `priority`, `app`, `appdata`, `device_id`) VALUES 
(1, 'mor', '556', 1, 'ChanSpy', 'IAX2|q', 0),
(38, 'mor', 'HANGUP', 1, 'Congestion', '4', 0),
(36, 'mor', 'BUSY', 1, 'Busy', '10', 0),
(37, 'mor', 'BUSY', 2, 'Hangup', '', 0),
(6, 'mor', '_X.', 5, 'GotoIf', '$["${DIALSTATUS}" = "BUSY"]?BUSY|1:HANGUP|1', 0),
(5, 'mor', '_X.', 4, 'GotoIf', '$[$["${DIALSTATUS}" = "CHANUNAVAIL"] | $["${DIALSTATUS}" = "CONGESTION"]]?FAILED|1', 0),
(4, 'mor', '_X.', 3, 'NoOp', 'HANGUPCAUSE: ${HANGUPCAUSE}', 0),
(3, 'mor', '_X.', 2, 'mor', '${EXTEN}', 0),
(2, 'mor', '_X.', 1, 'NoOp', 'MOR starts', 0),
(15, 'mor', '101', 1, 'GotoIf', '$[${LEN(${CALLED_TO})} > 0]?2:4', 1),
(16, 'mor', '101', 2, 'Set', 'CALLERID(NAME)=TRANSFER FROM ${CALLED_TO}', 1),
(17, 'mor', '101', 3, 'Goto', '101|5', 1),
(18, 'mor', '101', 4, 'Set', 'CALLED_TO=${EXTEN}', 1),
(19, 'mor', '101', 5, 'NoOp', 'MOR starts', 1),
(20, 'mor', '101', 6, 'GotoIf', '$[${LEN(${CALLERID(NAME)})} > 0]?9:7', 1),
(21, 'mor', '101', 7, 'GotoIf', '$[${LEN(${mor_cid_name})} > 0]?8:9', 1),
(22, 'mor', '101', 8, 'Set', 'CALLERID(NAME)=${mor_cid_name}', 1),
(23, 'mor', '101', 9, 'Dial', 'IAX2/101', 1),
(24, 'mor', '101', 10, 'GotoIf', '$["${DIALSTATUS}" = "CHANUNAVAIL"]?301', 1),
(25, 'mor', '101', 11, 'Hangup', '', 1),
(26, 'mor', '101', 209, 'Background', 'busy', 1),
(27, 'mor', '101', 210, 'Busy', '10', 1),
(28, 'mor', '101', 211, 'Hangup', '', 1),
(29, 'mor', '101', 301, 'Ringing', '', 1),
(30, 'mor', '101', 302, 'Wait', '120', 1),
(31, 'mor', '101', 303, 'Hangup', '', 1),
(39, 'mor', 'HANGUP', 2, 'Hangup', '', 0),
(40, 'mor', 'FAILED', 1, 'Congestion', '4', 0),
(41, 'mor', 'FAILED', 2, 'Hangup', '', 0),
(42, 'mor', '*89', 1, 'VoiceMailMain', '', 0),
(43, 'mor', '*89', 2, 'Hangup', '', 0),
(44, 'mor', 'fax', 1, 'Goto', 'mor_fax2email|123|1', 0),
(45, 'mor', '102', 1, 'GotoIf', '$[${LEN(${CALLED_TO})} > 0]?2:4', 2),
(46, 'mor', '102', 2, 'NoOp', 'CALLERID(NAME)=TRANSFER FROM ${CALLED_TO}', 2),
(47, 'mor', '102', 3, 'Goto', '102|5', 2),
(48, 'mor', '102', 4, 'Set', 'CALLED_TO=${EXTEN}', 2),
(49, 'mor', '102', 5, 'Set', 'MOR_FAX_ID=2', 2),
(50, 'mor', '102', 6, 'Set', 'FAXSENDER=${CALLERID(number)}', 2),
(51, 'mor', '102', 7, 'Goto', 'mor_fax2email|${EXTEN}|1', 2),
(52, 'mor', '102', 401, 'NoOp', 'NO ANSWER', 2),
(53, 'mor', '102', 402, 'Hangup', '', 2),
(54, 'mor', '102', 201, 'NoOp', 'BUSY', 2),
(55, 'mor', '102', 202, 'GotoIf', '${LEN(${MOR_CALL_FROM_DID}) = 1}?203:BUSY|1', 2),
(56, 'mor', '102', 203, 'Busy', '1', 2),
(57, 'mor', '102', 301, 'NoOp', 'FAILED', 2),
(58, 'mor', '102', 302, 'GotoIf', '${LEN(${MOR_CALL_FROM_DID}) = 1}?303:FAILED|1', 2),
(59, 'mor', '102', 303, 'Congestion', '1', 2);
#INSERT INTO `groups` VALUES ('1', 'All users', 'simple');
INSERT INTO `lcrproviders` VALUES ('1', '1', '1');
INSERT INTO `lcrs` VALUES ('1', 'Primary', 'price');
INSERT INTO `providertypes` VALUES ('1', 'Zap', 'Zap');
INSERT INTO `providertypes` VALUES ('2', 'SIP', 'SIP');
INSERT INTO `providertypes` VALUES ('3', 'IAX2', 'IAX2');
INSERT INTO `providertypes` VALUES ('4', 'H323', 'OOH323');
#INSERT INTO `usergroups` VALUES ('1', '0', '1', 'manager');
#INSERT INTO `usergroups` VALUES ('2', '1', '1', 'user');
#INSERT INTO `usergroups` VALUES ('3', '2', '1', 'user');
#INSERT INTO `usergroups` VALUES ('4', '3', '1', 'user');

INSERT INTO `users` VALUES ('0', 'admin', 'd033e22ae348aeb5660fc2140aec35850c4da997', 'admin', '0', 'System', 'Admin', '3', '0', '0', '0', '1', '1', '0', '2', '0', '2000-01-01 00:00:00', '0', '0', '1', '0', '-1', '', '', '2007-03-26', '', '1', '', '18', '1', '');
INSERT INTO `users` VALUES ('2', '101', 'dbc0f004854457f59fb16ab863a3a1722cef553f', 'user', '0', 'Test User', '#1', '3', '1', '0', '0', '1', '1', '0', '2', '0', '2000-01-01 00:00:00', '0', '0', '1', '0', '-1', null, null, null, null, null, null, '18', null, null);
UPDATE users SET id='0' WHERE username='admin'; 
INSERT INTO `locations` VALUES ('1', 'Global');

INSERT INTO `devices` VALUES ('2', '101', 'dynamic', '101', 'mor', '0.0.0.0', '0', '1175892667', '2', '\"101\" <101>', '101', '0', '101', 'IAX2', '2', '0', '1', '0', '0', 'no', 'all', 'all', '0.0.0.0/0.0.0.0', '0.0.0.0/0.0.0.0', 'yes', 'yes', '', 'no', null, 'rfc2833', null, null, null, null, 'no', 'no', 'no', 'never', 'no', 1, 'Test Device #1', 0);
INSERT INTO `devices` VALUES ('3', '102', 'dynamic', '102', 'mor', '0.0.0.0', '0', '1175892667', '3', '\"102\" <102>', '102', '0', '102', 'FAX', '2', '0', '1', '0', '0', 'no', 'all', 'all', '0.0.0.0/0.0.0.0', '0.0.0.0/0.0.0.0', 'yes', 'yes', '', 'no', null, 'rfc2833', null, null, null, null, 'no', 'no', 'no', 'never', 'no', 1, 'Test FAX device', 0);


#Kolmisoft

INSERT INTO `tariffs` VALUES ('1', 'Test Tariff', 'provider');
INSERT INTO `tariffs` VALUES ('2', 'Test Tariff for Users', 'user_wholesale');

INSERT INTO `devicecodecs` VALUES ('1', '1', '1');
INSERT INTO `devicecodecs` VALUES ('2', '1', '2');
INSERT INTO `devicecodecs` VALUES ('3', '1', '5');
INSERT INTO `devicecodecs` VALUES ('4', '1', '6');

INSERT INTO `providercodecs` VALUES ('1', '1', '1');
INSERT INTO `providercodecs` VALUES ('2', '1', '2');
INSERT INTO `providercodecs` VALUES ('3', '1', '5');
INSERT INTO `providercodecs` VALUES ('4', '1', '6');

INSERT INTO `providers` (id, name, tech, channel, login, password, server_ip, port, priority, quality, tariff_id, device_id) VALUES ('1', 'Test Provider', 'IAX2', '', 'test', 'test', '22.33.44.55', '4569', '1', '1', '1', '1');

INSERT INTO `devices` VALUES ('1', 'test', '22.33.44.55', 'test', 'mor', '22.33.44.55', '4569', '0', '1', '', 'prov_test', '0', 'test', 'IAX2', '-1', '0', '1', '0', '0', 'no', 'all', 'alaw;ulaw;g729;gsm', '0.0.0.0/0.0.0.0', '0.0.0.0/0.0.0.0', 'no', 'no', '', 'no', null, 'rfc2833', null, null, null, null, 'no', 'no', 'no', 'never', 'no', '1', '', 0);

