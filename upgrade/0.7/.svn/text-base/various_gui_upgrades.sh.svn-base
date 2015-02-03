#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================



            #echo ""
            #echo "======== XLS parsing support ========"


            #    PARSEEXCEL=`gem list --local parseexcel | grep parseexcel`;
            #    if [ "$PARSEEXCEL" == "" ]; then gem install parseexcel -y --no-rdoc --no-ri; fi

            #    ROO=`gem list --local roo | grep roo`;
            #    if [ "$ROO" == "" ]; 
            #    then 
            #	gem uninstall rubyforge;    
            #	gem install roo -y --no-rdoc --no-ri; 
            #    fi


            #echo ""
            #echo "done."
            #echo ""

echo -e "\n======== environment.rb upgrade ========"

    # functionality

    # not used anymore
    BACKUPS=`cat /home/mor/config/environment.rb | grep -i "F_BACKUPS"`;    
    if [ "$BACKUPS" == "" ]; then echo -e "\nF_BACKUPS = 0" >> /home/mor/config/environment.rb; fi

    # addons

    RSACTIVE=`cat /home/mor/config/environment.rb | grep -i "RS_Active"`;
    C2CACTIVE=`cat /home/mor/config/environment.rb | grep -i "C2C_Active"`;
    SMSACTIVE=`cat /home/mor/config/environment.rb | grep -i "SMS_Active"`;
    CALLCACTIVE=`cat /home/mor/config/environment.rb | grep -i "CALLC_Active"`;      
    
    if [ "$RSACTIVE" == "" ]; then echo -e "\nRS_Active = 0" >> /home/mor/config/environment.rb; fi
    if [ "$C2CACTIVE" == "" ]; then echo -e "\nC2C_Active = 0" >> /home/mor/config/environment.rb; fi
    if [ "$SMSACTIVE" == "" ]; then echo -e "\nSMS_Active = 0" >> /home/mor/config/environment.rb; fi
    if [ "$CALLCACTIVE" == "" ]; then echo -e "\nCALLC_Active = 0" >> /home/mor/config/environment.rb; fi

	    
_done;


#echo -e "\n======== mytop install ========"

#    download_packet mytop-1.4-1.rh9.rf.noarch.rpm
#    rpm -ifvh --replacepkgs --replacefiles mytop-1.4-1.rh9.rf.noarch.rpm

#_done;


         #echo ""
         #echo "======== Google Maps ========"
         #if [ -r /home/mor/config/gmaps_api_key.yml ];
         #then
         #    echo "Everything is ok with Google Maps..."
         #else
         #    cp -fr /usr/src/mor/gui/config/gmaps_api_key.yml /home/mor/config/;
         #fi; 
         #echo ""
         #echo "done."
         #echo ""

echo -e "\n\n======== Various ========\n"

# IVR
if [ -d /home/mor/public/ivr_voices ]; then
    echo "ivr_voices folder ok"
else
    mkdir -p /home/mor/public/ivr_voices
fi
chmod 777 -R /home/mor/public/ivr_voices/
ln -s /home/mor/public/ivr_voices /var/lib/asterisk/sounds/mor/ivr_voices

# fixed dtree.js
cp -fr /usr/src/mor/gui/public/javascripts/* /home/mor/public/javascripts/

# audio convert script
mkdir -p /usr/local/mor
if [ -d /usr/local/mor ]; then
    echo "/usr/local/mor folder ok"
else
    mkdir -p /usr/local/mor
fi
cp -fr /usr/src/mor/sh_scripts/convert_mp3wav2astwav.sh /usr/local/mor/

_done;

cp -fr /usr/src/mor/upgrade/0.7/gui_upgrade.sh /home/mor
cp -fr /usr/src/mor/upgrade/0.7/gui_upgrade_light.sh /home/mor

/usr/src/mor/sh_scripts/daily_actions_cronjob_install.sh

/usr/src/mor/sh_scripts/enable_backup.sh

/usr/src/mor/upgrade/0.7/pdf_utf8_support.sh

/usr/src/mor/upgrade/0.7/various_common_upgrades.sh

press_enter_to_exit;

apache_restart;

