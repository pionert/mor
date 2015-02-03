#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================


echo -e "\n======== H323 script ========\n"

cd /usr/src/mor/scripts/
./install.sh


# --- agi scripts -----

cd /usr/src/mor/agi/
./install.sh


#_done;

echo -e "\n======== Asterisk conf files ========\n";

    # ------ h323 ------

    H323=`cat /etc/asterisk/extensions_mor.conf | grep -i "extensions_mor_h323.conf"`;
    if [ "$H323" == "" ]; then echo -e "\n#include extensions_mor_h323.conf" >> /etc/asterisk/extensions_mor.conf; fi

    H323=`cat /etc/asterisk/h323.conf | grep -i "mor_ast_h323"`;
    if [ "$H323" == "" ]; then echo -e "\n#exec /usr/local/mor/mor_ast_h323" >> /etc/asterisk/h323.conf; fi

    touch /etc/asterisk/extensions_mor_h323.conf


    # ----- calling cards -----

    cp /usr/src/mor/asterisk-conf/extensions_mor_callingcard.conf /etc/asterisk/

    CC=`cat /etc/asterisk/extensions_mor.conf | grep -i "extensions_mor_callingcard.conf"`;
    if [ "$CC" == "" ]; then echo -e "\n#include extensions_mor_callingcard.conf" >> /etc/asterisk/extensions_mor.conf; fi
    

# -- dial-local pbx function ---
    
    cp -fr /usr/src/mor/asterisk-conf/extensions_mor_pbxfunctions.conf /etc/asterisk/    
    cp -fr /usr/src/mor/asterisk-conf/extensions_mor_ivr.conf /etc/asterisk/    


# ARA die! (for SIP just now only)

    #make backup
#    DATE=`date`
#    mkdir -p /etc/asterisk/backup
#    mkdir -p /etc/asterisk/backup/"$DATE"
#    cp -fr /etc/asterisk/extconfig.conf /etc/asterisk/backup/"$DATE"/extconfig.conf
#    cp -fr /etc/asterisk/sip.conf /etc/asterisk/backup/"$DATE"/sip.conf   
    
#    cp -fr /usr/src/mor/asterisk-conf/0.8/extconfig.conf /etc/asterisk/    
#    cp -fr /usr/src/mor/asterisk-conf/0.8/sip.conf /etc/asterisk/    

# -- asterisk restart script --
#cp -f /usr/src/mor/sh_scripts/asterisk_nice_restart.sh /usr/local/mor
#crontab_add "asterisk_nice_restart" "0 0 * * * /usr/local/mor/asterisk_nice_restart.sh"  "Asterisk nice restart crontab installed\t\t\t\t"


# broken code
#cat /etc/asterisk/sip.conf | sed 's/;useragent=.*/useragent=MOR Softswitch/g' >/etc/asterisk/sip.conf 
#cat /etc/asterisk/sip.conf | sed 's/.*useragent=.*/useragent=MOR Softswitch/g' >/etc/asterisk/sip.conf

# IVR
if [ -d /home/mor/public/ivr_voices ]; then
  echo "ivr_voices folder ok"
else
  mkdir -p /home/mor/public/ivr_voices
fi
chmod 777 -R /home/mor/public/ivr_voices/
ln -s /home/mor/public/ivr_voices /var/lib/asterisk/sounds/mor/ivr_voices
    
#scripts
#cd /usr/src/mor/scripts
#./install.sh

#callback
cd /usr/src/mor/callback/agi
./install.sh

/usr/src/mor/sh_scripts/install_hgc_sounds.sh


# fax apps just in case
cd /usr/src/mor/fax2email/additional_apps
make clean
make
make install

# auto-dialer +ivr action
cd /usr/src/mor/mor_ad/agi
./install.sh

#press_enter_to_exit;


asterisk -vvvvvrx 'module reload'
