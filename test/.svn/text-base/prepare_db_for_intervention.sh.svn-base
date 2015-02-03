#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    NEVER USE THIS ON PRODUCTION SERVERS! This script is used to prepare the DB for testing for various bugs. It is used in order users would not get invalid emails, etc... when you test things like daily/hourly/monthly actions
#
# Arguments:
#   $2  - DB_HOST
#   $3  - DB_NAME
#   $4  - DB_USERNAME
#   $5  - DB_PASSWORD


. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

FIRST_PARAM="$1"

DB_NAME="$2"

#------VARIABLES-------------


#----- FUNCTIONS ------------

#--------MAIN -------------
if [ "$DB_NAME" == "" ]; then  # User did not supplied the data, so we have to retrieve it ourselves
    mysql_connect_data_v2 > /dev/null
fi


if [ "$FIRST_PARAM" == "IKNOWWHATIDO" ]; then
    
    report "Breaking DB in order the system would not be able to send emails" 3
    /usr/bin/mysql "$DB_NAME" -e "UPDATE users set password = 'd033e22ae348aeb5660fc2140aec35850c4da997', username ='admin' where id = 0;"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE addresses set email = NULL, phone = '', mob_phone = '', fax = '', address = '';"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE conflines set value = 'logo/rails.png' where name ='Logo_Picture';"
    /usr/bin/mysql "$DB_NAME" -e "delete from sessions;"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE translations SET position = 1, active = 0 where position = 0;"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE translations SET position = 0, active = 1 where short_name = 'en';"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE servers SET active = 0;"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE conflines set value = 0 where name = 'Email_Sending_Enabled';"
    /usr/bin/mysql "$DB_NAME" -e "UPDATE conflines set value = '' where name = 'Email_from';"

    report "Turning off Asterisk in order it would not cause problems for clients" 3
    killall -9 safe_asterisk &> /dev/null
    killall -9 asterisk    &> /dev/null
else
    report "I see that you do not know how to use this script, for your own safety PLEASE DO NOT RUN THIS SCRIPT AGAIN, it's very dangerious!" 1
fi








