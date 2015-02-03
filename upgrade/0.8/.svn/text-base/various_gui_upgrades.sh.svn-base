#!/bin/sh
#==== Includes=====================================
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================


echo -e "\n======== environment.rb upgrade ========"

    # addons

    CCLASSACTIVE=`cat /home/mor/config/environment.rb | grep -i "CCLASS_Active"`;
    if [ "$CCLASSACTIVE" == "" ]; then echo -e "\nCCLASS_Active = 0" >> /home/mor/config/environment.rb; fi

    REC=`cat /home/mor/config/environment.rb | grep -i "REC_Active"`;
    if [ "$REC" == "" ]; then echo -e "\nREC_Active = 0" >> /home/mor/config/environment.rb; fi

	    
_done;


cp -fr /usr/src/mor/upgrade/0.8/gui_upgrade.sh /home/mor
cp -fr /usr/src/mor/upgrade/0.8/gui_upgrade_light.sh /home/mor


# backups
cd /usr/src/mor/sh_scripts
./enable_backup.sh


#email2callback
cp -fr /usr/src/mor/sh_scripts/mor_email2callback.sh /usr/local/mor
cd /usr/src/mor/sh_scripts
./install_email2callback.sh

#sipsak install
cd /usr/src/mor/sh_scripts
./sipsak_install.sh


# recording script
#cp -fr /usr/src/mor/sh_scripts/mor_wav2mp3 /usr/local/mor
rm -f /bin/mor_wav2mp3

#sip_check.sh
cp -fr /usr/src/mor/sh_scripts/sip_check.sh /usr/local/mor

#aes script
#cp -fr /usr/src/mor/sh_scripts/generate_aes_hash.php /usr/local/mor

#press_enter_to_exit;



#validation
wget -o /dev/null -O /dev/null http://127.0.0.1/billing/validation/validate

if [ $LOCAL_INSTALL == 1 ]; then
    #gui files for local installation
    cp -fr /usr/src/other/mor8_gui/* /home

    #/page
    cp -fr /usr/src/mor/upgrade/gui/index.html /var/www/html
    cp -fr /usr/src/mor/upgrade/gui/mor_box.png /var/www/html

fi

apache_restart;
