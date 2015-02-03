
USE mor;

ALTER TABLE lcrproviders ADD COLUMN priority int(11) default 1;

ALTER TABLE activecalls ADD COLUMN provider_id int(11) default NULL;
ALTER TABLE users ADD COLUMN uniquehash varchar(10) default NULL;
ALTER TABLE payments ADD COLUMN owner_id int(11) default 0;

ALTER TABLE conflines DROP  KEY  `uname`;
ALTER TABLE conflines ADD COLUMN owner_id int(11) default 0;

ALTER TABLE locationrules ADD COLUMN lr_type enum('dst','src') default 'dst';
ALTER TABLE providerrules ADD COLUMN pr_type enum('dst','src') default 'dst';
ALTER TABLE payments ADD COLUMN card tinyint(4) default 0;

DROP TABLE IF EXISTS `shortnumbers`;
ALTER TABLE pbxfunctions ADD COLUMN pf_type varchar(20);
INSERT INTO pbxfunctions (id, name, pf_type, context, extension, priority) VALUES (1, 'Tell balance',  'tell_balance', 'mor_pbxfunctions', 1, 1);

INSERT INTO conflines (name, value) VALUES ('AD_Sounds_Folder', '/home/mor/public/ad_sounds');

ALTER TABLE devices ADD COLUMN promiscredir enum('yes','no') default 'no';

#MOR PRO 0.6.pre6

INSERT INTO conflines (name, value) VALUES ('Greetings_Folder', '/home/mor/public/c2c_greetings');


#INSERT INTO conflines (name, value) VALUES ('CSV_Separator', ',');

ALTER TABLE devices MODIFY device_type varchar(20);
INSERT INTO devicetypes (name, ast_name) VALUES ('Virtual', 'Virtual');

INSERT INTO conflines (name, value) VALUES ('Temp_Dir', '/tmp/');
INSERT INTO conflines (name, value) VALUES ('Greetings_Folder', '/home/mor/public/c2c_greetings');


INSERT INTO conflines (name, value) VALUES ('Device_Range_MIN', '1001');
INSERT INTO conflines (name, value) VALUES ('Device_Range_MAX', '9999');

ALTER TABLE devices ADD COLUMN timeout int(11) DEFAULT 60;

ALTER TABLE devices ADD COLUMN process_sipchaninfo tinyint(4) DEFAULT 0;

ALTER TABLE calls ADD COLUMN peerip varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN recvip varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN sipfrom varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN uri varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN useragent varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN peername varchar(255) DEFAULT NULL;
ALTER TABLE calls ADD COLUMN t38passthrough tinyint(4) DEFAULT NULL;

ALTER TABLE providers ADD COLUMN timeout int(11) DEFAULT 60;

INSERT INTO conflines (name, value) VALUES ("WebMoney_Enabled", "1");
INSERT INTO conflines (name, value) VALUES ("WebMoney_Default_Currency", "USD");
INSERT INTO conflines (name, value) VALUES ("WebMoney_Min_Amount", "5");
INSERT INTO conflines (name, value) VALUES ("WebMoney_Default_Amount", "10");
INSERT INTO conflines (name, value) VALUES ("WebMoney_Test", "1");
INSERT INTO conflines (name, value) VALUES ("WebMoney_Purse", "Z616776332783");
INSERT INTO conflines (name, value) VALUES ("WebMoney_SIM_MODE", "0");
ALTER TABLE payments ADD COLUMN hash varchar(32);
ALTER TABLE payments ADD COLUMN bill_nr varchar(255);

# VM settings

INSERT INTO conflines (name, value) VALUES ('VM_Server_Active', '0');
INSERT INTO conflines (name, value) VALUES ('VM_Server_Device_ID', '');
INSERT INTO conflines (name, value) VALUES ('VM_Server_Retrieve_Extension', '*97');
INSERT INTO conflines (name, value) VALUES ('VM_Retrieve_Extension', '*97');



#Click2Call Addon

DROP TABLE IF EXISTS `c2c_campaigns`;
CREATE TABLE `c2c_campaigns` (
    `id` int(11) NOT NULL auto_increment,
    `name` varchar(255) default NULL,
    `description` varchar(255) default NULL,
    `user_id` int(11) default NULL,
    `device_id` int(11) default NULL,
    `first_dial` enum('company','client') NOT NULL default 'client',
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
             
DROP TABLE IF EXISTS `c2c_commfields`;
CREATE TABLE `c2c_commfields` (
  `id` int(11) NOT NULL auto_increment,
    `name` varchar(255) default NULL,
      `description` varchar(255) default NULL,
        `c2c_campaign_id` int(11) NOT NULL,
          `commenttype` enum('checkbox','textarea','text') default 'text',
            `commentorder` int(11) NOT NULL default '99',
              PRIMARY KEY  (`id`)
              ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
              
              ALTER TABLE users ADD COLUMN c2c_service_active tinyint(4) DEFAULT 0;
              
              DROP TABLE IF EXISTS `c2c_calls`;
              CREATE TABLE `c2c_calls` (
                `id` int(11) NOT NULL auto_increment,
                  `c2c_campaign_id` int(11) NOT NULL,
                    `client_number` varchar(255) default NULL,
                      `client_call_id` int(11) default NULL,
                        `company_call_id` int(11) default NULL,
                          `calldate` datetime default NULL,
                            `processed` tinyint(4) default 0,
                              PRIMARY KEY  (`id`)
                              ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `c2c_comments`;
CREATE TABLE `c2c_comments` (
  `id` int(11) NOT NULL auto_increment,
    `c2c_commfield_id` int(11) default NULL,
      `c2c_call_id` int(11) default NULL,
        `value` varchar(255) default NULL,
	  PRIMARY KEY  (`id`)
	  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	                                                                            