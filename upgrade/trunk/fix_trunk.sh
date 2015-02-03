#!/bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

#/usr/src/mor/sh_scripts/check_calls.sh

mkdir -p /usr/local/mor/backups


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

# no need /9/fix.sh does the same
#echo "Importing MySQL Permissions"
#/usr/bin/mysql -h "$DB_HOST" -u root -p < /usr/src/mor/db/mysqlpermissions.sql
#sleep 5

# copy appropriate upgrade files for gui 
cp -fr /usr/src/mor/upgrade/trunk/gui_upgrade.sh /home/mor
cp -fr /usr/src/mor/upgrade/trunk/gui_upgrade_light.sh /home/mor


# db backup-upgrade
/usr/src/mor/db/trunk/import_changes.sh

# gui fixes
/home/mor/gui_upgrade.sh


# anipin dialplan for * press
cp -fr /usr/src/mor/asterisk-conf/10/extensions_mor_anipin.conf /etc/asterisk/

# all other files
cp -fr /usr/src/mor/asterisk-conf/extensions_mor.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/extensions_mor_ad.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/10/extensions_mor_callingcard.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/extensions_mor_pbxfunctions.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/modules.conf /etc/asterisk/

cp -fr /usr/src/mor/asterisk-conf/10/chan_skype.conf /etc/asterisk/

cp -fr /usr/src/mor/asterisk-conf/sip_didww.conf /etc/asterisk/

#copy only if not present already
if [ ! -f /etc/asterisk/extensions_mor_didww.conf ]; then
    cp /usr/src/mor/asterisk-conf/extensions_mor_didww.conf /etc/asterisk/
fi
    
#copy only if not present already
if [ ! -f /etc/asterisk/extensions_mor_external_did.conf ]; then
    cp /usr/src/mor/asterisk-conf/9/extensions_mor_external_did.conf /etc/asterisk/
fi


# this on is disabled because we do not want to overwrite sip.conf and iax2.conf
#cp -fr /usr/src/mor/asterisk-conf/9/* /etc/asterisk/

asterisk -vvvvvvrx 'extensions reload'

# agi fixes
cd /usr/src/mor/agi
./install.sh

# ami
cd /usr/src/mor/ami
./install.sh

# calllog
mkdir -p /var/log/mor/calllog
cp -fr /usr/src/mor/sh_scripts/backup_calllog.sh /usr/local/mor/

# cronjobs
cp -fr /usr/src/mor/upgrade/trunk/cronjobs/mor_daily_actions /etc/cron.d/
cp -fr /usr/src/mor/upgrade/trunk/cronjobs/mor_minute_actions /etc/cron.d/

# do not upgrade gui for trunk everyday
rm -rf /etc/cron.d/mor_gui_upgrade

/etc/init.d/crond restart

mkdir -p /var/log/asterisk/cdr-csv
mkdir -p /var/log/asterisk/cdr-custom

# possible error fix
ln -s /usr/bin/lame /usr/local/bin/lame

# recording fix
chmod 777 /var/spool/asterisk/monitor

# cc new logic sound files
cd /usr/src/mor/sh_scripts
./install_mor9_sounds.sh

# check and fix gem version
cd /usr/src/mor/sh_scripts
./gem_version_check_and_repair.sh

# backups fix
chmod -R 777 /usr/local/mor/backups

# my.cnf configure
cd /usr/src/mor/sh_scripts
./configure_mycnf.sh

# persmission problem fix
chmod 777 /var/log/httpd
chmod 777 /var/log/httpd/fcgidsock

cp -f /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_restore.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_backup.sh /usr/local/mor/

touch /var/log/mor/monitorings.log
chmod 777 /var/log/mor/monitorings.log
    
/usr/src/mor/test/scripts/various/yum-updatesd.sh

cd /usr/src/mor/scripts
./install.sh
