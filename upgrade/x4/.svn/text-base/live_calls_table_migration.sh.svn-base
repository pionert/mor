
#! /bin/sh
#
#   Author: Mindaugas Mardosas
#   Year:   2013
#   About:  This script uses percona toolkit to migrate MOR database live without any calls interruption.


. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh



#===== Variables ====
ARRAY_OF_TABLE_NAMES=() # Initializing to be globally accessible in this script from functions
FORMED_PERCONA_SQL=""   # Initializing to be globally accessible in this script from functions

#=== Functions ====
install_percona_toolkit()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function install Percona toolkit for online DB schema migration.
    
    if [ `/usr/bin/pt-online-schema-change --version | grep '2.2.3' | wc -l` == "0" ]; then
        report "Percona Toolkit not detected, will install now" 3
        cd /usr/src
        wget -c http://www.kolmisoft.com/packets/percona/percona-toolkit-2.2.3-1.noarch.rpm
        yum -y install percona-toolkit-2.2.3-1.noarch.rpm
        if [ `/usr/bin/pt-online-schema-change --version | grep '2.2.3' | wc -l` == "1" ]; then
            report "Percona Toolkit installed" 4
        else
            report "Percona Toolkit installation failed, will not attempt to migrate DB" 1
            exit 1
        fi
    fi    
}
get_all_db_tables_names()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function install Percona toolkit for online DB schema migration.
    #   Returns:
    #       ARRAY_OF_TABLE_NAMES=()  - contains an array of DB table names.
    #   Important notes:
    #       Before executing this function initialize global variable like this:
    #           ARRAY_OF_TABLE_NAMES=()
    #
    #   mysql_connect_data_v2 must be called to get required connection details for this function
    #
    
    local DEBUG=0
    
    mysql_connect_data_v2      &> /dev/null
    local tmp_file=`mktemp`
    
    /usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e "SHOW tables;" | (read; cat) > $tmp_file

    FILE="$tmp_file"
    exec < $FILE
    while read LINE
    do
        ARRAY_OF_TABLE_NAMES+=($LINE);
    done
    
    if [ "$DEBUG" == "1" ]; then
        echo ${ARRAY_OF_TABLE_NAMES[1]}
        echo ${ARRAY_OF_TABLE_NAMES[2]}
    fi
}

grep_all_alter_sql_for_table_and_prepare_for_percona_toolkit()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function install Percona toolkit for online DB schema migration.
    #
    #
    #   Arguments:
    #       $1  DB structure changes file to look for
    #       $2  table name for which we are constructing SQL
    #
    #   Global variable FORMED_PERCONA_SQL must be initialed before calling this function. Value will be assigned to that variable.
    #
    #   Additional information:
    #       In order the ALTER TABLE SQL could be run on Percona toolkit - it has to be prepared the following way:
    #           1. "ALTER TABLE" <-- must be removed from SQL
    #           2. All alters for one table for performance reasons must be concatenated to one string and separated by semicolon
    #
    #
    FILE_WITH_DB_ALTER_STATEMENTS="$1"
    TABLE_NAME="$2"
    
    
    # The following lines does these things:
    #   1. greps ALTER TABLE statements
    #   2. REMOVES "ALTER TABLE" from SQL beginning
    #   3. REMOVES table name from SQL
    #   4. REMOVES any whitespaces from the beginning
    #   5. Checks if the statement has to add new column - checks if that column is not already present - if present, skips it.
    #
    # Code lines are divided into groups using files to export data between operations - do not attempt to fix this, it's done on purpose in order the code would be clear
    
    local FILE=`mktemp`
    local FILE2=`mktemp`

    grep -i "$TABLE_NAME" $FILE_WITH_DB_ALTER_STATEMENTS | grep -i 'ALTER TABLE' | awk -F'ALTER|TABLE' 'BEGIN {IGNORECASE = 1}{print $3}' |  sed 's/^ *//g' | cut -d' ' -f2- > $FILE
    
    exec < $FILE
    while read LINE; do
        DB_column=`echo $LINE | awk  '{print $3}'`
        
        if [ `echo $LINE | awk '{print $1}'` == "add" ] || [ `echo $LINE | awk '{print $1}'` == "ADD" ]; then 
            if [ `mysql mor -e "DESC $TABLE_NAME" | grep $DB_column | wc -l` == "1" ]; then    
                continue
            fi
        fi
        
        if [ `echo $LINE | awk '{print $1}'` == "drop" ] || [ `echo $LINE | awk '{print $1}'` == "DROP" ]; then 
            if [ `mysql mor -e "DESC $TABLE_NAME" | grep $DB_column | wc -l` == "0" ]; then    
                continue
            fi
        fi
        echo "$LINE"
    done | tr -d '\n' > $FILE2
    
    
    FORMED_PERCONA_SQL=`cat $FILE2`
    
    rm -rf $FILE $FILE2
    
}

#=== Main =====
mysql_connect_data_v2      &> /dev/null
install_percona_toolkit # If not installed already...
get_all_db_tables_names

#=========== This commented out code would work with ALL tables, but there are problems with DEFAULT NULL values in alter table from percona toolkit, so the decision was made to use this migration method only for calls table
#for element in $(seq 0 $((${#ARRAY_OF_TABLE_NAMES[@]} - 1)))
#do
#    FORMED_PERCONA_SQL="just_to_initialize"
#    grep_all_alter_sql_for_table_and_prepare_for_percona_toolkit "/usr/src/mor/db/x4/beta_structure.sql" "${ARRAY_OF_TABLE_NAMES[$element]}"
#    if [ "$FORMED_PERCONA_SQL" == "" ]; then
#        report "No alter tables found for table ${ARRAY_OF_TABLE_NAMES[$element]}" 0
#        continue;   # No alters found for this table
#    fi
#    
#    report "Now will attempt to migrate table ${ARRAY_OF_TABLE_NAMES[$element]}" 3
#    
#    pt-online-schema-change --execute --alter  "$FORMED_PERCONA_SQL" D=$DB_NAME,t=${ARRAY_OF_TABLE_NAMES[$element]}
#    
#    if [ "$?" == "0" ]; then
#        report "Table ${ARRAY_OF_TABLE_NAMES[$element]} migration was successful" 4
#    else
#        report "Table ${ARRAY_OF_TABLE_NAMES[$element]} migration failed" 1
#        exit 1
#    fi
#
#done

# Rework for just one "calls" table

FORMED_PERCONA_SQL="just_to_initialize"
grep_all_alter_sql_for_table_and_prepare_for_percona_toolkit "/usr/src/mor/db/x4/beta_structure.sql" "calls"
if [ "$FORMED_PERCONA_SQL" == "" ]; then
    report "No alter tables found for table ${ARRAY_OF_TABLE_NAMES[$element]}" 0
    continue;   # No alters found for this table
fi

report "Now will attempt to migrate table calls" 3

pt-online-schema-change --execute --alter  "$FORMED_PERCONA_SQL" D=$DB_NAME,t=calls

if [ "$?" == "0" ]; then
    report "Table calls migration was successful" 4
else
    report "Table calls migration failed" 1
fi
