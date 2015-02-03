
#create main db

#DROP DATABASE IF EXISTS mor;

CREATE DATABASE mor_mnp CHARACTER SET utf8;

GRANT ALL PRIVILEGES ON mor_mnp.* TO mor@localhost IDENTIFIED BY "mor" WITH GRANT OPTION;
GRANT REPLICATION SLAVE , REPLICATION CLIENT ON * . * TO 'mor'@'localhost';

USE mor_mnp;

#DROP TABLE IF EXISTS `numbers`;
CREATE TABLE `numbers` (
    `number` varchar(50) NOT NULL,
    `prefix` varchar(20) NOT NULL,
    PRIMARY KEY  (`number`),
    UNIQUE KEY `number` (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

USE mor;

UPDATE mor.extlines SET app = 'AGI', `appdata` = 'mor_mnp' WHERE extlines.context = 'mor' AND extlines.exten = '_X.' AND `extlines`.`priority` =1;
    