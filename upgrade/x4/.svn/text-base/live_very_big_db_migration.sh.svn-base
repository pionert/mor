#! /bin/sh
#
#   Author: Mindaugas Mardosas
#   Year:   2013
#   About:  This script uses percona toolkit to migrate MOR database live without any calls interruption.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
. /usr/src/mor/test/framework/mysql_specific_functions.sh

NO_SCREEN="$1"  # Option to be tolerant on running without screen

BACKUP_PATH="$2"

if [ ! -d "$BACKUP_PATH" ]; then
    BACKUP_PATH="/home"
fi

PERCONA_LOG="/var/log/mor/percona"

#=== Functions ===

#======= MAIN ==========
if [ "$NO_SCREEN" != "NO_SCREEN" ]; then
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
        exit 1
    fi
fi


mysql_connect_data_v2      &> /dev/null

# Check DB connection

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" -e "use $DB_NAME;" &> /dev/null
if [ "$?" != "0" ]; then
    report "Failed to connect to database using these details: /usr/bin/mysql -h $DB_HOST -u $DB_USERNAME --password=$DB_PASSWORD" 1
    exit 1
fi

check_if_db_index_present calls calldate
if [ "$?" == "0" ]; then
    report "Percona calls table migration is not needed, skipping" 3
    exit 0
fi


/usr/src/mor/sh_scripts/percona_install.sh
if [ "$?" != "0" ]; then
    exit 1
fi

dump_mor_db "$BACKUP_PATH"
STATUS="$?"
if [ "$STATUS" != "0" ] &&  [ "$STATUS" != "3" ]; then
    report "Will not proceed percona calls migration as backup creation failed" 1
    exit 1
fi

# Here is a group of alters which does not required any checks, etc..
#BIG_ALTER='MODIFY id SERIAL,ADD INDEX uniqueidindex  (uniqueid(6)),  DROP COLUMN `dcontext`, DROP COLUMN `dstchannel`, DROP COLUMN `lastapp`, DROP COLUMN `lastdata`, DROP COLUMN `amaflags`, DROP COLUMN `userfield` ,CHANGE `calldate` `calldate` TIMESTAMP NULL,ADD INDEX calldateindex  (calldate),ADD COLUMN `date` DATE NULL AFTER `calldate` ,ADD INDEX dateindex  (date),CHANGE `disposition` `disposition` ENUM("FAILED", "NO ANSWER", "BUSY", "ANSWERED"),CHANGE `callertype` `callertype` ENUM("Local", "Outside"), MODIFY did_price DECIMAL(30,15) DEFAULT 0, MODIFY provider_rate DECIMAL(30,15) DEFAULT 0, MODIFY provider_price DECIMAL(30,15) DEFAULT 0, MODIFY user_rate DECIMAL(30,15) DEFAULT 0, MODIFY user_price DECIMAL(30,15) DEFAULT 0, MODIFY reseller_rate DECIMAL(30,15) DEFAULT 0, MODIFY reseller_price DECIMAL(30,15) DEFAULT 0, MODIFY partner_rate DECIMAL(30,15) DEFAULT 0, MODIFY partner_price DECIMAL(30,15) DEFAULT 0, MODIFY did_inc_price DECIMAL(30,15) DEFAULT 0, MODIFY did_prov_price DECIMAL(30,15) DEFAULT 0, MODIFY real_duration DECIMAL(30,15) DEFAULT 0, MODIFY real_billsec DECIMAL(30,15) DEFAULT 0'



BIG_ALTER='MODIFY id SERIAL, CHANGE `calldate` `calldate` DATETIME DEFAULT "0000-00-00 00:00:00", CHANGE `disposition` `disposition` ENUM("FAILED", "NO ANSWER", "BUSY", "ANSWERED"),CHANGE `callertype` `callertype` ENUM("Local", "Outside")'

echo "`date` Alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona

# Drop columns
report "Preparing a list of columns required to be dropped" 3
DROP_COLUMNS_LIST=("dcontext" "dstchannel" "lastapp" "lastdata" "amaflags" "userfield")
for element in $(seq 0 $((${#DROP_COLUMNS_LIST[@]} - 1)))
do
    report "Checking if column ${DROP_COLUMNS_LIST[$element]} exists " 3
    check_if_db_column_exists "calls" "${DROP_COLUMNS_LIST[$element]}"
    if [ "$COLUMN_EXISTS" == "1" ]; then # if found in DB
        report "${DROP_COLUMNS_LIST[$element]} exists" 3
        BIG_ALTER="$BIG_ALTER,  DROP COLUMN \`${DROP_COLUMNS_LIST[$element]}\`"
    else
        report "${DROP_COLUMNS_LIST[$element]} not present" 3
    fi
done

echo "`date` BIG ALTER WITH DB column drop statements:  $BIG_ALTER" >> $PERCONA_LOG
#==========================================================================

# Adding new columns
check_if_db_column_exists "calls" "date"
if [ "$COLUMN_EXISTS" == "0" ]; then # if not found in DB
    report "Adding column date" 3
    BIG_ALTER="$BIG_ALTER, ADD COLUMN \`date\` DATE NULL"
fi

#==== Indexes check
# ===========Add new indexes===========
check_if_db_index_present calls dateindex
if [ "$?" == "0" ]; then
    BIG_ALTER="$BIG_ALTER, ADD INDEX dateindex  (\`date\`)"
    echo "`date` Adding dateindex index. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona  
fi

check_if_db_index_present calls uniqueidindex
if [ "$?" == "0" ]; then
    BIG_ALTER="$BIG_ALTER, ADD INDEX uniqueidindex  (uniqueid(6))"
    echo "`date` Adding uniqueidindex index. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona  
fi

check_if_db_index_present calls calldateindex
if [ "$?" == "0" ]; then
    BIG_ALTER="$BIG_ALTER, ADD INDEX calldateindex  (calldate)"
    echo "`date` Adding calldateindex index. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona  
fi

echo "`date` BIG ALTER WITH DB column ADD index statements:  $BIG_ALTER" >> $PERCONA_LOG

# ===========Drop not required indexes ===========
check_if_db_index_present calls card_id_calldate
if [ "$?" != "0" ]; then
    BIG_ALTER="$BIG_ALTER, DROP INDEX card_id_calldate"
    echo "`date` Found that card_id_calldate index is present. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona
fi

check_if_db_index_present calls card_id_user_id_calldate
if [ "$?" != "0" ]; then
    BIG_ALTER="$BIG_ALTER, DROP INDEX card_id_user_id_calldate"
    echo "`date` Found that card_id_user_id_calldate index is present. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona  
fi

check_if_db_index_present calls calldate
if [ "$?" != "0" ]; then
    BIG_ALTER="$BIG_ALTER, DROP INDEX calldate"
    echo "`date` Found that calldate index is present. One big alter for calls table to be executed: $BIG_ALTER" >> /var/log/mor/percona  

fi

echo "`date` BIG ALTER WITH DB index drop statements:  $BIG_ALTER" >> $PERCONA_LOG

report "Now will run fix for calls disposition where it is not set" 3
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" -e 'UPDATE calls set disposition = "FAILED" WHERE hangupcause = 224 AND disposition not in ("FAILED", "NO ANSWER", "BUSY", "ANSWERED");'

#report "Launching the big alter: $BIG_ALTER" 3
#
PTDEBUG=1  pt-online-schema-change --execute --print  --alter "$BIG_ALTER" D="$DB_NAME",t=calls   >> $PERCONA_LOG 2>&1   
status="$?"

if [ "$status" == "0" ]; then
    report "Calls table percona migration was successful" 4
else
    report "Failed to migrate calls table with percona. You can find DB backup in /home dir." 1
    exit 1
fi

# These are safe to add all big work is completed
report "Creating trigger: insert_date" 3
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e 'CREATE TRIGGER `insert_date` BEFORE INSERT ON `calls` FOR EACH ROW SET NEW.date = LEFT(NEW.calldate, 10);' >> /var/log/mor/percona   2>&1 

report "Updating calls table date" 3
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e 'UPDATE calls SET date = LEFT(calldate, 10)'  >> /var/log/mor/percona   2>&1 
