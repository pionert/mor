
USE mor;




CREATE TABLE `quickforwarddids` (
    `id` int(11) NOT NULL auto_increment,
    `did_id` int(11) default NULL,
    `user_id` int(11) default NULL,
    `number` varchar(255) default NULL,
    `description` varchar(255) default NULL,
PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO dialplans (name, dptype) VALUES ('Quick Forward DIDs DP', 'quickforwarddids');
	    


INSERT INTO codecs (name, long_name, codec_type) VALUES ('h264', 'H.264 Video', 'video');

#Fuguphone

CREATE TABLE `activecalls` (
    `id` bigint(11) NOT NULL auto_increment,
    `server_id` int(11) default NULL,
    `uniqueid` varchar(255) default NULL,
    `start_time` datetime default NULL,
    `answer_time` datetime default NULL,
    `transfer_time` datetime default NULL,
    `src` varchar(255) default NULL,
    `dst` varchar(255) default NULL,
    `src_device_id` int(11) default NULL,
    `dst_device_id` int(11) default NULL,
    `channel` varchar(255) default NULL,
    `dstchannel` varchar(255) default NULL,
    `prefix` varchar(255) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			    
			    
ALTER TABLE calls ADD COLUMN server_id int(11) DEFAULT 1;
			    

ALTER TABLE calls ADD COLUMN hangupcause int(11) DEFAULT NULL;
ALTER TABLE tariffs ADD COLUMN owner_id int(11) DEFAULT 0;
ALTER TABLE users ADD COLUMN owner_id int(11) DEFAULT 0;

CREATE TABLE `shortnumbers` (
    `id` int(11) NOT NULL auto_increment,
    `extension` varchar(255) default NULL,
    `pbxfunction_id` int(11) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `pbxfunctions` (
    `id` int(11) NOT NULL auto_increment,
    `name` varchar(255) default NULL,
    `context` varchar(255) default NULL,
    `extension` varchar(255) default NULL,
    `priority` int(11) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	    
ALTER TABLE devices ADD COLUMN cid_from_dids tinyint(4) DEFAULT 0;
	

ALTER TABLE users ADD COLUMN hidden tinyint(4) DEFAULT 0;

ALTER TABLE invoicedetails ADD COLUMN invdet_type tinyint(4) DEFAULT 1;
UPDATE invoicedetails SET invdet_type = 0 WHERE name LIKE 'Calls%';

ALTER TABLE users ADD COLUMN allow_loss_calls int(11) DEFAULT 0;

DROP TABLE IF EXISTS `emails`;
CREATE TABLE `emails` (              
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,      
  `subject` varchar(255) NOT NULL,   
  `date_created` datetime NOT NULL,  
  `body` blob NOT NULL,   
  PRIMARY KEY  (`id`)                
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO `emails` (`id`, `name`, `subject`, `date_created`, `body`) VALUES 
(1, 'registration_confirmation_for_user', 'Thank you for registering!', '2007-10-29 16:55:22', 0x596f75206465766963652073657474696e67733a200d0a0d0a5365727665722049503a203c253d207365727665725f697020253e0d0a44657669636520747970653a203c253d206465766963655f7479706520253e0d0a557365726e616d653a203c253d206465766963655f757365726e616d6520253e0d0a50617373776f72643a203c253d206465766963655f70617373776f726420253e0d0a0d0a2d2d2d2d0d0a0d0a53657474696e677320746f206c6f67696e20746f204d4f5220696e746572666163653a0d0a0d0a4c6f67696e2055524c3a203c253d206c6f67696e5f75726c20253e0d0a557365726e616d653a203c253d206c6f67696e5f757365726e616d6520253e0d0a50617373776f72643a203c253d206c6f67696e5f70617373776f726420253e0d0a0d0a5468616e6b20796f7520666f72207265676973746572696e6721),
(2, 'registration_confirmation_for_admin', 'New user registered', '2007-10-29 16:55:51', 0x557365722073657474696e67733a200d0a0d0a557365723a0d0a4669727374204e616d652f436f6d70616e793a203c253d2066697273745f6e616d6520253e0d0a4c617374204e616d653a203c253d206c6173745f6e616d6520253e0d0a0d0a4465766963652073657474696e67730d0a0d0a44657669636520747970653a203c253d206465766963655f7479706520253e0d0a557365726e616d653a203c253d206465766963655f757365726e616d6520253e0d0a50617373776f72643a203c253d206465766963655f70617373776f726420253e0d0a0d0a53657474696e677320746f206c6f67696e20746f204d4f5220696e746572666163650d0a0d0a557365726e616d653a203c253d206c6f67696e5f757365726e616d6520253e0d0a50617373776f72643a203c253d206c6f67696e5f70617373776f726420253e);


ALTER TABLE emails ADD COLUMN template tinyint(4) DEFAULT 0;
UPDATE emails SET template = 1 WHERE name LIKE 'registration%';


#config table
CREATE TABLE `conflines` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `uname` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `translations` (              
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,      
  `native_name` varchar(255) NOT NULL,   
  `short_name` varchar(255) NOT NULL,   
  `position` int(11) NOT NULL,
  `active` tinyint(4) default '1',
  `flag` varchar(255) NOT NULL,   
  PRIMARY KEY  (`id`)                
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('English','','en','1','gbr');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Lithuanian','','lt','2','ltu');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Spanish','','es','3','esp');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Dutch','Nederlands','nl','4','nld');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Italian','Italiano','it','5','ita');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Albanian','Gjuha shqipe','al','6','alb');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Russian','','ru','7','rus');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Brazilian Portuguese','','pt','8','bra');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Estonian','Eesti','et','9','est');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Bulgarian','','bg','10','bgr');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Swedish','Svenska','se','11','swe');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('German','Deutch','de','12','deu');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Armenian','','am','13','arm');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('French','','fr','14','fra');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Polish','Polski','pl','15','pol');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Romanian','','ro','16','rom');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Turkish','','tr','17','tur');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Indonesian','Bahasa Indonesia','id','18','idn');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Hungarian','Magyar','hu','19','hun');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Slovenian','Slovene','sl','100','svn');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Greek','','gr','101','grc');

INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Australian English','','au','102','aus');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Serbian','Srpski','sr','103','scg');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Belarussian','','by','104','blr');

INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Arabic','','ar','105','ara');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Macedonian','Makedonski','mk','106','mkd');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Chinese','','zn','107','chn');

INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Urdu','','ur','108','pak');
INSERT INTO translations (name, native_name, short_name, position, flag) VALUES ('Latvian','','lv','109','lva');


INSERT INTO conflines (name, value) VALUES ('CSV_Separator', ','); 
INSERT INTO conflines (name, value) VALUES ('WEB_Callback_CID', '');

INSERT INTO conflines (name, value) VALUES ('AMI_Host', '127.0.0.1');
INSERT INTO conflines (name, value) VALUES ('AMI_Username', 'mor');
INSERT INTO conflines (name, value) VALUES ('AMI_Secret', 'morsecret');


INSERT INTO conflines (name, value) VALUES ('Reg_allow_user_enter_vat', '0');


INSERT INTO conflines (name, value) VALUES ('Company', 'KolmiSoft');
INSERT INTO conflines (name, value) VALUES ('Logo_Picture', 'logo/mor_logo.png');
INSERT INTO conflines (name, value) VALUES ('Company_Email', 'kolmitest@gmail.com');

INSERT INTO conflines (name, value) VALUES ('Days_for_did_close', '90');

INSERT INTO conflines (name, value) VALUES ('Version', 'MOR 0.7');
INSERT INTO conflines (name, value) VALUES ('Copyright_Title', ' by <a href=\'http://www.kolmisoft.com\' target=\"_blank\">KolmiSoft </a> 2006-2008');

INSERT INTO conflines (name, value) VALUES ('Invoice_Address1', 'Street Address');
INSERT INTO conflines (name, value) VALUES ('Invoice_Address2', 'City, Country');
INSERT INTO conflines (name, value) VALUES ('Invoice_Address3', 'Phone, fax');
INSERT INTO conflines (name, value) VALUES ('Invoice_Address4', 'Web, email');
INSERT INTO conflines (name, value) VALUES ('Invoice_Number_Start', 'INV');
INSERT INTO conflines (name, value) VALUES ('Invoice_Number_Length', '9');
INSERT INTO conflines (name, value) VALUES ('Invoice_Number_Type', '2');
INSERT INTO conflines (name, value) VALUES ('Invoice_Period_Start_Day', '01');
INSERT INTO conflines (name, value) VALUES ('Invoice_Show_Calls_In_Detailed', '1');
INSERT INTO conflines (name, value) VALUES ('Invoice_Bank_Details_Line1', 'Please make payments to:');
INSERT INTO conflines (name, value) VALUES ('Invoice_Bank_Details_Line2', 'Company name');
INSERT INTO conflines (name, value) VALUES ('Invoice_Bank_Details_Line3', 'Bank name');
INSERT INTO conflines (name, value) VALUES ('Invoice_Bank_Details_Line4', 'Bank account number');
INSERT INTO conflines (name, value) VALUES ('Invoice_Bank_Details_Line5', 'Add. info');
INSERT INTO conflines (name, value) VALUES ('Invoice_End_Title', 'Thank you for your business!');
INSERT INTO conflines (name, value) VALUES ('Invoice_Address_Format', '2');

INSERT INTO conflines (name, value) VALUES ('C2C_Active', '1');

INSERT INTO conflines (name, value) VALUES ('CB_Active', '1');
INSERT INTO conflines (name, value) VALUES ('CB_Temp_Dir', '/tmp');
INSERT INTO conflines (name, value) VALUES ('CB_Spool_Dir', '/var/spool/asterisk/outgoing');
INSERT INTO conflines (name, value) VALUES ('CB_MaxRetries', '0');
INSERT INTO conflines (name, value) VALUES ('CB_RetryTime', '10');
INSERT INTO conflines (name, value) VALUES ('CB_WaitTime', '20');

INSERT INTO conflines (name, value) VALUES ('Registration_enabled', '1');
INSERT INTO conflines (name, value) VALUES ('Tariff_for_registered_users', '2');
INSERT INTO conflines (name, value) VALUES ('LCR_for_registered_users', '1');
INSERT INTO conflines (name, value) VALUES ('Default_VAT_Percent', '18');
INSERT INTO conflines (name, value) VALUES ('Default_Country_ID', '123');
INSERT INTO conflines (name, value) VALUES ('Asterisk_Server_IP', '111.222.333.444');
INSERT INTO conflines (name, value) VALUES ('Default_CID_Name', '');
INSERT INTO conflines (name, value) VALUES ('Default_CID_Number', '');

INSERT INTO conflines (name, value) VALUES ('Paypal_Enabled', '1');
INSERT INTO conflines (name, value) VALUES ('PayPal_Email', '');
INSERT INTO conflines (name, value) VALUES ('PayPal_Default_Amount', '10');
INSERT INTO conflines (name, value) VALUES ('PayPal_Min_Amount', '5');
INSERT INTO conflines (name, value) VALUES ('PayPal_Test', '0');

INSERT INTO conflines (name, value) VALUES ('Change_Zap', '0');
INSERT INTO conflines (name, value) VALUES ('Change_Zap_to', 'PSTN');

INSERT INTO conflines (name, value) VALUES ('Vouchers_Enabled', '1');
INSERT INTO conflines (name, value) VALUES ('Voucher_Number_Length', '15');
INSERT INTO conflines (name, value) VALUES ('Voucher_Disable_Time', '60');
INSERT INTO conflines (name, value) VALUES ('Voucher_Attempts_to_Enter', '3');

INSERT INTO conflines (name, value) VALUES ('Send_Email_To_User_After_Registration', '1');
INSERT INTO conflines (name, value) VALUES ('Send_Email_To_Admin_After_Registration', '1');

INSERT INTO conflines (name, value) VALUES ('Active_Calls_Refresh_Interval', '5');



#0.4.7

INSERT INTO conflines (name, value) VALUES ('Email_Fax_From_Sender', 'fax@some.domain.com');

# 0.4.6 (tar)


INSERT INTO conflines (name, value) VALUES ('Items_Per_Page', '50');


INSERT INTO conflines (name, value) VALUES ('Nice_Number_Digits', '4');
INSERT INTO conflines (name, value) VALUES ('User_Wholesale_Enabled', '1');

ALTER TABLE cards ADD COLUMN  `frozen_balance` double default 0;

ALTER TABLE dialplans ADD COLUMN  `data1` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data2` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data3` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data4` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data5` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data6` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data7` varchar(255) default NULL;
ALTER TABLE dialplans ADD COLUMN  `data8` varchar(255) default NULL;


#VoiceMailMain
INSERT INTO `extlines` (context, exten, priority, app, appdata, device_id) VALUES ('mor', '*97', '1', 'AGI', 'mor_acc2user', '0');
INSERT INTO `extlines` (context, exten, priority, app, appdata, device_id) VALUES ('mor', '*97', '2', 'VoiceMailMain', 's${MOR_EXT}', '0');
INSERT INTO `extlines` (context, exten, priority, app, appdata, device_id) VALUES ('mor', '*97', '3', 'Hangup', '', '0');

INSERT INTO `extlines`(context, exten, priority, app, appdata, device_id)  VALUES ('mor', 'fax', '1', 'Goto', 'mor_fax2email|123|1', '0');

ALTER TABLE subscriptions ADD COLUMN  `memo` varchar(255) default NULL;

INSERT INTO conflines (name, value) VALUES ('Email_Sending_Enabled', '1');
INSERT INTO conflines (name, value) VALUES ('Fax_Device_Enabled', '1');

CREATE TABLE `pdffaxes` (
  `id` int(11) NOT NULL auto_increment,
    `device_id` int(11) default NULL,
      `filename` varchar(255) default NULL,
        `receive_time` datetime default NULL,
	  `size` int(11) default NULL,
	    `deleted` tinyint(4) default '0',
	      `uniqueid` varchar(255) default NULL,
	        `fax_sender` varchar(255) default NULL,
		  `status` varchar(255) default 'good',
		    PRIMARY KEY  (`id`)
		    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
		    
		    CREATE TABLE `pdffaxemails` (
		      `id` int(11) NOT NULL auto_increment,
		        `device_id` int(11) default NULL,
			  `email` varchar(255) default NULL,
			    PRIMARY KEY  (`id`)
			    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			    

ALTER TABLE devices ADD COLUMN  `pin` varchar(255) default NULL;


CREATE TABLE `sessions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `session_id` varchar(255) default NULL,
  `data` longtext,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE actions ADD COLUMN  `data2` varchar(255) default NULL;


INSERT INTO conflines (name, value) VALUES ('Agreement_Number_Length', '10');
INSERT INTO conflines (name, value) VALUES ('Paypal_Default_Currency', 'USD');

INSERT INTO conflines (name, value) VALUES ('Device_PIN_Length', '6');

INSERT INTO conflines (name, value) VALUES ('Admin_Browser_Title', 'MOR 0.7');

INSERT INTO conflines (name, value) VALUES ('Email_Batch_Size', '50');
INSERT INTO conflines (name, value) VALUES ('Email_Smtp_Server', 'smtp.gmail.com');
INSERT INTO conflines (name, value) VALUES ('Email_Domain', 'localhost.localdomain');
INSERT INTO conflines (name, value) VALUES ('Email_Login', 'kolmitest');
INSERT INTO conflines (name, value) VALUES ('Email_Password', 'kolmitest99');

ALTER TABLE lcrproviders ADD COLUMN `active` tinyint(4) NOT NULL default '1';

#Montenegro
#INSERT INTO directions (name, code) VALUES ('Montenegro', 'MBX');
#INSERT INTO destinationgroups (name, desttype, flag) VALUES ('Montenegro', 'FIX', 'mbx');
#INSERT INTO destinationgroups (name, desttype, flag) VALUES ('Montenegro', 'MOB', 'mbx');
#INSERT INTO destinations (prefix, direction_code, subcode, name, destinationgroup_id) VALUES ('382', 'MBX', 'FIX', '', (SELECT id FROM destinationgroups WHERE name = 'Montenegro' AND desttype='FIX' ));
#INSERT INTO destinations (prefix, direction_code, subcode, name, destinationgroup_id) VALUES ('3826', 'MBX', 'MOB', '', (SELECT id FROM destinationgroups WHERE name = 'Montenegro' AND desttype='MOB' ));


CREATE INDEX rd USING BTREE ON ratedetails(rate_id, daytype, start_time, end_time);

DROP TABLE IF EXISTS `providerrules`;

CREATE TABLE `providerrules` (
  `id` int(11) NOT NULL auto_increment,
  `provider_id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  `enabled` tinyint(4) NOT NULL default '1',
  `cut` varchar(255) default NULL,
  `add` varchar(255) default NULL,
  `minlen` int(11) NOT NULL default '1',
  `maxlen` int(11) NOT NULL default '100',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `callflows` (
  `id` int(11) NOT NULL auto_increment,
  `device_id` int(11) default NULL,
  `cf_type` varchar(255) default NULL,
  `priority` int(11) NOT NULL default '1',
  `action` varchar(255) default NULL,
  `data` varchar(255) default NULL,
  `data2` varchar(255) default NULL,
  `time_data` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE didrates ADD COLUMN `rate_type` varchar(20) default 'provider';
ALTER TABLE dids ADD COLUMN `language` varchar(10) default 'en';

ALTER TABLE users ADD COLUMN `vouchers_disabled_till` datetime default '2000-01-01 00:00:00';

ALTER TABLE devices ADD COLUMN `tell_balance` tinyint(4) NOT NULL default '0';
ALTER TABLE devices ADD COLUMN `tell_time` tinyint(4) NOT NULL default '0';
ALTER TABLE devices ADD COLUMN `tell_rtime_when_left` int(11) NOT NULL default '60';
ALTER TABLE devices ADD COLUMN `repeat_rtime_every` int(11) NOT NULL default '60';

ALTER TABLE devices ADD COLUMN `t38pt_udptl` varchar(255) default 'no';

ALTER TABLE payments ADD COLUMN `vat_percent` double NOT NULL default '0';

CREATE TABLE `vouchers` (
  `id` int(11) NOT NULL auto_increment,
  `number` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `credit_with_vat` double NOT NULL default '0',
  `vat_percent` double NOT NULL,
  `user_id` int(11) NOT NULL default '-1',
  `use_date` datetime default NULL,
  `active_till` datetime NOT NULL,
  `currency` varchar(255) NOT NULL,
  `payment_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE voicemail_boxes CHANGE id uniqueid INTEGER  NOT NULL auto_increment;

ALTER TABLE cardgroups ADD COLUMN `location_id` int(11) default '1';
ALTER TABLE devices ADD COLUMN `regserver` varchar(255);

#0.4.2

ALTER TABLE devices ADD COLUMN `ani` tinyint(4) default 0;
ALTER TABLE providers ADD COLUMN `ani` tinyint(4) default 0;

CREATE TABLE `callerids` (
  `id` int(11) NOT NULL auto_increment,
  `cli` varchar(255) default NULL,
  `device_id` int(11) default NULL,
  `description` varchar(255) default NULL,
  `added_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# ---- e.164 numbers - without int.prefix -----
UPDATE destinations SET prefix = CONCAT("", SUBSTRING(prefix,3,LENGTH(prefix))) WHERE SUBSTRING(prefix,1,2) = "00";

INSERT INTO `locationrules` VALUES ('1', '1', 'Int. prefix', '1', '00', '', '10', '20'); 

CREATE TABLE `currencies` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `full_name` varchar(255) default NULL,
  `exchange_rate` double NOT NULL default '1',
  `active` tinyint(4) NOT NULL default '1',
  `last_update` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `currencies` VALUES ('1', 'USD', 'United States dollar', '1', '1', CURRENT_TIMESTAMP);
INSERT INTO `currencies` VALUES ('2', 'EUR', 'Euro', '0.73853104', '1', CURRENT_TIMESTAMP);

ALTER TABLE tariffs ADD COLUMN `currency` varchar(255);
UPDATE tariffs SET currency = (SELECT name FROM currencies WHERE id = 1);

UPDATE users SET vat_percent = 0 WHERE vat_percent IS NULL;

ALTER TABLE dids ADD COLUMN `provider_id` int(11) default 0;
UPDATE dids SET provider_id = 1;
ALTER TABLE calls ADD COLUMN `callertype` enum('Local','Outside') default 'Local';

INSERT INTO `pdffaxemails` (`id`, `device_id`, `email`) VALUES (1, 3, 'mkezys@gmail.com');
