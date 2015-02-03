#! /bin/sh

# M2 DB is located at /usr/src/m2
# checkout: svn co http://svn.kolmisoft.com/m2/install/ /usr/src/m2
# this script is left here for backwards-compatibility

# update M2 db to latest stable revision

svn co http://svn.kolmisoft.com/m2/install/ /usr/src/m2

stable_rev=`cat /usr/src/m2/gui/stable_revision`

cd /usr/src/m2/db
svn -r $stable_rev update


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


mysql_connect_data

/usr/src/mor/test/scripts/mysql/mysql_grants.sh


echo "Importing STRUCTURE Changes"

FILE="/usr/src/m2/db/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "Structure changes import complete"

echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/m2/db/beta_data.sql

echo "Data changes import complete"


echo "Importing Currency Changes"
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/m2/db/currency_changes.sql
echo "Currency changes import complete"


echo "Starting permission import"

#==== Importing new permissions dump
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/m2/db/permissions.sql

echo "Permission import complete"
