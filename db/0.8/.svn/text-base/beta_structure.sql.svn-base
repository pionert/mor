ALTER TABLE invoices ADD number_type TINYINT default 1 COMMENT 'invoice number format type';
CREATE INDEX resellerid ON calls(reseller_id);
CREATE INDEX extmainindex ON extlines(context,exten,priority);
ALTER TABLE recordings ADD local TINYINT default 1 COMMENT 'is recording saved on GUI server';
ALTER TABLE cardgroups ADD valid_after_first_use INT default 0 COMMENT 'how many days active after first use. 0 means not used - active forever.';
CREATE TABLE `flatrate_destinations` (  `id`             INTEGER NOT NULL auto_increment,  `service_id`     INTEGER NOT NULL COMMENT 'Foreign key to services table',  `destination_id` INTEGER NOT NULL COMMENT 'Foreign key to destination table',  `active`        TINYINT NOT NULL COMMENT '1 - This destination is included into flatrate service, 0 - destination is excluded',  INDEX service_id_index (`service_id`),  INDEX destination_id_index (`destination_id`),  PRIMARY KEY  (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE `flatrate_data` (  `id`              INTEGER      NOT NULL auto_increment,  `year_month`      VARCHAR(255) NOT NULL COMMENT 'Marks year and month for which minutes are counted',  `minutes`         INTEGER      NOT NULL COMMENT 'How many minutes user has already used',  `subscription_id` INTEGER      NOT NULL COMMENT 'Foreign key to subscriptions table',  PRIMARY KEY  (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE calls ADD did_billsec INT DEFAULT 0 COMMENT 'billsec for incoming call';
ALTER TABLE recordings ADD visible_to_dst_user TINYINT default 1 COMMENT 'is recording visible to dst user?';
ALTER TABLE vouchers ADD tax_id INTEGER NOT NULL default 0;
ALTER TABLE `vouchers` MODIFY COLUMN `vat_percent` DOUBLE  NOT NULL DEFAULT 0;
ALTER TABLE invoices ADD tax_id int(11) default NULL COMMENT 'Tax for invoice';
ALTER TABLE actions ADD COLUMN  `data3` varchar(255) default NULL;
ALTER TABLE actions ADD COLUMN  `data4` varchar(255) default NULL;
ALTER TABLE actions ADD INDEX `user_id_index`(`user_id`);
ALTER TABLE actions ADD INDEX `target_id_index`(`target_id`);
ALTER TABLE providers ADD COLUMN  `reg_line` varchar(255) default NULL;
ALTER TABLE taxes ADD compound_tax tinyint(4) default 1 COMMENT 'is this tax compound';
ALTER TABLE devices ADD INDEX `name_index`(`name`);
ALTER TABLE devices ADD record_forced TINYINT default 0 COMMENT 'Force recording for this device?';
ALTER TABLE cardgroups ADD tax_id INTEGER NOT NULL default 0; 
ALTER TABLE users ADD tax_id INTEGER NOT NULL default 0;
ALTER TABLE users ADD recordings_email varchar(50) default NULL;
ALTER TABLE users ADD recording_hdd_quota INT NOT NULL default 100;
ALTER TABLE adnumbers ADD INDEX number_index(number);
ALTER TABLE adnumbers ADD INDEX campaign_id_index(campaign_id);
ALTER TABLE dids ALTER language SET DEFAULT "";
CREATE INDEX did_index ON dids(did);
# ======== MOR 9 AFTER THIS LINE ==========
CREATE TABLE `cc_gmps` ( `id` int(11) NOT NULL auto_increment, `cardgroup_id` int(11) NOT NULL, `prefix` varchar(255) NOT NULL, `percent` int(11) NOT NULL default '100',  PRIMARY KEY  (`id`)  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# SQL sentences goes to the top ^^^^^ from this line
# make sure you press ENTER (to end line) after last SQL sentence!
# also whole SQL sentence should go into one line

# ------------ DO NOT WRITE NOTHING PAST THIS LINE ---------------
