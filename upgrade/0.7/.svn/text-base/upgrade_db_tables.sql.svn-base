
#################### MOR PRO 0.7 ############################

# --------------- CREATE TABLES -----------------


CREATE TABLE IF NOT EXISTS `servers` (
  `id` int(11) NOT NULL auto_increment,
  `server_ip` varchar(255) NOT NULL,
  `stats_url` varchar(255) default NULL,
  `server_type` varchar(255) default NULL,
  `active` tinyint(4) default '0',
  `comment` varchar(255) default NULL,
  `hostname` varchar(255) default NULL,
  `maxcalllimit` int(11) default '1000',
  `server_id` int(11) default '1',
  `ami_port` varchar(255) default '5038',
  `ami_secret` varchar(255) default 'morsecret',
  `ami_username` varchar(255) default 'mor',
  PRIMARY KEY  (`id`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8;
		

CREATE TABLE IF NOT EXISTS `serverproviders` (
  `id` int(11) NOT NULL auto_increment,
  `server_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `hangupcausecodes` (
  `id` int(11) NOT NULL auto_increment,
  `code` int(11) NOT NULL,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8; 



# -- new permission system --

CREATE TABLE IF NOT EXISTS `roles` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `roles_name_index` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `rights` (
  `id` int(11) NOT NULL auto_increment,
  `controller` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `saved` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `rights_controller_index` (`controller`),
  KEY `rights_action_index` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `role_rights` (
  `id` int(11) NOT NULL auto_increment,
  `role_id` int(11) NOT NULL,
  `right_id` int(11) NOT NULL,
  `permission` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `role_rights_index` (`role_id`,`right_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `iplocations` (
    `id` int(11) NOT NULL auto_increment,
    `ip` varchar(255) NOT NULL,
    `latitude` float NOT NULL,
    `longitude` float NOT NULL,
    `country` varchar(255) default NULL,
    `city` varchar(255) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


# c2c

CREATE TABLE IF NOT EXISTS `c2c_invoicedetails` (
    `id` int(11) NOT NULL auto_increment,
    `c2c_invoice_id` int(11) default NULL,
    `c2c_campaign_id` int(11) default NULL,
    `name` varchar(255) default NULL,
    `total_calls` int(11) default NULL,
    `price` double default NULL,
    `invdet_type` tinyint(4) default '1',
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `c2c_invoices` (
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
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


# --- IVR ---

CREATE TABLE IF NOT EXISTS `ivr_actions` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `ivr_block_id` int(11) NOT NULL,
  `data1` varchar(255) default NULL,
  `data2` varchar(255) default NULL,
  `data3` varchar(255) default NULL,
  `data4` varchar(255) default NULL,
  `data5` varchar(255) default NULL,
  `data6` varchar(255) default NULL,
  `order` int(11) default NULL,
  PRIMARY KEY  (`id`)
)ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS `ivr_extensions` (
  `id` INT(11)  NOT NULL AUTO_INCREMENT,
  `exten` VARCHAR(255)  NOT NULL,
  `goto_ivr_block_id` INT(11)  NOT NULL,
  `ivr_block_id` INT(11)  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS `ivr_blocks` (
  `id` INT(11)  NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255)  NOT NULL,
  `ivr_id` INT(11),
  `timeout_response` INT(11),
  `timeout_digits` INT(11),
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB CHARACTER SET utf8;

CREATE TABLE IF NOT EXISTS `ivrs` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `start_block_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
)
ENGINE = InnoDB CHARACTER SET utf8;

CREATE TABLE IF NOT EXISTS `ivr_timeperiods` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `start_hour` int(11) NOT NULL,
  `end_hour` int(11) NOT NULL,
  `start_minute` int(11) NOT NULL,
  `end_minute` int(11) NOT NULL,
  `start_weekday` varchar(3) default NULL,
  `end_weekday` varchar(3) default NULL,
  `start_day` int(11) default NULL,
  `end_day` int(11) default NULL,
  `start_month` int(11) default NULL,
  `end_month` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS `ivr_sound_files` (
  `id` int(11) NOT NULL auto_increment,
  `ivr_voice_id` varchar(255) NOT NULL,
  `path` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `created_at` datetime default NULL,
  `size` int(11) default '0',
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ivr_voices` (
 `id` int(11) NOT NULL auto_increment,
  `voice` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `backups` (
    `id` INT(11)  NOT NULL AUTO_INCREMENT,
    `backuptime`  varchar(255) default NULL,
    `comment`   varchar(255) default NULL,
    `backuptype`  varchar(255) default NULL,
    PRIMARY KEY(`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS `lcr_partials` (
    `id`  INT(11)  NOT NULL AUTO_INCREMENT,
    `main_lcr_id` int(11) NOT NULL,
    `prefix` varchar(255) NOT NULL,
    `lcr_id` int(11) NOT NULL,
    PRIMARY KEY(`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


# --------------- DROP TABLES -----------------

