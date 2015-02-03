
USE mor;

#################### MOR PRO 0.6 ############################

# --------------- CREATE TABLES -----------------



CREATE TABLE IF NOT EXISTS `pbxfunctions` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `context` varchar(255) default NULL,
  `extension` varchar(255) default NULL,
  `priority` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `activecalls` (
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


CREATE TABLE IF NOT EXISTS `quickforwarddids` (
  `id` int(11) NOT NULL auto_increment,
  `did_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `number` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# ------------ Click2Call Addon -----------

CREATE TABLE IF NOT EXISTS `c2c_campaigns` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `device_id` int(11) default NULL,
  `first_dial` enum('company','client') NOT NULL default 'client',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `c2c_commfields` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `c2c_campaign_id` int(11) NOT NULL,
  `commenttype` enum('checkbox','textarea','text') default 'text',
  `commentorder` int(11) NOT NULL default '99',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `c2c_calls` (
  `id` int(11) NOT NULL auto_increment,
  `c2c_campaign_id` int(11) NOT NULL,
  `client_number` varchar(255) default NULL,
  `client_call_id` int(11) default NULL,
  `company_call_id` int(11) default NULL,
  `calldate` datetime default NULL,
  `processed` tinyint(4) default 0,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `c2c_comments` (
  `id` int(11) NOT NULL auto_increment,
  `c2c_commfield_id` int(11) default NULL,
  `c2c_call_id` int(11) default NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


# ---------------- Auto dialer ----------------

CREATE TABLE IF NOT EXISTS  `adactions` (
    `id` int(11) NOT NULL auto_increment,
    `priority` int(11) default NULL,
    `action` varchar(255) default NULL,
    `data` varchar(255) default NULL,
    `campaign_id` int(11) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	    
CREATE TABLE IF NOT EXISTS  `adnumbers` (
    `id` int(11) NOT NULL auto_increment,
    `number` varchar(255) default NULL,
    `status` varchar(255) default 'new',
    `campaign_id` int(11) default NULL,
    `executed_time` datetime default NULL,
    `completed_time` datetime default NULL,
    `channel` varchar(255) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `campaigns` (
    `id` int(11) NOT NULL auto_increment,
    `name` varchar(255) default NULL,
    `campaign_type` varchar(255) default 'basic',
    `status` varchar(255) default NULL,
    `start_time` time default NULL,
    `stop_time` time default NULL,
    `max_retries` int(11) default '0',
    `retry_time` int(11) default '120',
    `wait_time` int(11) default '30',
    `user_id` int(11) default NULL,
    `device_id` int(11) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
		

# --------------- DROP TABLES -----------------

DROP TABLE IF EXISTS `shortnumbers`;


