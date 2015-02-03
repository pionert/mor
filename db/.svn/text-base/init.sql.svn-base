
#create main db

#DROP DATABASE IF EXISTS mor;

CREATE DATABASE mor CHARACTER SET utf8;

GRANT ALL PRIVILEGES ON mor.* TO mor@localhost IDENTIFIED BY "mor" WITH GRANT OPTION;
GRANT REPLICATION SLAVE , REPLICATION CLIENT ON * . * TO 'mor'@'localhost';

grant super on *.* to 'mor'@'localhost';

#create testing db

DROP DATABASE IF EXISTS mor_test;

CREATE DATABASE mor_test CHARACTER SET utf8;

GRANT ALL PRIVILEGES ON mor_test.* TO mor@localhost IDENTIFIED BY "mor" WITH GRANT OPTION;


USE mor;


