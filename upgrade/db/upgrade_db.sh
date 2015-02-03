#! /bin/sh
#==========
mysql_connect_data(){
if [ -r /home/mor/config/database.yml ];
   then
      cat /home/mor/config/database.yml | grep -iA 5 production: | grep -iA 4 database: > /tmp/mor_db.txt
      DATABASE=`cat /tmp/mor_db.txt | grep database | cut -c 13-`;
      DB_USERNAME=`cat /tmp/mor_db.txt | grep username | cut -c 13-`;
      DB_PASSWORD=`cat /tmp/mor_db.txt | grep password | cut -c 13-`;
      HOST=`cat /tmp/mor_db.txt | grep host | cut -c 9-`;
   
      if [ "$DB_USERNAME" -a "$DATABASE" -a "$DB_PASSWORD" -a "$HOST" != "" ]; 
         then echo "Username, database, password and host were found:";
         else echo "There was an error, please enter the following mysql info by hand:";
            echo "Database name:"; read DATABASE;
            echo "User name:"; read DB_USERNAME;
            echo "Password:"; read DB_PASSWORD;
            echo "Host:"; read HOST;
      fi
      
   else echo "Can't read /home/mor/config/database.yml"
fi

rm -rf /tmp/mor_db.txt

echo "DB_USERNAME: $DB_USERNAME"
echo "DATABASE: $DATABASE"
echo "DB_PASSWORD: not echoing"
echo "HOST: $HOST";
}
mysql_connect_data

#== USERNAME="mor"
#== PASSWORD="mor"
#==================
clear;
echo -e "\n-------- Starting MOR database upgrade to v0.6 ----------\n";
echo -e "\n--------- Making backup ---------\n";

mysqldump -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction mor > /usr/src/mor/upgrade/db/backup/mor_backup.$$.sql ; 
						                        
#compressing....
cd /usr/src/mor/upgrade/db/backup/
tar -czf mor_backup.$$.sql.tar.gz mor_backup.$$.sql
rm -rf mor_backup.$$.sql 

echo -e "\n--------- Upgrading tables ---------\n"; 

/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD < /usr/src/mor/upgrade/db/upgrade_db_tables.sql

echo -e "\ndone\n---------- Altering tables ------------\n"

/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE users ADD COLUMN allow_loss_calls int(11) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE emails ADD COLUMN template tinyint(4) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE devices ADD COLUMN cid_from_dids tinyint(4) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE invoicedetails ADD COLUMN invdet_type tinyint(4) DEFAULT 1;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE users ADD COLUMN hidden tinyint(4) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE users ADD COLUMN owner_id int(11) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE tariffs ADD COLUMN owner_id int(11) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN hangupcause int(11) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN server_id int(11) DEFAULT 1;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE payments ADD COLUMN bill_nr varchar(255);"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE payments ADD COLUMN hash varchar(32);"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE providers ADD COLUMN timeout int(11) DEFAULT 60;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN t38passthrough tinyint(4) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN peername varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN useragent varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN uri varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN sipfrom varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN recvip varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE calls ADD COLUMN peerip varchar(255) DEFAULT NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE devices ADD COLUMN process_sipchaninfo tinyint(4) DEFAULT 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE devices ADD COLUMN timeout int(11) DEFAULT 60;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE devices MODIFY device_type varchar(20);"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE devices ADD COLUMN promiscredir enum('yes','no') default 'no';"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE pbxfunctions ADD COLUMN pf_type varchar(20);"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE payments ADD COLUMN card tinyint(4) default 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE locationrules ADD COLUMN lr_type enum('dst','src') default 'dst';"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE providerrules ADD COLUMN pr_type enum('dst','src') default 'dst';"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE conflines ADD COLUMN owner_id int(11) default 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE lcrproviders ADD COLUMN priority int(11) default 1;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE activecalls ADD COLUMN provider_id int(11) default NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE users ADD COLUMN uniquehash varchar(10) default NULL;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE payments ADD COLUMN owner_id int(11) default 0;"
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE users ADD COLUMN c2c_service_active tinyint(4) DEFAULT 0;"

/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e "ALTER TABLE conflines DROP KEY name;"

#/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD -D "$DATABASE" -e ""


echo -e "\n NOTE: ERROR 1060 means that field is allready in DB and it is not added - you can ignore this error message."
echo -e "NOTE: ERROR 1091 means that column/key is allready deleted - you can ignore this error message.\ndone"
echo -e "\n-------- Inserting new values ----------\n"

/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD < /usr/src/mor/upgrade/db/upgrade_db_data.sql

#===========

SQL_SELECT=`mysql -u "$DB_USERNAME" -h "$HOST" -p"$DB_PASSWORD" -D "$DATABASE" -D "$DATABASE" -e 'select value from conflines where name = "Version" and owner_id = 0;' | grep 0.5`;
if [ "$SQL_SELECT" == "" ]; 
   then echo "MOR version number in a database is up to date";
   else mysql -u "$DB_USERNAME" -h "$HOST" -p"$DB_PASSWORD" -D "$DATABASE" -D "$DATABASE" -e 'update conflines set value="MOR 0.6 PRO" where name = "Version" and owner_id = 0 ;'         
fi
#============
echo -e "\ndone\n-------- MOR database upgraded ----------\n"

