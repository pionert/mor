#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    script restart service if it is stopped for some reasons

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

read_mor_db_settings
if [ "$DB_PRESENT" == "0" ]; then
    exit 0;
fi

/etc/init.d/mor_aggregates status | grep running >/dev/null
if [ $? == '1' ]; then
    /etc/init.d/mor_alerts start
fi
