#! /bin/sh

. /usr/src/mor/x5/framework/settings.sh
. /usr/src/mor/x5/framework/mor_install_functions.sh


cd /usr/src/mor

# get db data
mysql_connect_data_v2

#echo "Importing Permissions"

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/0.8/permissions.sql

#echo
echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/sh_scripts/asterisk/db/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo
echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/beta_data.sql

echo "Importing Triggers"
/usr/bin/mysql -h "$DB_HOST" -u root --password="" "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/triggers.sql
if [ "$?" != "0" ]; then    #if inserting without a password fails
    /usr/bin/mysql -h "$DB_HOST" -u root -p  "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/triggers.sql
fi
