
USE mor;

CREATE TABLE `adactions` (
    `id` int(11) NOT NULL auto_increment,
    `priority` int(11) default NULL,
    `action` varchar(255) default NULL,
    `data` varchar(255) default NULL,
    `campaign_id` int(11) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `adnumbers` (
    `id` int(11) NOT NULL auto_increment,
    `number` varchar(255) default NULL,
    `status` varchar(255) default 'new',
    `campaign_id` int(11) default NULL,
    `executed_time` datetime default NULL,
    `completed_time` datetime default NULL,
    `channel` varchar(255) default NULL,
    PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `campaigns` (
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
						    