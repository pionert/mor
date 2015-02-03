#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================


#======== Functions ========
mor_check_fix_assets()
{
    # Author: Mindaugas Mardosas
    # Year: 2012
    # About: This functions recompiles assets if there are any changes in /home/mor/app/assets.

    if [ -f "/home/mor/assets_log" ]; then
        LAST_COMPILED_ASSETS_REVISION=`tail -n 1 /home/mor/assets_log`
    else
        echo "[DEBUG] /home/mor/assets_log not found"
    fi

    CURRENT_ASSETS_REVISION=`svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}'`

    if [ "$CURRENT_ASSETS_REVISION" != "$LAST_COMPILED_ASSETS_REVISION" ]; then
        report "Recompiling MOR assets. This will take some time" 3
        rm -rf /home/mor/tmp
        mkdir -p /home/mor/app/assets
        cd /home/mor
        report "Cleaning Assets" 3
        rvm ruby-1.9.3-p327@x4 do rake assets:clean &> /dev/null #--trace
        report "Recompiling assets" 3
        rvm ruby-1.9.3-p327@x4 do rake assets:precompile &> /dev/null #--trace

        svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}' > /home/mor/assets_log
        
    fi
    mkdir -p /home/mor/tmp /home/mor/app/assets /home/mor/log
    chmod 777 -R /home/mor/tmp /home/mor/app/assets
}

#========== MAIN ========================

#make backup of previous gui
_mor_time; #get the system time
tar czf /usr/local/mor/backups/GUI/mor_gui_backup.$mor_time.tar.gz /home/mor/app /home/mor/config /home/mor/doc /home/mor/lang /home/mor/lib /home/mor/public/stylesheets /home/mor/vendor

get_last_stable_mor_revision x4
svn co -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/gui/branches/x4 /home/mor


mor_check_fix_assets

rvm 1.9.3 do rvm alias create default ruby-1.9.3-p327@x4     # setting as default ruby for the whole system
# this file should be empty and readable
rm -fr /home/mor/Gemfile.lock 
touch /home/mor/Gemfile.lock 
chmod 666 /home/mor/Gemfile.lock 

#- Updating ruby gems
cd /home/mor
report "Bundling gems. This might take a few minutes" 3
rvm ruby-1.9.3-p327@x4 do bundle update
touch /tmp/mor_debug.log  /tmp/new_log.txt
chown -R apache: /home/mor /tmp/mor_debug.log  /tmp/new_log.txt
chmod 777 tmp/mor_debug.log /tmp/new_log.txt
/etc/init.d/httpd restart

log_revision 'mor' 'gui' 'Update was made using gui_upgrade_light.sh'
