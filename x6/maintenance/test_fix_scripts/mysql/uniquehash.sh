#! /bin/bash

. /usr/src/mor/x6/framework/bash_functions.sh

mysql_connect_data_v2

uniquehash=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -B --disable-column-names -e "select uniquehash from users where id=0"`
if [ "$uniquehash" == "1c99d99974" ]; then
    api_in_use=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -B --disable-column-names -e "select value from conflines where name='Allow_API' and owner_id='0'"`
    if [ "$api_in_use" == "0" ]; then
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -B --disable-column-names -e "UPDATE users SET uniquehash = SUBSTRING(SHA1(RAND()) FROM 1 FOR 10) where uniquehash = '1c99d99974' and owner_id='0'"
        report "Replaced default admins uniquehash with random one" 4
    elif [ "$api_in_use" == "1" ]; then
        report "Admins uniquehash is default one and API is in use. Check with system owner and update uniquehash" 2
    else
        report "Failed to read API setting value to check if it is disabled or enabled" 1
    fi
fi
