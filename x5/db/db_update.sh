#! /bin/sh
#==== Includes=====================================
 . /usr/src/mor/x5/framework/mor_install_functions.sh
 . /usr/src/mor/x5/framework/framework.conf
 . /usr/src/mor/x5/framework/bash_functions.sh
#==================================================
NO_SCREEN="$2"  # Option to be tolerant on running without screen
if [ "$NO_SCREEN" != "NO_SCREEN" ]; then    # require to be running from screen from now on
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   2
        #exit 1
    fi
fi

cd /usr/src/mor/x5/db

if [ "$1" == "STABLE" ]; then
  stable_rev=`cat /usr/src/mor/x5/stable_revision`
  report "Updating DB to STABLE revision: $stable_rev" 3
  svn -r $stable_rev update beta*
else
  report "Updating DB to LATEST revision" 3
  svn update
fi


mysql_connect_data_v2

/usr/src/mor/x5/db/mysql_grants.sh


report "Importing STRUCTURE Changes" 3

#FILE="/usr/src/mor/x5/db/beta_structure.sql"
FILE="/usr/src/mor/db/x5/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

report "Structure changes import complete" 0

report "Importing DATA Changes" 3

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/x5/db/beta_data.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/x5/beta_data.sql

report "Data changes import complete" 0

report "Starting permission import" 3
# ==== Importing new permissions dump
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/x5/permissions.sql
report "Permission import complete" 0

report "DB Update complete" 0
