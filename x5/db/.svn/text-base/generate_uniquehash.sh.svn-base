#! /bin/bash

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:   Sets random uniquehash for admin user. Use it on fresh install only!

. /usr/src/mor/x5/framework/bash_functions.sh

mysql_connect_data_v2

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE users SET uniquehash = SUBSTRING(SHA1(RAND()) FROM 1 FOR 10) where id=0"
