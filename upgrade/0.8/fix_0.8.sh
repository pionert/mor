#!/bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh


./check_calls.sh


mkdir -p /usr/local/mor
mkdir -p /usr/local/mor/backups


yum -y install curl-devel


if [ $LOCAL_INSTALL == 0 ]; then

    #backup
    randir=`date +%H%M%S%N`
    if [ -d /home/mor ]; then
        mkdir -p /usr/local/mor/backups/GUI
	tar -cvf /usr/local/mor/backups/GUI/$randir.tar.gz /home/mor --exclude "/home/mor/log"
    fi


    # upgrade install script files
    svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor_upgraded
    
fi

# get db data
mysql_connect_data

echo "Importing MySQL Permissions"
/usr/bin/mysql -h "$DB_HOST" -u root --password="" < /usr/src/mor/db/mysqlpermissions.sql
if [ "$?" != "0" ]; then    #if inserting without a password fails
    /usr/bin/mysql -h "$DB_HOST" -u root -p < /usr/src/mor/db/mysqlpermissions.sql
fi

sleep 5


# new script for audio conversion
cp -f /usr/src/mor/sh_scripts/convert_mp3wav2astwav.sh /usr/local/mor

# auto-dialer upgrade to support callerid
cd /usr/src/mor/mor_ad/agi
./install.sh
cd /usr/src/mor/mor_ad/app
./install.sh
cp -f /usr/src/mor/mor_ad/mor_ad_cron /home/mor_ad/

# changing cronjob logic from crontab -e to /etc/cron.d
#crontab_add "mor_ad_cron" "*/5 * * * * /home/mor_ad/mor_ad_cron >> /home/mor_ad/mor_ad_cron.log" "Auto-Dialer crontab installed"
#crontab_add "daily_actions" "0 0 * * * wget -o /dev/null -O /dev/null http://127.0.0.1/billing/callc/daily_actions" "Daily Actions crontab installed"
#crontab_add "hourly_actions" "0 * * * * wget -o /dev/null -O /dev/null http://127.0.0.1/billing/callc/hourly_actions"  "Hourly actions crontab installed"
cp -fr /usr/src/mor/upgrade/0.8/mor_cronjobs/mor_* /etc/cron.d/
cp -fr /usr/src/mor/upgrade/0.8/mor_cronjobs/ntpdate /etc/cron.d/


# fax2email upgrade
cd /usr/src/mor/fax2email/agi
./install.sh

# default audio (silence for 1s) for auto-dialer
cp -f /usr/src/mor/mor_ad/silence1.wav /home/mor/public/ad_sounds/

# copy appropriate upgrade files for gui 
cp -fr /usr/src/mor/upgrade/0.8/gui_upgrade.sh /home/mor
cp -fr /usr/src/mor/upgrade/0.8/gui_upgrade_light.sh /home/mor



# sound files
#rm /usr/src/mor_sounds.tgz
#download_packet mor_sounds.tgz
#extract_gz mor_sounds.tgz
#cp -r /usr/src/sounds/* /var/lib/asterisk/sounds


if [ $LOCAL_INSTALL == 0 ]; then

    # db backup-upgrade
    /usr/src/mor/upgrade/0.8/upgrade_db.sh


    # gui fixes
    /usr/src/mor/upgrade/0.8/gui_upgrade.sh
fi


# Various GUI upgrades
cd /usr/src/mor/upgrade/0.8
./various_gui_upgrades.sh

# Various APP upgrades
cd /usr/src/mor/upgrade/0.8
./various_app_upgrades.sh

ln -s /usr/src/mor /root/mor_dir

cp -fr /usr/src/mor/asterisk-conf/extensions_mor_ad.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_pbxfunctions.conf /etc/asterisk/

asterisk -vvvvrx 'extensions reload'

if [ -r /etc/my.cnf ]; then
  insert_line_after_pattern "\[mysqld\]" "max_allowed_packet=100M" "/etc/my.cnf" ;
fi


#scripts - not ncessary here, done in various_app_upgrades.sh
#cd /usr/src/mor/scripts
#./install.sh

# log folder 
mkdir -p /var/log/mor

#/etc/init.d/mysqld restart
#asterisk -vvvvvrx 'module reload'

#netstat script to send network details by email
cp -fr /usr/src/mor/sh_scripts/net_info /usr/bin/


# fix ad folder problems
mkdir -p /home/mor/public/ad_sounds
chmod 777 /home/mor/public/ad_sounds


# clean cron from previous incarnations
cd /usr/src/mor/sh_scripts
./clean_cron.sh

# install logrotate
cd /usr/src/mor/sh_scripts
./logrotate_run.sh

touch /tmp/mor_debug.txt
chmod 777 /tmp/mor_debug.txt
chmod 777 /home/mor/public/images/logo/

mkdir -p /var/log/asterisk/cdr-csv
mkdir -p /var/log/asterisk/cdr-custom

# possible error fix
ln -s /usr/bin/lame /usr/local/bin/lame

# recording fix
chmod 777 /var/spool/asterisk/monitor

# silence files
mkdir -p /var/lib/asterisk/sounds/mor/ivr_voices/silence
cp -fr /usr/src/mor/sounds/silence/* /var/lib/asterisk/sounds/mor/ivr_voices/silence

# check and fix gem version
cd /usr/src/mor/sh_scripts
./gem_version_check_and_repair.sh

# backups fix
chmod -R 777 /usr/local/mor/backups

# my.cnf configure
#cd /usr/src/mor/sh_scripts
#./configure_mycnf.sh

cp -f /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_restore.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_backup.sh /usr/local/mor/


