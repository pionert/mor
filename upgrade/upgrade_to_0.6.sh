#!/bin/sh

#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#===============
BACKUP_FOLDER_PATH="/var/mor_backups"
#===============

WITH_STOPS=1

if [ -d "$BACKUP_FOLDER_PATH" ]; 
   then 
      echo "$BACKUP_FOLDER_PATH    Directory exists - OK";
   else
      echo "The MOR backup directory does not exist, the script will create it for you";
      mkdir -p "$BACKUP_FOLDER_PATH";     
fi

mor_gui_backup() 
{
cp -R /home/mor /home/mor_gui_backup
cd /home/mor_gui_backup
rm -rf /home/mor_gui_backup/log
cd ..
tar -czf mor_gui_backup.tar.gz mor_gui_backup
rm -rf /home/mor_gui_backup

mv mor_gui_backup.tar.gz "$BACKUP_FOLDER_PATH";

if [ -r "$BACKUP_FOLDER_PATH"/mor_gui_backup.tar.gz ]; 
   then echo "The mor_gui_backup was successfully created";
   else echo "There was an error, the mor_gui_backup creation was unsuccessful";
fi;
}
mor_gui_backup

asterisk_conf_back() 
{
cd /etc
tar -czf asterisk_backup.tar.gz asterisk
mv asterisk_backup.tar.gz "$BACKUP_FOLDER_PATH"/asterisk_backup.tar.gz

if [ -r "$BACKUP_FOLDER_PATH"/mor_gui_backup.tar.gz ]; 
   then echo "The asterisk_backup was successfully created";
   else echo "There was an error, the asterisk_backup creation was unsuccessful";
fi;
}
asterisk_conf_back




wait_user() {
    if [ $WITH_STOPS == 1 ]
    then      
        echo -e "\n\nPress enter to continue"
        read
        echo -e "\n\n"    
    fi
}

# Upgrade DB
cd /usr/src/mor/upgrade/db
./upgrade_db.sh

wait_user;

# Upgrade /home/mor/config/environemnt.rb and /etc/asterisk/mor.conf
cd /usr/src/mor/upgrade/conf_files
./env_rb_mor_conf_update.sh

wait_user;

# Upgrade GUI from SVN
cd /usr/src/mor/upgrade/gui
./gui_upgrade.sh

wait_user;

# Upgrade Asterisk + Addons
cd /usr/src/mor/upgrade/asterisk
./asterisk_upgrade.sh

wait_user;
#====================================================================================

#===============================================
if [ -r /etc/asterisk/extensions_mor_pbxfunctions.conf ]; 
   then
      if [ -r /etc/asterisk/extensions_mor_pbxfunctions.conf_mor_backup$$ ]; #for security, if the script would be run multiple times
         then echo "The backup of /etc/asterisk/extensions_mor_pbxfunctions.conf was already made";
         else 
            cp /etc/asterisk/extensions_mor_pbxfunctions.conf /etc/asterisk/extensions_mor_pbxfunctions.conf_mor_backup$$
            cp /usr/src/mor/asterisk-conf/extensions_mor_pbxfunctions.conf /etc/asterisk/extensions_mor_pbxfunctions.conf
      fi      
fi;

if [ -r /etc/asterisk/extensions_mor.conf ]; 
   then
      EXISTS_LINE=`cat /etc/asterisk/extensions_mor.conf | grep "#include extensions_mor.conf"`;
      if [ "$EXISTS_LINE" == "" ]; 
         then echo "#include extensions_mor.conf" >> /etc/asterisk/extensions_mor.conf;            
      fi;
   else echo "/etc/asterisk/extensions_mor.conf is not readable or doesn't exist"
fi;

if [ -r /etc/asterisk/udptl.conf ];
then
      if [ -r /etc/asterisk/udptl.conf_mor_backup$$ ]; #for security, if the script would be run multiple times
         then echo "The backup of /etc/asterisk/udptl.conf was already made";
         else 
            cp /etc/asterisk/udptl.conf /etc/asterisk/udptl.conf_mor_backup$$
            cp /usr/src/mor/asterisk-conf/udptl.conf /etc/asterisk/udptl.conf
      fi      
fi;


   download_packet mor_sounds.tgz
   extract_gz mor_sounds.tgz
   cp -fr /usr/src/sounds/* /var/lib/asterisk/sounds  #changed from cp -fr /usr/src/mor/sounds/* /var/lib/asterisk/sounds to ...


         #if [ -x /usr/bin/rsync ];
         #   then 
         #      rsync -R --ignore-existing /usr/src/mor/sounds/* /var/lib/asterisk/sounds;
         #   else
         #      if [ -r /etc/redhat-release ]; then yum -y install rsync; fi
         #      if [ -r /etc/debian_version ]; then apt-get install rsync; fi 
         #      rsync -R --ignore-existing /usr/src/mor/sounds/* /var/lib/asterisk/sounds;
         #fi
         # wait_user;
wait_user;
#================Autodialer===============


AUTODIALER_INSTALLED=`crontab -u $USER -l | grep mor_ad_cron`;
if [ "$AUTODIALER_INSTALLED" != "" ]; 
   then 
      cd /usr/src/mor/mor_ad/app/
      /usr/src/mor/mor_ad/app/install.sh
      rm -rf /home/mor/public/ad_sounds
      ln -s /var/lib/asterisk/sounds/mor/ad /home/mor/public/ad_sounds
fi; 

#==============================================
#LOG_IS_SET=`cat /etc/logrotate.conf | grep /home/mor/log`;
#if [ "$LOG_IS_SET" == "" ]; 
#   then 
#      . /usr/src/mor/logrotate.sh
#      logrotate_cfg
#   else echo "Logrotate is already set"
#fi

cp -R /usr/src/mor/agi/* /home/mor_ad/agi/
cd /home/mor_ad/agi/
./install.sh
wait_user;
 

cp -R /usr/src/mor/asterisk-conf/* /etc/asterisk

