#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script syncs MySQL data to an up-to date version

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------
#----- FUNCTIONS ------------
check_if_there_are_calls_made_via_cards()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About: This function check if sync is needed for cards table
    
    if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select * from calls where card_id != NULL LIMIT 1;" | (read; cat) | wc -l` == "0" ]; then
        #return 0 # sync is not needed
        exit 0
    else
        return 1 # sync is needed
    fi    
    
    
}
check_if_sync_needed()
{
    asterisk_is_running
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then
        mor_core_version
        vercomp "12.0.6" "$MOR_CORE_VERSION" #this is needed starting from core 12++
        if [ "$?" == "2" ]; then
            check_if_required_columns_exist
            check_if_there_are_calls_made_via_cards            
            
            
            if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT sum(call_count) FROM cards;" | (read; cat)` == "0" ]; then
                return 1
            else
                return 0
            fi
        else
            return 0
        fi
    else
        return 0
    fi
}
check_if_required_columns_exist()
{
    if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "DESC cards; desc dids;" | grep call_count | wc -l` != "2" ]; then
        report "You must upgrade your database table structure by running import_changes.sh for your MOR version before you will be able to sync database data" 3
        exit 0
    fi
}
sync_data()
{
    report "Locking table calls for write" 3

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SET autocommit=0; LOCK TABLE calls WRITE, dids WRITE; UPDATE dids JOIN (SELECT COUNT(*) call_count, did_id FROM calls WHERE did_id > 0 GROUP BY did_id) calls ON(calls.did_id = dids.id) SET dids.call_count = calls.call_count; COMMIT; UNLOCK TABLES;"
    SQL1="$?"

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SET autocommit=0; LOCK TABLE calls WRITE, cards WRITE; UPDATE cards JOIN (SELECT COUNT(*) call_count, card_id FROM calls WHERE card_id > 0 GROUP BY card_id) calls ON(calls.card_id = cards.id) SET cards.call_count = calls.call_count; COMMIT; UNLOCK TABLES;"
    SQL2="$?"

    if [ "$SQL2" == "0" ] && [ "$SQL1" == "0" ]; then
        report "All went OK, calls table unlocked, data is now synced" 4
    else
        report "Something went wrong. Please try to run this line in DB directly:\nSET autocommit=0; LOCK TABLE calls WRITE, dids WRITE; UPDATE dids JOIN (SELECT COUNT(*) call_count, did_id FROM calls WHERE did_id > 0 GROUP BY did_id) calls ON(calls.did_id = dids.id) SET dids.call_count = calls.call_count; COMMIT; UNLOCK TABLES; \n\nSET autocommit=0; LOCK TABLE calls WRITE, cards WRITE; UPDATE cards JOIN (SELECT COUNT(*) call_count, card_id FROM calls WHERE card_id > 0 GROUP BY card_id) calls ON(calls.card_id = cards.id) SET cards.call_count = calls.call_count; COMMIT; UNLOCK TABLES;" 1
    fi
}
#--------MAIN -------------
mysql_connect_data_v2 > /dev/null
check_if_sync_needed
if [ "$?" == "1" ]; then
    report "Your database needs sync. Would you like to proceed now? Asterisk has to be shutdown before this operation. This would stop calls for a few hours depending on amount of calls in calls table. It is recommended to delete not needed calls from this table before proceeding. Type in uppercase yes to proceed" 3
    read answer
    if [ "$answer" == "YES" ]; then
        sync_data
    else
        report "It is important that you would run sync again, because without sync GUI will display incorrect count of calls for each DID and Calling Cards. This has to be done once" 1
    fi
fi
