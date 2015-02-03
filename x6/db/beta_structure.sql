ALTER TABLE `rates` ADD COLUMN `prefix` VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE rates ADD INDEX prefix_index (prefix);
ALTER TABLE `rates` ADD COLUMN `name` VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE invoices ADD COLUMN `timezone` varchar(255) NOT NULL DEFAULT 'UTC';
ALTER TABLE invoices ADD COLUMN `client_name` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details1` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details2` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details3` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details4` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details5` varchar(255) DEFAULT NULL;
ALTER TABLE invoices ADD COLUMN `client_details6` varchar(255) DEFAULT NULL;
CREATE TABLE `invoice_lines` ( `id` SERIAL, `invoice_id` INT(11) UNSIGNED DEFAULT NULL, `destination` VARCHAR(50) DEFAULT NULL, `service` VARCHAR(128) DEFAULT NULL, `units` INT(50) UNSIGNED DEFAULT NULL, `total_time` INT(50) UNSIGNED DEFAULT NULL, `price` DECIMAL(30,15) DEFAULT '0.000000000000000', PRIMARY KEY  (`id`), KEY `invoice_id_index` (`invoice_id`)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `daily_currencies` (`id` BIGINT(20) unsigned NOT NULL AUTO_INCREMENT, `added` DATE DEFAULT NULL, `AED` DECIMAL(30,15) DEFAULT 1, `ALL` DECIMAL(30,15) DEFAULT 1, `AMD` DECIMAL(30,15) DEFAULT 1, `ANG` DECIMAL(30,15) DEFAULT 1, `ARS` DECIMAL(30,15) DEFAULT 1, `AUD` DECIMAL(30,15) DEFAULT 1, `AWG` DECIMAL(30,15) DEFAULT 1, `BBD` DECIMAL(30,15) DEFAULT 1, `BDT` DECIMAL(30,15) DEFAULT 1, `BGN` DECIMAL(30,15) DEFAULT 1, `BHD` DECIMAL(30,15) DEFAULT 1, `BMD` DECIMAL(30,15) DEFAULT 1, `BND` DECIMAL(30,15) DEFAULT 1, `BOB` DECIMAL(30,15) DEFAULT 1, `BRL` DECIMAL(30,15) DEFAULT 1, `BTN` DECIMAL(30,15) DEFAULT 1, `BWP` DECIMAL(30,15) DEFAULT 1, `BZD` DECIMAL(30,15) DEFAULT 1, `CAD` DECIMAL(30,15) DEFAULT 1, `CHF` DECIMAL(30,15) DEFAULT 1, `CLP` DECIMAL(30,15) DEFAULT 1, `CNY` DECIMAL(30,15) DEFAULT 1, `COP` DECIMAL(30,15) DEFAULT 1, `CRC` DECIMAL(30,15) DEFAULT 1, `CUP` DECIMAL(30,15) DEFAULT 1, `CVE` DECIMAL(30,15) DEFAULT 1, `CZK` DECIMAL(30,15) DEFAULT 1, `DJF` DECIMAL(30,15) DEFAULT 1, `DKK` DECIMAL(30,15) DEFAULT 1, `DOP` DECIMAL(30,15) DEFAULT 1, `DZD` DECIMAL(30,15) DEFAULT 1, `EGP` DECIMAL(30,15) DEFAULT 1, `ETB` DECIMAL(30,15) DEFAULT 1, `EUR` DECIMAL(30,15) DEFAULT 1, `FJD` DECIMAL(30,15) DEFAULT 1, `GBP` DECIMAL(30,15) DEFAULT 1, `GEL` DECIMAL(30,15) DEFAULT 1, `GHS` DECIMAL(30,15) DEFAULT 1, `GIP` DECIMAL(30,15) DEFAULT 1, `GMD` DECIMAL(30,15) DEFAULT 1, `GNF` DECIMAL(30,15) DEFAULT 1, `GTQ` DECIMAL(30,15) DEFAULT 1, `GYD` DECIMAL(30,15) DEFAULT 1, `HKD` DECIMAL(30,15) DEFAULT 1, `HNL` DECIMAL(30,15) DEFAULT 1, `HRK` DECIMAL(30,15) DEFAULT 1, `HTG` DECIMAL(30,15) DEFAULT 1, `HUF` DECIMAL(30,15) DEFAULT 1, `IDR` DECIMAL(30,15) DEFAULT 1, `IEP` DECIMAL(30,15) DEFAULT 1, `ILS` DECIMAL(30,15) DEFAULT 1, `INR` DECIMAL(30,15) DEFAULT 1, `ISK` DECIMAL(30,15) DEFAULT 1, `JMD` DECIMAL(30,15) DEFAULT 1, `JOD` DECIMAL(30,15) DEFAULT 1, `JPY` DECIMAL(30,15) DEFAULT 1, `KES` DECIMAL(30,15) DEFAULT 1, `KHR` DECIMAL(30,15) DEFAULT 1, `KMF` DECIMAL(30,15) DEFAULT 1, `KRW` DECIMAL(30,15) DEFAULT 1, `KWD` DECIMAL(30,15) DEFAULT 1, `KYD` DECIMAL(30,15) DEFAULT 1, `KZT` DECIMAL(30,15) DEFAULT 1, `LAK` DECIMAL(30,15) DEFAULT 1, `LBP` DECIMAL(30,15) DEFAULT 1, `LKR` DECIMAL(30,15) DEFAULT 1, `LSL` DECIMAL(30,15) DEFAULT 1, `LTL` DECIMAL(30,15) DEFAULT 1, `LVL` DECIMAL(30,15) DEFAULT 1, `LYD` DECIMAL(30,15) DEFAULT 1, `MAD` DECIMAL(30,15) DEFAULT 1, `MDL` DECIMAL(30,15) DEFAULT 1, `MGA` DECIMAL(30,15) DEFAULT 1, `MMK` DECIMAL(30,15) DEFAULT 1, `MNT` DECIMAL(30,15) DEFAULT 1, `MRO` DECIMAL(30,15) DEFAULT 1, `MUR` DECIMAL(30,15) DEFAULT 1, `MVR` DECIMAL(30,15) DEFAULT 1, `MWK` DECIMAL(30,15) DEFAULT 1, `MXN` DECIMAL(30,15) DEFAULT 1, `MYR` DECIMAL(30,15) DEFAULT 1, `MZN` DECIMAL(30,15) DEFAULT 1, `NAD` DECIMAL(30,15) DEFAULT 1, `NGN` DECIMAL(30,15) DEFAULT 1, `NIO` DECIMAL(30,15) DEFAULT 1, `NOK` DECIMAL(30,15) DEFAULT 1, `NPR` DECIMAL(30,15) DEFAULT 1, `NZD` DECIMAL(30,15) DEFAULT 1, `OMR` DECIMAL(30,15) DEFAULT 1, `PEN` DECIMAL(30,15) DEFAULT 1, `PGK` DECIMAL(30,15) DEFAULT 1, `PHP` DECIMAL(30,15) DEFAULT 1, `PKR` DECIMAL(30,15) DEFAULT 1, `PLN` DECIMAL(30,15) DEFAULT 1, `PYG` DECIMAL(30,15) DEFAULT 1, `QAR` DECIMAL(30,15) DEFAULT 1, `RON` DECIMAL(30,15) DEFAULT 1, `RUB` DECIMAL(30,15) DEFAULT 1, `SAR` DECIMAL(30,15) DEFAULT 1, `SBD` DECIMAL(30,15) DEFAULT 1, `SCR` DECIMAL(30,15) DEFAULT 1, `SDG` DECIMAL(30,15) DEFAULT 1, `SEK` DECIMAL(30,15) DEFAULT 1, `SGD` DECIMAL(30,15) DEFAULT 1, `SHP` DECIMAL(30,15) DEFAULT 1, `SLL` DECIMAL(30,15) DEFAULT 1, `SRD` DECIMAL(30,15) DEFAULT 1, `STD` DECIMAL(30,15) DEFAULT 1, `SVC` DECIMAL(30,15) DEFAULT 1, `SYP` DECIMAL(30,15) DEFAULT 1, `SZL` DECIMAL(30,15) DEFAULT 1, `THB` DECIMAL(30,15) DEFAULT 1, `TND` DECIMAL(30,15) DEFAULT 1, `TOP` DECIMAL(30,15) DEFAULT 1, `TRY` DECIMAL(30,15) DEFAULT 1, `TTD` DECIMAL(30,15) DEFAULT 1, `TWD` DECIMAL(30,15) DEFAULT 1, `TZS` DECIMAL(30,15) DEFAULT 1, `UAH` DECIMAL(30,15) DEFAULT 1, `UGX` DECIMAL(30,15) DEFAULT 1, `USD` DECIMAL(30,15) DEFAULT 1, `VEF` DECIMAL(30,15) DEFAULT 1, `VND` DECIMAL(30,15) DEFAULT 1, `VUV` DECIMAL(30,15) DEFAULT 1, `WST` DECIMAL(30,15) DEFAULT 1, `XAF` DECIMAL(30,15) DEFAULT 1, `XCD` DECIMAL(30,15) DEFAULT 1, `XOF` DECIMAL(30,15) DEFAULT 1, `XPF` DECIMAL(30,15) DEFAULT 1, `ZAR` DECIMAL(30,15) DEFAULT 1, `ZMW` DECIMAL(30,15) DEFAULT 1, `ZWL` DECIMAL(30,15) DEFAULT 1, PRIMARY KEY (`id`), KEY `added_index` (`added`)) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
CREATE TABLE IF NOT EXISTS `partner_groups` (`id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT, `name` VARCHAR(255) NOT NULL DEFAULT '', `comment` TEXT, UNIQUE (name)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `partner_group_rights` (`id` int(11) NOT NULL AUTO_INCREMENT, `partner_group_id` int(11) NOT NULL, `partner_right_id` int(11) NOT NULL, `value` tinyint(4) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `partner_rights` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL DEFAULT '', `nice_name` varchar(255) NOT NULL DEFAULT '', PRIMARY KEY (`id`), UNIQUE KEY `name` (`name`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE users ADD COLUMN partner_group_id INT NOT NULL DEFAULT 0;
ALTER TABLE servers MODIFY COLUMN server_type enum ('asterisk', 'sip_proxy', 'other') NOT NULL DEFAULT 'asterisk';
ALTER TABLE callflows ADD data5 INTEGER;
ALTER TABLE queues ADD pbx_pool_id int(11) NOT NULL DEFAULT 1;
ALTER TABLE ringgroups ADD COLUMN pbx_pools_id int(11) DEFAULT 1;
CREATE TABLE IF NOT EXISTS `transfers` (`id` int(11) NOT NULL AUTO_INCREMENT, `transfer_date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00', `uniqueid` varchar(64) NOT NULL, PRIMARY KEY (`id`), KEY `transfer_date_index` (`transfer_date`), KEY `uniqueid_index` (`uniqueid`)) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
ALTER TABLE addresses DROP INDEX unique_email;
ALTER TABLE time_periods ADD COLUMN last_call_id BIGINT(11) UNSIGNED DEFAULT NULL;
ALTER TABLE invoice_lines ADD COLUMN invdet_type tinyint DEFAULT 1;
ALTER TABLE invoicedetails ADD COLUMN prefix VARCHAR(50) DEFAULT NULL;
ALTER TABLE invoicedetails ADD COLUMN total_time INT(50) UNSIGNED DEFAULT NULL;
ALTER TABLE devices ADD inherit_codec int(11) DEFAULT NULL;
CREATE TABLE IF NOT EXISTS `call_details_old` (`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,`call_id` bigint(20) DEFAULT NULL,`pdd` decimal(30,15) DEFAULT '0.000000000000000',`la_ip` int(11) DEFAULT NULL,`la_local_ip` int(11) DEFAULT NULL,`la_codec` int(11) DEFAULT NULL,`la_rtt` decimal(30,15) DEFAULT '0.000000000000000',`la_r` int(11) DEFAULT NULL,`la_mos` decimal(30,15) DEFAULT '0.000000000000000',`la_rxcount` int(11) DEFAULT NULL,`la_lp` int(11) DEFAULT NULL,`la_rxjitter` decimal(30,15) DEFAULT '0.000000000000000',`la_r_r` int(11) DEFAULT NULL,`la_r_mos` decimal(30,15) DEFAULT '0.000000000000000',`la_tx_count` int(11) DEFAULT NULL,`la_rlp` int(11) DEFAULT NULL,`la_txjitter` decimal(30,15) DEFAULT '0.000000000000000',`la_t_r` int(11) DEFAULT NULL,`la_t_mos` decimal(30,15) DEFAULT '0.000000000000000',`lb_ip` int(11) DEFAULT NULL,`lb_local_ip` int(11) DEFAULT NULL,`lb_codec` tinyint(4) DEFAULT NULL,`lb_rtt` decimal(30,15) DEFAULT '0.000000000000000',`lb_r` int(11) DEFAULT NULL,`lb_mos` decimal(30,15) DEFAULT '0.000000000000000',`lb_rxcount` int(11) DEFAULT NULL,`lb_lp` int(11) DEFAULT NULL,`lb_rxjitter` decimal(30,15) DEFAULT '0.000000000000000',`lb_r_r` int(11) DEFAULT NULL,`lb_r_mos` decimal(30,15) DEFAULT '0.000000000000000',`lb_txcount` int(11) DEFAULT NULL,`lb_rlp` int(11) DEFAULT NULL,`lb_txjitter` decimal(30,15) DEFAULT '0.000000000000000',`lb_t_r` int(11) DEFAULT NULL,`lb_t_mos` decimal(30,15) DEFAULT '0.000000000000000',`peerip` int(10) unsigned DEFAULT NULL,`recvip` int(10) unsigned DEFAULT NULL,`sipfrom` varchar(255) DEFAULT NULL,`uri` varchar(255) DEFAULT NULL,`useragent` varchar(255) DEFAULT NULL,`peername` varchar(255) DEFAULT NULL,`t38passthrough` tinyint(4) DEFAULT NULL,PRIMARY KEY (`id`)) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
ALTER TABLE users ADD COLUMN enable_static_list enum('no', 'blacklist', 'whitelist') NOT NULL DEFAULT 'no';
ALTER TABLE users ADD static_list_id int(11) DEFAULT NULL;
## SQL sentences goes to the top ^^^^^ from this line
# make sure you press ENTER (to end line) after last SQL sentence!
# also whole SQL sentence should go into one line
# marking that DB is updated from script
