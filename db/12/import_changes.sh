#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================

mysql_connect_data

/usr/src/mor/test/scripts/mysql/mysql_grants.sh

echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/db/12/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "Structure changes import complete"

echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/12/beta_data.sql

echo "Data changes import complete"


echo "Importing Currency Changes"
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/12/currency_changes.sql
echo "Currency changes import complete"

echo "Starting permission import"

#==== Importing new permissions dump
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/12/permissions.sql    


echo "Permission import complete"

mysql_server_version

vercomp "$MYSQL_VERSION_2" "5.5"
STATUS="$?"
if [ "$STATUS" == "0" ] || [ "$STATUS" == "1" ]; then
    /usr/src/mor/upgrade/12/mor_12_db_utf_fix_when_updating_from_extend.sh
else
    report "MySQL version lower than 5.5 detected. In order encodings would be OK - please upgrade MySQL version and run this script again" 1
fi

echo "DB upgrade complete"
