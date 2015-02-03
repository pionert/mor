#!/bin/bash

. /usr/src/mor/sh_scripts/install_configs.sh                                                                                                                                                                          
. /usr/src/mor/sh_scripts/mor_install_functions.sh

call_count=`mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM calls" | egrep -v '[a-Z]'`
if [ "$?" != "0" ]; then
    echo -ne "Failed to check how many calls are in your database. To prevent service downtime please check calls count manually:\n\nSELECT COUNT(*) FROM calls; \n\nIf you get a result that there are more than 500.000 calls - some precautions must be made before upgrade to prevent a downtime\n\nIf you do not know what is this all about press CTRL+C to exit\n\n"
    read
fi

if [ "$call_count" -ge '500000' ]; then
	echo -ne "\n\n\n\n\n\n"
	echo "                                             !!!!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!"
	echo "There are more than 500.000 calls in database, proceeding with upgrade without any appropriate actions could lead asterisk and GUI services"
	echo "to slowdown or stop for a long time while database upgrade process is active. So here is what you can do:"
	echo "1. If you don't have active calls and you know that your system hardware is fast enough, just press ENTER and attept to upgrade database with-"
	echo "out any further warnings or notices."
	echo "2. Export calls from database , then upgrade it and import old calls back to database (Notice: this requires advanced MySQL knowledge)."
	echo "3. Search http://forum.kolmisoft.com/ for more info."
	echo -ne "\n\n\n\n"
	echo "If you are not sure what to do, press CTRL+C to abort this task"
	read
else
    echo "Calls in DB: $call_count. Work can proceed." 
fi
