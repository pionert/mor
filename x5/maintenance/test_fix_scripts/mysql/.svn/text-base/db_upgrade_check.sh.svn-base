#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script checks if DB was properly upgraded. 

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
mysql_connect_data_v2      > /dev/null 

DB_CHECK=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name='DB_Update_From_Script';" | (read; cat)`

if [ "$DB_CHECK" == "1" ]; then
	report "Previous DB update is successful" 0
else
	report "Previous DB update FAILED. Please contact Kolmisoft support." 1
fi
