#! /bin/bash
   #======= includes ===========
      cd /usr/local/mor
      . install_configs.sh
      . mor_install_functions.sh
   #============================

clear;
echo -e "============================================
Asterisk restore script (last resort)
============================================
The script restores:
\t /etc/asterisk
\t /usr/lib/asterisk
\t /var/lib/asterisk
This script must be executed locally
============================================"

#======================= Main =======================================
   echo "Do you want to continue (y)?";
   read a;

if [ $a == "y" ]; then 
   asterisk_stop
   echo Restoring /etc/asterisk....;
   
   cp -R "$_BACKUP_FOLDER"/restore/asterisk_back_etc /etc/asterisk
      backups_error_output "Asterisk_last_resort_failed: /etc/asterisk"

   echo Restoring /usr/lib/asterisk....;
   cp -R "$_BACKUP_FOLDER"/restore/asterisk_back_usr_lib /usr/lib/asterisk
      backups_error_output "Asterisk_last_resort_failed: /usr/lib/asterisk"

   echo Restoring /var/lib/asterisk....;
   cp -R "$_BACKUP_FOLDER"/restore/asterisk_back_var_lib /var/lib/asterisk
      backups_error_output "Asterisk_last_resort_failed: /var/lib/asterisk"
   echo "Done";

   /etc/init.d/asterisk start

else echo Other button pressed, assuming "No"; exit 1; fi
