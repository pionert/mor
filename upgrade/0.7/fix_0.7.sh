#!/bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

mkdir -p /usr/local/mor
mkdir -p /usr/local/mor/backups

randir=`date +%H%M%S%N`
if [ -d /home/mor ]; then
    mkdir -p /usr/local/mor/backups/GUI
    tar -cvf /usr/local/mor/backups/GUI/$randir.tar.gz /home/mor --exclude "/home/mor/log"
fi


if [ $LOCAL_INSTALL == 0 ]; then
    # upgrade install script files
    svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
fi

# get db data
mysql_connect_data

# new script for audio conversion
cp -f /usr/src/mor/sh_scripts/convert_mp3wav2astwav.sh /usr/local/mor

# auto-dialer upgrade to support callerid
# tellbalance to disable ghost_min on balance
cd /usr/src/mor/mor_ad/agi
./install.sh
cd /usr/src/mor/mor_ad/app
./install.sh
cp -f /usr/src/mor/mor_ad/mor_ad_cron /home/mor_ad/

#crontab_add "mor_ad_cron" "*/5 * * * * /home/mor_ad/mor_ad_cron >> /home/mor_ad/mor_ad_cron.log" "Auto-Dialer crontab installed"
#crontab_add "daily_actions" "0 0 * * * wget -o /dev/null -O /dev/null http://127.0.0.1/billing/callc/daily_actions" "Daily Actions crontab installed"

# fax2email upgrade
cd /usr/src/mor/fax2email/agi
./install.sh

# default audio (silence for 1s) for auto-dialer
cp -f /usr/src/mor/mor_ad/silence1.wav /home/mor/public/ad_sounds/

# copy appropriate upgrade files for gui 
cp -fr /usr/src/mor/upgrade/0.7/gui_upgrade.sh /home/mor
cp -fr /usr/src/mor/upgrade/0.7/gui_upgrade_light.sh /home/mor

# db backup-upgrade
/usr/src/mor/upgrade/0.7/upgrade_db.sh

if [ $LOCAL_INSTALL == 0 ]; then
    # gui fixes
    /usr/src/mor/upgrade/0.7/gui_upgrade.sh
fi

# sound files
#rm /usr/src/mor_sounds.tgz
#download_packet mor_sounds.tgz
#extract_gz mor_sounds.tgz
#cp -r /usr/src/sounds/* /var/lib/asterisk/sounds

# recordings
ln -s /var/spool/asterisk/monitor /home/mor/public/recordings
cp -u /usr/src/mor/scripts/mor_wav2mp3 /bin/


# IVR
if [ -d /home/mor/public/ivr_voices ]; then
  echo "ivr_voices folder ok"
else
  mkdir -p /home/mor/public/ivr_voices
fi
chmod 777 -R /home/mor/public/ivr_voices/
ln -s /home/mor/public/ivr_voices /var/lib/asterisk/sounds/mor/ivr_voices
	

# ----- calling cards -----

cp /usr/src/mor/asterisk-conf/extensions_mor_callingcard.conf /etc/asterisk/
CC=`cat /etc/asterisk/extensions_mor.conf | grep -i "extensions_mor_callingcard.conf"`;
if [ "$CC" == "" ]; then echo -e "\n#include extensions_mor_callingcard.conf" >> /etc/asterisk/extensions_mor.conf; fi

cp -fr /usr/src/mor/asterisk-conf/extensions_mor_pbxfunctions.conf /etc/asterisk/    

ln -s /usr/src/mor /root/mor_dir

# broken code
#cat /etc/asterisk/sip.conf | sed 's/;useragent=.*/useragent=MOR Softswitch/g' >/etc/asterisk/sip.conf 
#cat /etc/asterisk/sip.conf | sed 's/.*useragent=.*/useragent=MOR Softswitch/g' >/etc/asterisk/sip.conf

# -- asterisk restart script --
#cp -f /usr/src/mor/sh_scripts/asterisk_nice_restart.sh /usr/local/mor
#crontab_add "asterisk_nice_restart" "0 0 * * * /usr/local/mor/asterisk_nice_restart.sh"  "Asterisk nice restart crontab installed\t\t\t\t"


#scripts
cd /usr/src/mor/scripts
./install.sh

if [ -r /etc/my.cnf ]; then
    insert_line_after_pattern "\[mysqld\]" "max_allowed_packet=100M" "/etc/my.cnf" ;
fi


/usr/src/mor/sh_scripts/install_hgc_sounds.sh

# fax apps just in case
cd /usr/src/mor/fax2email/additional_apps
make clean  
make  
make install  

#/page
if [ $LOCAL_INSTALL == 1 ]; then
    cp -fr /usr/src/mor/upgrade/gui/index.html /var/www/html
    cp -fr /usr/src/mor/upgrade/gui/mor_box.png /var/www/html
fi

#validation
wget -o /dev/null -O /dev/null http://127.0.0.1/billing/validation/validate

#/etc/init.d/mysqld restart
asterisk -vvvvrx 'module reload'

# script to send network details by email
cp -fr /usr/src/mor/sh_scripts/net_info /usr/bin/

mkdir -p /home/mor/public/ad_sounds
chmod 777 /home/mor/public/ad_sounds

chmod 777 /tmp/mor_debug.txt
