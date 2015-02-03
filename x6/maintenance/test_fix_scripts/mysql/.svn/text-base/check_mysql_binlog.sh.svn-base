#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    Script reports if MySQL binlog is enabled on server where replication is not present,
#           also checks if expire_logs_days not exceeds 3 days.
#           Live values are checked instead of values on config file.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

mysql_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

read_mor_replication_settings
mysql_connect_data_v2
mysqladmin variables -u $DB_USERNAME -p$DB_PASSWORD | grep " log_bin " | grep ON &> /dev/null
if [ "$?" == "0" ]; then
    EXPIRE_LOGS_DAYS=`mysqladmin variables -u $DB_USERNAME -p$DB_PASSWORD | grep expire_logs_days | awk -F"|" '{print $3}' | awk -F" " '{print $1}'`
    if [ "$EXPIRE_LOGS_DAYS" -ge 1 ] && [ "$EXPIRE_LOGS_DAYS" -le 3 ]; then
        report "MySQL expire_logs_days is set to $EXPIRE_LOGS_DAYS" 0
    else
        report "expire_logs_days is set to $EXPIRE_LOGS_DAYS on currently running MySQL" 1
    fi
    
    if [ "$REPLICATION_PRESENT" != "yes" ]; then
        report "replication is not present, but Binlog is enabled on currently running MySQL" 3
    fi
else
    report "MySQL binlog is disabled" 0
fi

