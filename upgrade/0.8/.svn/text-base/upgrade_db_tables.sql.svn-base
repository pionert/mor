
#################### MOR 0.8 ############################

# --------------- CREATE TABLES -----------------


CREATE TABLE IF NOT EXISTS `gateways` (
    id int(11) NOT NULL auto_increment COMMENT 'Unique ID',
    setid int(11) NOT NULL default '1' COMMENT 'Destination Set ID',
    destination varchar(192) NOT NULL default 'sip:' COMMENT 'Destination SIP Address',
    description varchar(255) COMMENT 'Description for this Destination',
    server_id int(11) NOT NULL DEFAULT '1',
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;


#-------------------- SMS ---------------------------------

CREATE TABLE IF NOT EXISTS  `sms_providers` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `login` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `api_id` int(11) default NULL,
  `priority` int(11) default NULL,
  `sms_tariff_id` int(11) default NULL,
  `provider_type` varchar(255) default NULL,
  `sms_provider_domain` varchar(255) default NULL,
  `use_subject` varchar(255) default NULL,
  `sms_subject` varchar(255) default NULL,
  `sms_email_wait_time` varchar(255) default '0',
  `wait_for_good_email` int(11) default '0',
  `email_good_keywords` varchar(255) default NULL,
  `wait_for_bad_email` int(11) default '0',
  `email_bad_keywords` varchar(255) default NULL,
  `time_out_charge_user` int(11) default '0',
  `nan_keywords_charge_user` int(11) default '0',
  `pay_sms_receiver` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



CREATE TABLE IF NOT EXISTS  `sms_lcrproviders` (
  `id` INT(11)  NOT NULL AUTO_INCREMENT,
  `sms_lcr_id`  INT(11)  NOT NULL,
  `sms_provider_id`  INT(11)  NOT NULL,
  `active`  INT(11)  default '1',
  `priority`  INT(11)  default '1',
  PRIMARY KEY(`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS  `sms_lcrs` (
  `id` INT(11)  NOT NULL AUTO_INCREMENT,
  `name`  varchar(255) default NULL,
  `order`  varchar(255) default 'price',
  PRIMARY KEY(`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS  `sms_messages` (
  `id` INT(11)  NOT NULL AUTO_INCREMENT,
  `sending_date` datetime DEFAULT NULL,
  `status_code`  varchar(255) default NULL,
  `provider_id` INT(11),
  `provider_rate` double default '0',
  `provider_price` double default '0',
  `user_id` INT(11),
  `user_rate` double default '0',
  `user_price` double default '0',
  `reseller_id` INT(11)  default '0',
  `reseller_rate` double default '0',
  `reseller_price` double default '0',
  `prefix`  varchar(255) default NULL,
  `number`  varchar(255) default NULL,
  `clickatell_message_id`  varchar(255) default NULL,
  PRIMARY KEY(`id`)
) ENGINE = InnoDB CHARACTER SET utf8;


CREATE TABLE IF NOT EXISTS  `sms_tariffs` (
  `id` int(11) NOT NULL auto_increment,
  `name`  VARCHAR(255),
  `tariff_type`  VARCHAR(255),
  `owner_id` INT(11)  default '0',
  `currency`  VARCHAR(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS  `sms_rates` (
  `id` int(11) NOT NULL auto_increment,
  `prefix` varchar(255) default NULL,
  `price` double NOT NULL default '0',
  `sms_tariff_id`  int(11),
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS  `terminators` (
    `id` int(11)        NOT NULL auto_increment,
    `name` varchar(255) NOT NULL default "",
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `taxes` (
  `id`             INTEGER      NOT NULL AUTO_INCREMENT,
  `tax1_enabled`   TINYINT      NOT NULL DEFAULT '0' COMMENT 'Shows if tax is enabled',
  `tax2_enabled`   TINYINT      NOT NULL DEFAULT '0'COMMENT 'Shows if tax is enabled',
  `tax3_enabled`   TINYINT      NOT NULL DEFAULT '0'COMMENT 'Shows if tax is enabled',
  `tax4_enabled`   TINYINT      NOT NULL DEFAULT '0'COMMENT 'Shows if tax is enabled',
  `tax1_name`      varchar(255) NOT NULL DEFAULT '' COMMENT 'Tax name',
  `tax2_name`      varchar(255) NOT NULL DEFAULT '' COMMENT 'Tax name',
  `tax3_name`      varchar(255) NOT NULL DEFAULT '' COMMENT 'Tax name',
  `tax4_name`      varchar(255) NOT NULL DEFAULT '' COMMENT 'Tax name',
  `total_tax_name` varchar(255) NOT NULL DEFAULT '' COMMENT 'Name of total tax. Sum of all taxes', 
  `tax1_value`     FLOAT        NOT NULL DEFAULT 0  COMMENT 'Tax percentage. E.g. 19.5',
  `tax2_value`     FLOAT        NOT NULL DEFAULT 0  COMMENT 'Tax percentage. E.g. 19.5',
  `tax3_value`     FLOAT        NOT NULL DEFAULT 0  COMMENT 'Tax percentage. E.g. 19.5',
  `tax4_value`     FLOAT        NOT NULL DEFAULT 0  COMMENT 'Tax percentage. E.g. 19.5',
  PRIMARY KEY (`id`) 
) ENGINE = InnoDB CHARACTER SET utf8;

CREATE TABLE IF NOT EXISTS `cc_invoices` (
  `id`             INTEGER      NOT NULL AUTO_INCREMENT,
  `payment_id`     INTEGER                              COMMENT 'Foreign key to payments table',
  `ccorder_id`     INTEGER      NOT NULL                COMMENT 'Foreign key to ccorders table',
  `owner_id`       INTEGER      NOT NULL DEFAULT '0'    COMMENT 'Foreign key to users table describes payment owner',
  `number`         VARCHAR(255) NOT NULL                COMMENT 'Payment number',
  `email`          VARCHAR(50)  NOT NULL DEFAULT ''     COMMENT 'Client email address',
  `sent_email`     TINYINT      NOT NULL DEFAULT '0',
  `sent_manually`  TINYINT      NOT NULL DEFAULT '0',
  `paid`           TINYINT      NOT NULL DEFAULT '0',
  `created_at`     DATETIME     NOT NULL,
  `paid_date`      DATETIME              DEFAULT NULL,
 INDEX owner_id_index (`owner_id`),
 PRIMARY KEY (`id`)
) ENGINE = InnoDB CHARACTER SET utf8;



CREATE TABLE IF NOT EXISTS  `acc_groups` (
  `id`   INTEGER      NOT NULL        auto_increment,
  `name` varchar(255) NOT NULL UNIQUE default ""     COMMENT 'Accountant group name',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      
CREATE TABLE IF NOT EXISTS  `acc_rights` (
  `id`        INTEGER      NOT NULL        AUTO_INCREMENT,
  `name`      VARCHAR(255) NOT NULL UNIQUE DEFAULT ""     COMMENT 'Accountant right name',
  `nice_name` VARCHAR(255) NOT NULL        DEFAULT ""     COMMENT 'Accountant right name to be shown in translation',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	      
CREATE TABLE IF NOT EXISTS  `acc_group_rights` (
  `id`           INTEGER NOT NULL auto_increment,
  `acc_group_id` INTEGER NOT NULL COMMENT 'Accountant group id',
  `acc_right_id` INTEGER NOT NULL COMMENT 'Accountant right id',
  `value`        TINYINT NOT NULL COMMENT 'Role right value ',
PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


# --------------- DROP TABLES -----------------
