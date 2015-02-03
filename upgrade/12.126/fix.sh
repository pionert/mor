#!/bin/sh
# Company: Kolmisfot


# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh

do_not_allow_to_downgrade_if_current_gui_higher_than 120

#/usr/src/mor/sh_scripts/check_calls.sh

#trac 10891
mysql_connect_data
mor_branch=`svn info /home/mor | grep URL | awk -F"/" '{print $7}'`
if [ "$mor_branch" != "12.126" ]; then
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "DELETE FROM conflines WHERE name='REC_Active' and owner_id='0';"
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "INSERT INTO conflines (name,value,owner_id) VALUES ('REC_Active','1','0');"
fi

mkdir -p /usr/local/mor/backups
yum -y install curl-devel 
yum -y --enablerepo=epel install whatmask

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


yum -y install zip bind-utils

# Adding symlinks appropriate upgrade files for gui

rm -rf /home/mor/gui_upgrade.sh /home/mor/gui_upgrade_light.sh

report "Adding symlinks to /usr/src/mor/upgrade/12.126/gui_upgrade_light.sh and /usr/src/mor/upgrade/12.126/gui_upgrade.sh" 3
ln -s /usr/src/mor/upgrade/12.126/gui_upgrade_light.sh /home/mor/gui_upgrade_light.sh
ln -s /usr/src/mor/upgrade/12.126/gui_upgrade.sh /home/mor/gui_upgrade.sh
chmod +x /home/mor/gui_upgrade_light.sh /home/mor/gui_upgrade.sh

# db backup-upgrade
/usr/src/mor/db/12.126/import_changes.sh

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

#Asterisk 1.8 configs
asterisk_current_version
if [ "$ASTERISK_BRANCH" == "1.8" ]; then
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/asterisk.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/cdr.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/cli_aliases.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/extensions_mor.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/extensions_mor_anipin.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/extensions_mor_callingcard.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/extensions_mor_pbxfunctions.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/modules.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/res_fax.conf /etc/asterisk/
    cp -fr /usr/src/mor/asterisk-conf/ast_1.8/sip_didww.conf /etc/asterisk/
fi

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
cp -fr /usr/src/mor/upgrade/12.126/cronjobs/mor_daily_actions /etc/cron.d/
cp -fr /usr/src/mor/upgrade/12.126/cronjobs/mor_minute_actions /etc/cron.d/

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

#mor ad fix
cp -fr /usr/src/mor/mor_ad/agi/mor_ad_agi.c /home/mor_ad/agi
cd /home/mor_ad/agi
./install.sh


if [ "$ASTERISK_BRANCH" == "1.8" ]; then
    #Asterisk 1.8 IVR fix
    cd /usr/src/mor/sh_scripts/asterisk/scripts
    ./install.sh
    
    #--- disallow stupid transfers to mor_local by local devices http://trac.kolmisoft.com/trac/changeset/32775
    cp -rf /usr/src/mor/asterisk-conf/ast_1.8/extensions.conf /etc/asterisk/extensions.conf

    asterisk -rx 'dialplan reload'
    
    #---- end ivr sound files --- lines below makes copy of cc_callingcard_choices.wav in every language to create new end_ivr sound files if does not exist already. Check trac 6415 for details.
    end_ivr_new_files="ani_end_ivr_1 ani_end_ivr_2 cc_end_ivr_1 cc_end_ivr_4 cc_end_ivr_5 cc_end_ivr_6 "
    end_ivr_new_files_array=($end_ivr_new_files)
    sound_language_directories=`ls -l /var/lib/asterisk/sounds/mor/ivr_voices/ | grep "^d" | awk '{print $9}' | awk '{printf "%s " ,$1}'`
    sound_language_directories_array=($sound_language_directories)
    for dir_element in $(seq 0 $((${#sound_language_directories_array[@]} - 1)))
    do
        if [ -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_callingcard_choices.wav" ]; then
            for file_element in $(seq 0 $((${#end_ivr_new_files_array[@]} - 1)))
            do
                if [ ! -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/${end_ivr_new_files_array[$file_element]}.wav" ]; then
                    cp "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_callingcard_choices.wav" "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/${end_ivr_new_files_array[$file_element]}.wav"
                fi
            done
        fi
        if [ -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_please_enter_number.wav" ] && [ ! -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_end_ivr_2.wav" ]; then
            cp "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_please_enter_number.wav" "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_end_ivr_2.wav"
        fi
    done
    
fi