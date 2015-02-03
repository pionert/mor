#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================
echo -e "\n======== Sound files ========\n"

if [ $LOCAL_INSTALL == 0 ]; then
    rm /usr/src/mor_sounds.tgz
fi
download_packet mor_sounds.tgz
extract_gz mor_sounds.tgz

cp -fr /usr/src/sounds/* /var/lib/asterisk/sounds  #changed from cp -fr /usr/src/mor/sounds/* /var/lib/asterisk/sounds to ...

_done;
echo -e "\n======== AGI scripts ========\n"

cd /usr/src/mor/agi
./install.sh 

_done;

echo -e "\n======== Registration and IVR generation scripts ========\n"

if [ $UPGRADE_TO_8 == 0 ]; then
    cd /usr/src/mor/scripts/
    ./install.sh
fi

_done;

echo -e "\n======== Asterisk conf files ========\n";

# make backup for old files
mkdir -p /etc/asterisk/mor_backup
cp /etc/asterisk/* /etc/asterisk/mor_backup

cp -fr /usr/src/mor/asterisk-conf/asterisk.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_ad.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_pbxfunctions.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_tests.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_ivr.conf /etc/asterisk/

if [ -r /etc/asterisk/extensions_mor_custom.conf ]; then echo -e "extensions_mor_custom.conf ok \n";
   else cp -fr /usr/src/mor/asterisk-conf/extensions_mor_custom.conf /etc/asterisk/
fi


# -- asterisk restart script --
#cp -f /usr/src/mor/sh_scripts/asterisk_nice_restart.sh /usr/local/mor
#crontab_add "asterisk_nice_restart" "0 0 * * * /usr/local/mor/asterisk_nice_restart.sh"  "Asterisk nice restart crontab installed\t\t\t\t"

if [ $UPGRADE_TO_8 == 0 ]; then
    /usr/src/mor/sh_scripts/install_hgc_sounds.sh
fi

asterisk_reload; #asterisk -vvvvvrx 'reload'  
             
_done;

/usr/src/mor/upgrade/0.7/various_common_upgrades.sh

press_enter_to_exit;
