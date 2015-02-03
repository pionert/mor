#! /bin/sh
#
#   Author: Mindaugas Mardosas
#   Year:   2013
#   About:  This script checks all required parameters and updates MySQL db for better performance

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh
. /usr/src/mor/x6/framework/mor_install_functions.sh

#------------Functions------------------------

check_if_speedup_completed()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    This script checks if update for DB speedup is needed
    #
    # Returns:
    #   DB_UPDATE_NEEDED {0 - DB Update not needed, 1 - DB update is needed}
    
    
    local TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "DESC calls;" | grep "dcontext\|dstchannel\|lastapp\|lastdata\|amaflags\|userfield" | wc -l > $TMP_FILE
    NOT_NEEDED_COLUMNS=`cat $TMP_FILE`;
    if [ "$NOT_NEEDED_COLUMNS" != "0" ]; then
        DB_UPDATE_NEEDED=1 # DB update is needed
        return 1 # DB needs update
    else
        DB_UPDATE_NEEDED=0 # not needed
        return 0; # DB is OK
    fi        

}

#==== Main
read_mor_gui_settings
if [ "$GUI_PRESENT" != "1" ] ; then  # We are not sure that we will be able to retrieve DB settings. Also we need to know GUI version
    exit 1; # we are not sure if this is a standalone 
fi

mor_gui_current_version
mor_version_mapper $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS

mysql_connect_data_v2 > /dev/null   # retrieving DB settings

# TODO CHECK IF GUI VERSION IS


check_if_speedup_completed
calls_in_db
if [ "$DB_UPDATE_NEEDED" == "1" ] && [ "$CALLS_IN_DB" -lt "100000" ] && [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
    report "There are less than 100K calls, launching DB speedup script" 3

    /usr/src/mor/db/x4/speedup_fresh_db.sh

    check_if_speedup_completed
    if [ "$DB_UPDATE_NEEDED" == "1" ]; then
       report "Something went wrong, try launching script manually or check instructions in it: /usr/src/mor/db/x4/speedup_fresh_db.sh" 1
       exit 1
    fi 
else
    report "Call Speedup changes are not necessary or cannot be completed" 3
fi



