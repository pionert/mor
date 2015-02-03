#!/bin/sh
# Author:   Mindaugas Mardosas
# Year:     2012
# About:    This script is used to upgrade MOR GUI

#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#=================================================

#======== Functions ========
mor_check_fix_assets()
{
    # Author: Mindaugas Mardosas
    # Year: 2012
    # About: This functions recompiles assets if there are any changes in /home/mor/app/assets.

    if [ ! -f "/home/mor/tmp/recompiled" ]; then
        rm -rf /home/mor/assets_log # Dirty hack to recompile assets. This was needed as assets got many improvements after which a recompile was needed.
    fi
    
    if [ -f "/home/mor/assets_log" ]; then
        LAST_COMPILED_ASSETS_REVISION=`tail -n 1 /home/mor/assets_log`
    else
        echo "[DEBUG] /home/mor/assets_log not found"
    fi

    CURRENT_ASSETS_REVISION=`svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}'`

    if [ "$CURRENT_ASSETS_REVISION" != "$LAST_COMPILED_ASSETS_REVISION" ]; then
        rvm alias create default ruby-1.9.3-p194@12
        report "Recompiling MOR assets. This will take some time" 3
        rm -rf /home/mor/tmp
        mkdir -p /home/mor/app/assets
        cd /home/mor
        report "Cleaning Assets" 3
        #rvm ruby-1.9.3-p194@12 do rake assets:clean &> /dev/null #--trace
        rake assets:clean  2>&1 | grep -v Insecure
        report "Recompiling assets" 3
        #rvm ruby-1.9.3-p194@12 do rake assets:precompile &> /dev/null #--trace
        rake assets:precompile 2>&1 | grep -v Insecure

        svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}' > /home/mor/assets_log
        mkdir -p /home/mor/tmp
        touch /home/mor/tmp/recompiled
    fi
    mkdir -p /home/mor/tmp /home/mor/app/assets /home/mor/log
    chmod 777 -R /home/mor/tmp /home/mor/app/assets
}

#========== MAIN ========================

#make backup of previous gui
_mor_time; #get the system time
tar czf /usr/local/mor/backups/GUI/mor_gui_backup.$mor_time.tar.gz /home/mor/app /home/mor/config /home/mor/doc /home/mor/lang /home/mor/lib /home/mor/vendor

rm -rf /tmp/mor # cleaning out any stuff left from previous upgrade

get_last_stable_mor_revision 12
svn co -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/gui/branches/12 /tmp/mor ;
if [ ! -L "/home/mor/public/recordings" ]; then
    ln -s /var/spool/asterisk/monitor /home/mor/public/recordings
fi

chmod -R 777 /home/mor/public/recordings

cp -f -r -v /tmp/mor /home/

if [ -d /home/mor/public/ad_sounds ]; then
    chmod 777 /home/mor/public/ad_sounds
else
    mkdir -p /home/mor/public/ad_sounds
    chmod 777 /home/mor/public/ad_sounds
    ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad
fi

rvm 1.9.3 do rvm alias create default ruby-1.9.3-p194@12     # setting as default ruby for the whole system
# this file should be empty and readable
rm -fr /home/mor/Gemfile.lock 
touch /home/mor/Gemfile.lock 
chmod 666 /home/mor/Gemfile.lock 

#- Updating ruby gems
cd /home/mor
report "Bundling gems. This might take a few minutes" 3
rvm ruby-1.9.3-p194@12 do bundle update

mor_check_fix_assets

#===== Cleanup after dynamic assets migration to static public dir ======

if [ -d "/home/mor/app/assets/images/cards" ]; then
    mkdir -p /home/mor/public/images/cards
    mv /home/mor/app/assets/images/cards/*  /home/mor/public/images/cards/
    rm -rf /home/mor/app/assets/images/cards
fi


if [ -d "/home/mor/app/assets/images/logo" ]; then
    mkdir -p /home/mor/public/images/logo
    mv /home/mor/app/assets/images/logo/*  /home/mor/public/images/logo/
    rm -rf /home/mor/app/assets/images/logo
fi

if [ -d "/home/mor/app/assets/images/flags" ]; then
    mkdir -p /home/mor/public/images/flags
    mv /home/mor/app/assets/images/flags/*  /home/mor/public/images/flags/
    rm -rf /home/mor/app/assets/images/flags
fi

#================================


touch /home/mor/log/development.log /home/mor/log/production.log /tmp/mor_debug.log  /tmp/new_log.txt
chmod -R 777 /home/mor/log
chown -R apache: /home/mor /tmp/mor_debug.log  /tmp/new_log.txt
chmod -R 777 /home/mor/public/ivr_voices /home/mor/tmp /tmp/mor_debug.log /tmp/new_log.txt /home/mor/public/images



 


/etc/init.d/httpd restart
log_revision 'mor' 'gui' 'Update was made using gui_upgrade.sh' #logging MOR GUI versrion change
