#!/bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh

#/usr/src/mor/sh_scripts/check_calls.sh

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
    svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
    
fi

# get db data
mysql_connect_data

# Adding symlinks appropriate upgrade files for gui

rm -rf /home/mor/gui_upgrade.sh /home/mor/gui_upgrade_light.sh

report "Adding symlinks to /usr/src/mor/upgrade/10/gui_upgrade_light.sh and /usr/src/mor/upgrade/10/gui_upgrade.sh" 3
ln -s /usr/src/mor/upgrade/10/gui_upgrade_light.sh /home/mor/gui_upgrade_light.sh
ln -s /usr/src/mor/upgrade/10/gui_upgrade.sh /home/mor/gui_upgrade.sh
chmod +x /home/mor/gui_upgrade_light.sh /home/mor/gui_upgrade.sh

# db backup-upgrade
/usr/src/mor/db/10/import_changes.sh

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

# calllog
mkdir -p /var/log/mor/calllog
cp -fr /usr/src/mor/sh_scripts/backup_calllog.sh /usr/local/mor/

# cronjobs
cp -fr /usr/src/mor/upgrade/10/cronjobs/mor_daily_actions /etc/cron.d/

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
#/usr/src/mor/sh_scripts/install_mor9_sounds.sh

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

# ivr fix
mkdir -p /home/mor/public/ivr_voices/silence
chmod -R 777 /home/mor/public/ivr_voices/silence

chmod 777 /home/mor/public
chmod 777 /home/mor/public/ivr_voices
chmod 755 -R /home/mor/public/ivr_voices
chmod 777 /var/lib/asterisk/sounds/mor/
chmod 777 /var/lib/asterisk/sounds/
chmod 777 /var/lib/asterisk/
chmod 777 /var/lib/
chmod 777 /var/
chown -R apache: /home/mor/public/ivr_voices
