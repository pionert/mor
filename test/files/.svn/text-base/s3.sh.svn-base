#!/bin/sh
# Author: Mindaugas Mardosas
# Year:   2012-2013
# About:  This script creates backups for MOR DB into Amazon S3 Cloud\
#
# Originally taken from:
# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

. /usr/src/mor/test/framework/bash_functions.sh

if [ ! -f /root/.s3cfg ]; then
    report "Kolmisoft Amazon S3 backup tool installed not properly, please reinstall"   1
    exit 1
fi

mysql_connect_data_v2      > /dev/null # getting MySQL connection details from various configs

#============ Functions ======================


exit_script_and_send_email_if_not_enough_free_space()
{
    #   Author:   Mindaugas Mardosas
    #   Year:     2013
    #   About:    This functions checks if there is enough free space, if not - sends email to MOR admin and exits the script
    #

    check_if_there_is_enough_space_to_dump_and_archive_mor_db "$TMP_PATH"
    if [ "$?" != "0" ]; then
        # Not enough FREE space, send email to admin
        get_mor_admin_smtp_settings
        get_mor_admin_email
        if [ "$?" == "0" ] && [ "$EMAIL_SENDING_ENABLED" == "1" ]; then
            default_interface_ip
            /usr/local/mor/sendEmail -f "$ADMIN_EMAIL" -t "$ADMIN_EMAIL"  -u "[MOR SERVER: $DEFAULT_IP] Not enough FREE space for S3 backup" -m "Not enough free space in server $DEFAULT_IP. At least $SPACE_NEEDED_FOR_BACKUP bytes are needed" -s "$SMTP_SERVER" -o reply-to="$SMTP_EMAIL_FROM" tls=auto  -xu "$SMTP_USERNAME" -xp "$SMTP_PASSWORD"
            exit 1
        else
            report "Not enough FREE space to create S3 backup" 1
            exit 1
        fi
    fi
}
#=============================================

# change these variables to what you need
MYSQLROOT=$DB_USERNAME
MYSQLPASS=$DB_PASSWORD
#S3BUCKET=`grep bucket_name /root/.s3cfg | awk '{print $3}'`

S3BUCKET="kolmibackups"

FILENAME="mor_db"
DATABASE="$DB_NAME"
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=`grep USER_PATH /root/.s3cfg | awk '{print $3}'`
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/

MYSQLDUMPPATH=

if [ ! -f "/usr/local/mor/s3_configuration" ]; then
    TMP_PATH=~/
else
    TMP_PATH=`awk -F"#" '{print $1}' /usr/local/mor/s3_configuration | grep TMP_DIR | awk -F"=" '{print $2}' | head -n 1`
fi

exit_script_and_send_email_if_not_enough_free_space

DATESTAMP=$(date +".%Y.%m.%d")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
	if [ ${DAY} = "01" ]; then
        	PERIOD=month
	elif [ ${DAYOFWEEK} = "Sunday" ]; then
        	PERIOD=week
	else
       		PERIOD=day
	fi	
fi

echo "Selected period: $PERIOD."

echo "Starting backing up the database to a file..."

# dump all databases
${MYSQLDUMPPATH}mysqldump -h "$DB_HOST" --quick --single-transaction --user=${MYSQLROOT} --password=${MYSQLPASS} ${DATABASE} --ignore-table=mor.call_logs --ignore-table=mor.sessions > ${TMP_PATH}${FILENAME}.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

tar czf ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz ${TMP_PATH}${FILENAME}.sql

echo "Done compressing the backup file."

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
echo "New backup uploaded."

# Doing rotation, keeping last 2 backups in each dir: 2 weekly, 2 monthly, 2 daily backups
echo "Doing backups rotation. Deleting oldest backups for period: $PERIOD"
s3cmd ls s3://${S3BUCKET}/${S3PATH}${PERIOD}/ | sort -r | (read; read; cat) | awk '{print $NF }'| while read backupas; do
    echo "Removing old backup: s3cmd del $backupas";
    s3cmd del $backupas;
done

echo "Removing the cache files..."
# remove databases dump
if [ -f "${TMP_PATH}${FILENAME}.sql" ]; then  # Protection, in order the whole directory would not be deleted
    rm -rf ${TMP_PATH}${FILENAME}.sql
else
    echo "${TMP_PATH}${FILENAME}.sql not found"
fi

if [ -f "${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz" ]; then # Protection, in order the whole directory would not be deleted
    rm -rf ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz
else
    echo "${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz not found"
fi

echo "Files removed."
echo "All done."