#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh

#==================================================
clear

# get db data
mysql_connect_data


echo -e "\n-------- Starting MOR database upgrade to v0.8 ----------\n"
echo -e "\n--------- Making backup ---------\n"
   mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction "$DB_NAME" > /usr/src/mor/upgrade/0.8/backup/mor_backup.$$.sql ; 
   if [ $? != 0 ]; then echo "Database upgrade failed"; fi;
						                        
#compressing....
cd /usr/src/mor/upgrade/0.8/backup/
tar -czf mor_backup.$$.sql.tar.gz mor_backup.$$.sql
rm -rf mor_backup.$$.sql 


echo -e "done.\n --------- Upgrading tables ---------\n"


/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.8/upgrade_db_tables.sql

mysql_sql "UPDATE conflines SET value = '/usr/local/mor/backups' WHERE name = 'Backup_Folder';"


echo -e "done.\n---------- Altering tables ------------\n"

mysql_sql "ALTER TABLE users ADD generate_invoice tinyint(4) default '1';"

mysql_sql "ALTER TABLE servers ADD gateway_active tinyint(4) default 0;"

mysql_sql "ALTER TABLE cardgroups ADD tax_1 double  default 0;"
mysql_sql "ALTER TABLE cardgroups ADD tax_2 double  default 0;"
mysql_sql "ALTER TABLE cardgroups ADD tax_3 double  default 0;"
mysql_sql "ALTER TABLE cardgroups ADD tax_4 double  default 0;"

mysql_sql "ALTER TABLE users ADD tax_1 double  default 0;"
mysql_sql "ALTER TABLE users ADD tax_2 double  default 0;"
mysql_sql "ALTER TABLE users ADD tax_3 double  default 0;"
mysql_sql "ALTER TABLE users ADD tax_4 double  default 0;"

mysql_sql "ALTER TABLE callerids ADD banned int(4)  default 0;"
mysql_sql "ALTER TABLE callerids ADD created_at datetime NOT NULL;"
mysql_sql "ALTER TABLE callerids ADD updated_at datetime NOT NULL;"
mysql_sql "ALTER TABLE callerids ADD ivr_id int(11)  default 0;"
mysql_sql "ALTER TABLE callerids ADD comment BLOB  default NULL;"

mysql_sql "ALTER TABLE users ADD block_at date default '2008-01-01';"

mysql_sql "ALTER TABLE phonebooks ADD card_id int(11) NOT NULL default 0;"
mysql_sql "ALTER TABLE phonebooks ADD speeddial varchar(50);"
mysql_sql "ALTER TABLE phonebooks ADD updated_at datetime;"

mysql_sql "ALTER TABLE callerids ADD email_callback int(11) default '0';"

mysql_sql "ALTER TABLE users ADD block_at_conditional tinyint(4) default 15;"

mysql_sql "ALTER TABLE devices ADD faststart enum('no','yes') default 'yes';"
mysql_sql "ALTER TABLE devices ADD h245tunneling enum('no','yes') default 'yes';"

mysql_sql "ALTER TABLE cards ADD owner_id int(11) default 0;"
mysql_sql "ALTER TABLE cardgroups ADD owner_id int(11) default 0;"

mysql_sql "ALTER TABLE devices ADD latency double default 0;"
mysql_sql "ALTER TABLE devices ADD grace_time int(11) default 0;"

mysql_sql "ALTER TABLE lcrproviders ADD percent int(11) default 0;"

mysql_sql "ALTER TABLE users ADD block_conditional_use tinyint(4) default 0;"

mysql_sql "ALTER TABLE vouchers ADD active tinyint(4) default 1;"


mysql_sql "ALTER TABLE recordings ADD user_id INT NOT NULL default 0;"
mysql_sql "ALTER TABLE recordings ADD path varchar(255) NOT NULL default '';"
#mysql_sql "ALTER TABLE recordings ADD enabled TINYINT  NOT NULL default 1;"
#mysql_sql "ALTER TABLE recordings ADD forced TINYINT  NOT NULL default 1;"
mysql_sql "ALTER TABLE recordings ADD deleted TINYINT  NOT NULL default 0;"
mysql_sql "ALTER TABLE recordings ADD send_time DATETIME default NULL;"
mysql_sql "ALTER TABLE recordings ADD comment varchar(255) NOT NULL default '';"

mysql_sql "ALTER TABLE devices ADD recording_to_email TINYINT NOT NULL default 0;"
mysql_sql "ALTER TABLE devices ADD recording_keep TINYINT NOT NULL default 1;"
mysql_sql "ALTER TABLE devices ADD recording_email varchar(50) default NULL;"

mysql_sql "ALTER TABLE cards ADD callerid varchar(30) default NULL;"

mysql_sql "ALTER TABLE users ADD recording_enabled TINYINT NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD recording_forced_enabled TINYINT NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD recordings_email varchar(50) default NULL;"
mysql_sql "ALTER TABLE users ADD recording_hdd_quota INT NOT NULL default 100;"

mysql_sql "ALTER TABLE calls ADD originator_ip varchar(20) default '';"
mysql_sql "ALTER TABLE calls ADD terminator_ip varchar(20) default '';"

mysql_sql "ALTER TABLE providers ADD terminator_id INT(11) NOT NULL default 0;"
mysql_sql "CREATE INDEX cards_number_index ON cards(number);"
mysql_sql "CREATE INDEX cards_pin_index ON cards(pin);"
mysql_sql "CREATE INDEX destinations_direction_code_index ON destinations(direction_code);"
mysql_sql "CREATE INDEX directions_code_index ON directions (code);"
mysql_sql "ALTER TABLE calls ADD real_duration double NOT NULL default 0 COMMENT 'exact duration';"
mysql_sql "ALTER TABLE calls ADD real_billsec double NOT NULL default 0 COMMENT 'exact billsec';"
mysql_sql "ALTER TABLE users ADD warning_email_active TINYINT NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD warning_email_balance double NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD warning_email_sent TINYINT default 0;"
mysql_sql "ALTER TABLE cardgroups ADD tax_id INTEGER NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD tax_id INTEGER NOT NULL default 0;"
mysql_sql "ALTER TABLE cardgroups DROP COLUMN tax_1, DROP COLUMN tax_2, DROP COLUMN tax_3, DROP COLUMN tax_4;"
mysql_sql "ALTER TABLE ccorders ADD tax_percent FLOAT NOT NULL default 0;"
mysql_sql "ALTER TABLE users ADD invoice_zero_calls TINYINT NOT NULL default 1;"
mysql_sql "ALTER TABLE invoices ADD invoice_type varchar(20) default NULL;"
mysql_sql "ALTER TABLE c2c_invoices ADD invoice_type varchar(20) default NULL;"

mysql_sql "ALTER TABLE ccorders ADD tax_percent double default '0';"

mysql_sql "ALTER TABLE users ADD acc_group_id INT NOT NULL default 0;"
mysql_sql "ALTER TABLE actions ADD target_type VARCHAR(255) default '' COMMENT 'target type user/device/cardgroup...';"
mysql_sql "ALTER TABLE actions ADD target_id   INT   default NULL COMMENT 'id of target ';"

mysql_sql "ALTER TABLE recordings ADD size FLOAT NOT NULL default 0 COMMENT 'Recording file size';"

mysql_sql "ALTER TABLE acc_rights ADD permission_group varchar(50) NOT NULL default '' COMMENT 'Permission group';"

mysql_sql "ALTER TABLE devices ADD lastms int(11) default 0;"

mysql_sql "ALTER TABLE recordings ADD uniqueid varchar(30) default '' COMMENT 'Name of recording';"
mysql_sql "ALTER TABLE recordings ADD visible_to_user TINYINT default 1 COMMENT 'Can user see it?';"
mysql_sql "ALTER TABLE recordings ADD dst_user_id int(11) default 0 COMMENT 'User which received call';"

mysql_sql "ALTER TABLE recordings DROP COLUMN forced;"
mysql_sql "ALTER TABLE recordings DROP COLUMN enabled;"

mysql_sql "ALTER TABLE devices ADD record_forced TINYINT default 0 COMMENT 'Force recording for this device?';"

# --- indexes ---
#mysql_sql "CREATE INDEX dt USING BTREE ON ratedetails(daytype);"

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD -e "USE mor; "

mysql_sql "ALTER TABLE \`calls\` DROP INDEX \`7\`, DROP INDEX \`3\`, DROP INDEX \`2\`, DROP INDEX \`9\`, DROP INDEX \`4\`, DROP INDEX \`5\`, DROP INDEX \`id\`, DROP INDEX \`calldate_2\`, DROP INDEX \`calldate_3\`, DROP INDEX \`dst\`, DROP INDEX \`dst_2\`;"


if [ $VERBOSE == 1 ]; then
   echo -e "\nDON'T PANIC!!!\n"
   echo "NOTE: ERROR 1060 means that field is allready in DB and it is not added - you can ignore this error message."
   echo "NOTE: ERROR 1061 means that key is allready in DB and it is not added - you can ignore this error message."
   echo "NOTE: ERROR 1091 means that column/key is allready deleted - you can ignore this error message."
fi;

echo -e "\ndone.\n\n-------- Inserting new values ----------\n"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.8/upgrade_db_data.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/0.8/permissions.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/hangupcausecodes.sql


#mysql_sql "UPDATE extlines SET app = 'GotoIf', appdata = '\$["\${MOR_CARD_USED}" != ""]?mor_callingcard|s|1' WHERE context = 'mor' AND exten = '_X.' AND priority = 3;"

mysql_sql "UPDATE conflines SET value2 = 1 WHERE conflines.name = 'Tax_1';"

#mysql_sql "UPDATE conflines SET value = 'MOR 0.8' WHERE name = 'Version' AND owner_id = 0;"


cd /usr/src/mor/db/0.8/
./import_changes.sh


echo -e "done.\n-------- MOR database upgraded ----------\n\n"

