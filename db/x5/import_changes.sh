#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================
NO_SCREEN="$1"  # Option to be tolerant on running without screen

if [ "$NO_SCREEN" != "NO_SCREEN" ]; then    # require to be running from screen from now on
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
        exit 1
    fi
fi


mysql_connect_data_v2

check_if_percona_upgrade_is_needed()
{
    if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "desc calls;" | grep dcontext | wc -l` == "1" ]; then
        # Percona migration is needed
        report "Launching percona migration script" 3
        /usr/src/mor/upgrade/x5/live_very_big_db_migration.sh "$NO_SCREEN"
        if [ "$?" != "0" ]; then
            exit 1
        fi
    fi
}


/usr/src/mor/x5/maintenance/test_fix_scripts/mysql/mysql_grants.sh


#check_if_percona_upgrade_is_needed

echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/db/x5/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "Structure changes import complete"

echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/x5/beta_data.sql

echo "Data changes import complete"


echo "Importing Currency Changes"
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/x5/currency_changes.sql
echo "Currency changes import complete"


echo "Starting permission import"

#==== Importing new permissions dump
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/x5/permissions.sql    


echo "Permission import complete"

