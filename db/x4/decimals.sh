#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script alters call table and ensures that decimals are used instead of double.
#
# ALTER TABLE calls MODIFY did_price DECIMAL(30,15) DEFAULT 0, MODIFY provider_rate DECIMAL(30,15) DEFAULT 0, MODIFY provider_price DECIMAL(30,15) DEFAULT 0, MODIFY user_rate DECIMAL(30,15) DEFAULT 0, MODIFY user_price DECIMAL(30,15) DEFAULT 0, MODIFY reseller_rate DECIMAL(30,15) DEFAULT 0, MODIFY reseller_price DECIMAL(30,15) DEFAULT 0, MODIFY partner_rate DECIMAL(30,15) DEFAULT 0, MODIFY partner_price DECIMAL(30,15) DEFAULT 0, MODIFY did_inc_price DECIMAL(30,15) DEFAULT 0, MODIFY did_prov_price DECIMAL(30,15) DEFAULT 0, MODIFY real_duration DECIMAL(30,15) DEFAULT 0, MODIFY real_billsec DECIMAL(30,15) DEFAULT 0"

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
. /usr/src/mor/test/framework/mysql_specific_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_required_columns_are_decimal_in_calls_table()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function checks if there are double/float db columns in calls table to upgrade to decimal
	#
	# Returns:
    # 	CALLS_TABLE_NEEDS_UPDATE_FOR_DECIMALS {1 - update is neeeded; 0 - update is not needed }

    CALLS_TABLE_NEEDS_UPDATE_FOR_DECIMALS=1
    DECIMAL_ALTER="ALTER TABLE calls" # Don't touch!
    EVIL_DECIMAL_LIST=("did_price" "provider_rate" "provider_price" "user_rate" "user_price" "reseller_rate" "reseller_price" "partner_rate" "partner_price"
    "did_inc_price" "did_prov_price" "real_duration" "real_billsec")
    FIRST="TRUE"
    for element in $(seq 0 $((${#EVIL_DECIMAL_LIST[@]} - 1)))
    do
        check_if_db_column_is_decimal "calls" "${EVIL_DECIMAL_LIST[$element]}"
        if [ "$IS_DECIMAL" == "0" ]; then # if found in DB
            report "Column ${EVIL_DECIMAL_LIST[$element]} is not decimal" 3
            if [ "$FIRST" == "TRUE" ]; then
            	FIRST="FALSE"
            	DECIMAL_ALTER="$DECIMAL_ALTER MODIFY \`${EVIL_DECIMAL_LIST[$element]}\` DECIMAL(30,15) DEFAULT 0"
            else
            	DECIMAL_ALTER="$DECIMAL_ALTER , MODIFY \`${EVIL_DECIMAL_LIST[$element]}\` DECIMAL(30,15) DEFAULT 0"
            fi
        fi
    done

    if [ "$FIRST" == "TRUE" ]; then # Don't touch!
        CALLS_TABLE_NEEDS_UPDATE_FOR_DECIMALS=0
    fi
}
#--------MAIN -------------

mysql_connect_data_v2 > /dev/null

check_if_required_columns_are_decimal_in_calls_table
if [ "$CALLS_TABLE_NEEDS_UPDATE_FOR_DECIMALS" == "1" ]; then
    calls_in_db

    if [ "$CALLS_IN_DB" -lt "500000" ]; then
    	report "There are non-decimal columns in calls table. Will fix that now" 3
        /usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" -e "$DECIMAL_ALTER;"
        STATUS="$?"

        check_if_required_columns_are_decimal_in_calls_table

        if [ "$STATUS" != "0" ] || [ "$CALLS_TABLE_NEEDS_UPDATE_FOR_DECIMALS" == "1" ]; then
            report "Failed to upgrade calls table. Try again manually: $DECIMAL_ALTER" 1
            exit 1
        else
            report "Calls table was successfully upgraded!" 4
        fi
    else
        report "You have a lot of calls in calls table: $CALLS_IN_DB. You need to shedule and do this update in DB manually as it can cause long service interruption depending on amount of calls" 3
        report "SQL which you have to run when ready to do this: $DECIMAL_ALTER" 3
        report "If you will not run this SQL - you will have small (less than a fraction of cent) rounding errors." 3
    fi
else
    report "Calls table is up to date" 3
fi