#!/bin/sh
# Company:  Kolmisoft
# Author:   Mindaugas Mardosas
# Year:     2012
# About:    MOR system upgrade/fix script
#
# Important: Once this script is launched there is no way back to older MOR versions. You will have to reinstall the system in order to get older MOR version.
#
# Changes implemented by this script:
#   1. Ruby on Rails version is lifted to 3.2.2
#   2. Ruby version is lifted to ruby-1.9.3-p194
#   3. Passenger is used instead of FCGI
#   4. Various configuration upgrades for Asterisk
#   5. MySQL tables are upgraded. Blob type is changed to TEXT in order to support UTF-8
#   6. environment.rb configuration file is migrated
#   7. database.yml configuration file is migrated


# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh

mysql_server_version
vercomp "$MYSQL_VERSION_2" "5.5"
STATUS="$?"
if [ "$STATUS" == "0" ] || [ "$STATUS" == "1" ]; then
    report "MySQL version: OK" 0
else
    report "MOR X3 must have MySQL >=5.5 in order encodings would work correctly in MOR GUI. Will now exit the script" 1
    exit 1
fi

#=========== Functions ======
migrate_environment_rb()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function migrates existing Ruby On Rails 1 environmnet.rb file to Ruby On Rails 3 environmnet.rb file

    cp  /usr/src/mor/upgrade/12/files/environment.rb /home/mor/config/environment.rb
    local WEB_URL=`awk -F "#" '{print $1}'  /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/config/environment.rb | grep Web_URL | sed 's/ //g' | awk -F"=" '{print $2}' | head -n 1`
    local RECORDINGS_URL=`awk -F "#" '{print $1}'  /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/config/environment.rb | grep Recordings_Folder | head -n 1 | sed 's/ //g'`
    local email_prefix=`awk -F "#" '{print $1}'  /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/config/environment.rb | grep email_prefix | sed 's/ //g' | awk -F"=" '{print $2}' | head -n 1 | sed 's/\n//g'`

    replace_line /home/mor/config/environment.rb 'Web_URL' "Web_URL = $WEB_URL"
    replace_line /home/mor/config/environment.rb 'Recordings_Folder' "$RECORDINGS_URL"
    replace_line /home/mor/config/environment.rb 'ExceptionNotifier.email_prefix' "ExceptionNotifier_email_prefix=$email_prefix"
    
    #--- Migrate addons
    awk -F'#' '{print $1}' /tmp/.mor_env_rb_before_migration | grep "CC_Active\|AD_Active\|RS_Active\|SMS_Active\|REC_Active\|PG_Active\|CS_Active\|MA_Active\|AST_18\|PROVB_Active\|WP_Active\|SKP_Active\|RSPRO_Active\|CALLB_Active" >> /home/mor/config/environment.rb
    
    #--- enable ast 18 by default
    if [ `grep AST_18 /home/mor/config/environment.rb | wc -l` == "0" ]; then
        echo "AST_18 = 1" >> /home/mor/config/environment.rb
    fi
    
    report "/home/mor/config/environment.rb migrated" 4
}
migrate_database_yml()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function migrates existing Ruby On Rails 1 database.yml file to Ruby On Rails 3 database.yml file

    sed "s/db_name/$DB_NAME/g" /usr/src/mor/upgrade/12/files/database.yml | \
    sed "s/db_username/$DB_USERNAME/g" | \
    sed "s/db_passwd/$DB_PASSWORD/g" | \
    sed "s/db_host/$DB_HOST/g" > /home/mor/config/database.yml
    report "/home/mor/config/database.yml migrated" 4
}



#=========== Main ==================================================



mkdir -p /usr/local/mor/backups/GUI
if [ $LOCAL_INSTALL == 0 ]; then
    svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor

    get_last_stable_mor_revision 12
    svn update -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/install_script/trunk/db/12/ /usr/src/mor/db/12/ &> /dev/null

    randir=`date +%H%M%S%N`
    if [ -d /home/mor ]; then
        mor_gui_current_version
        if [ "$MOR_VERSION" -lt "12" ] || [ "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS" == "12.126" ]; then    # BIG CHANGES.. New project structure, etc....
            mysql_connect_data_v2  # getting MySQL connection details
            tar -cvf /usr/local/mor/backups/GUI/mor_"$MOR_VERSION"_before_migration_to_MOR_12_$randir.tar.gz /home/mor --exclude "/home/mor/log"
            if [ -d /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12 ]; then
                report 'Sorry, but /home/mor_'$MOR_VERSION'_BEFORE_MIGRATION_TO_MOR_12 already exists. To avoid custom modifications you might have there I refuse to continue overwriting that directory. Remove or rename that directory if you are sure that no valuable information there is present' 1
                exit 1
            fi
            
            rm -rf /tmp/.mor_env_rb_before_migration
            cp -fr /home/mor/config/environment.rb /tmp/.mor_env_rb_before_migration          
            
            mv /home/mor /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12
            report "Checking out MOR X3 GUI from svn.kolmisoft.com" 3
            
            svn co -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/gui/branches/12 /home/mor &> /dev/null

            cp -R /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/public/ivr_voices /home/mor/public/ivr_voices
            chmod 666 -R /home/mor/public/ivr_voices
            
            if [ ! -L /home/mor/public/recordings ]; then # not needed since MOR 12. If you will leave this symlink - you will not be able to open recordings
                ln -s /var/spool/asterisk/monitor /home/mor/public/recordings  
            fi

            cp -R /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/public/ad_sounds /home/mor/public/ad_sounds
            chmod 666 -R /home/mor/public/ad_sounds

            if [ ! -s "/home/mor/public/recordings" ]; then
                ln -s /var/spool/asterisk/monitor /home/mor/public/recordings
            fi

            if [ ! -s "/home/mor/public/fax2email" ]; then
                ln -s /var/spool/asterisk/faxes /home/mor/public/fax2email
            fi

            #----------- Assets ------
            mkdir -p /home/mor/app/assets/images/logo /home/mor/tmp
            cp -R /home/mor_"$MOR_VERSION"_BEFORE_MIGRATION_TO_MOR_12/public/images/logo/* /home/mor/app/assets/images/logo/
            chmod -R 777 /home/mor/app/assets /home/mor/tmp
            #------------------------
            #------
            mkdir -p /home/mor/log
            chmod -R 666 /home/mor/log
            if [ "$?" == "0" ]; then
                report "MOR X3 checkout from SVN" 0
            else
                report "Failed to checkout MOR X3 GUI from svn.kolmisoft.com. Please ensure that your DNS settings in /etc/resolv.conf are correct and you can access address svn.kolmisoft.com" 1
                exit 1
            fi
            report "Migrating MOR GUI Configuration files" 3
            migrate_environment_rb
            rm -rf /tmp/.mor_env_rb_before_migration
            
            migrate_database_yml
            service httpd restart
            
            #---- Cleaning out OLD sessions as OLD sessions are not compatible with ROR3 ---
            report "Deleting old sessions from database as they are not compatible with new ROR Framework. All users will be disconnected from MOR GUI" 3
            /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "DELETE FROM sessions;"
            
            
        fi
    fi
fi

#-------------------

# get db data
mysql_connect_data

# Adding symlinks appropriate upgrade files for gui

rm -rf /home/mor/gui_upgrade.sh /home/mor/gui_upgrade_light.sh

report "Adding symlinks to /usr/src/mor/upgrade/12/gui_upgrade_light.sh and /usr/src/mor/upgrade/12/gui_upgrade.sh" 3
ln -s /usr/src/mor/upgrade/12/gui_upgrade_light.sh /home/mor/gui_upgrade_light.sh
ln -s /usr/src/mor/upgrade/12/gui_upgrade.sh /home/mor/gui_upgrade.sh
chmod +x /home/mor/gui_upgrade_light.sh /home/mor/gui_upgrade.sh

# db backup-upgrade
/usr/src/mor/db/12/import_changes.sh

rm -rf /usr/local/mor/mor_ruby
ln -s /usr/src/mor/upgrade/12/mor_ruby /usr/local/mor/mor_ruby
chmod +x /usr/local/mor/mor_ruby

/usr/src/mor/test/scripts/gui/ror3_invoices.sh

#---- MOR 12 specific -------

/usr/src/mor/upgrade/12/nodejs.sh
#/usr/src/mor/upgrade/12/rvm.sh

/usr/src/mor/upgrade/12/ruby_1_9_3.sh
/usr/src/mor/upgrade/12/bundler.sh
/usr/src/mor/upgrade/12/passenger.sh


/usr/src/mor/upgrade/12/rs_to_rspro.sh # DB data fix

#-----------------------------

yum --enablerepo=epel -y install curl-devel whatmask
yum -y install zip bind-utils

# gui fixes
/home/mor/gui_upgrade.sh    # all gems are rebundled here also


# anipin dialplan for * press
cp -fr /usr/src/mor/asterisk-conf/10/extensions_mor_anipin.conf /etc/asterisk/

# all other files
cp -fr /usr/src/mor/asterisk-conf/extensions_mor.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/extensions_mor_ad.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/extensions_mor_callingcard.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/extensions_mor_pbxfunctions.conf /etc/asterisk/
cp -fr /usr/src/mor/asterisk-conf/9/modules.conf /etc/asterisk/

#cp -fr /usr/src/mor/asterisk-conf/10/chan_skype.conf /etc/asterisk/

cp -fr /usr/src/mor/asterisk-conf/sip_didww.conf /etc/asterisk/

#copy only if not present already
if [ ! -f /etc/asterisk/extensions_mor_didww.conf ]; then
    cp /usr/src/mor/asterisk-conf/extensions_mor_didww.conf /etc/asterisk/
fi

#copy only if not present already
if [ ! -f /etc/asterisk/extensions_mor_external_did.conf ]; then
    cp /usr/src/mor/asterisk-conf/9/extensions_mor_external_did.conf /etc/asterisk/
fi

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
cp -fr /usr/src/mor/upgrade/12/cronjobs/mor_daily_actions /etc/cron.d/
cp -fr /usr/src/mor/upgrade/12/cronjobs/mor_minute_actions /etc/cron.d/

# do not upgrade gui for trunk everyday
rm -rf /etc/cron.d/mor_gui_upgrade

/etc/init.d/crond restart

mkdir -p /var/log/asterisk/cdr-csv
mkdir -p /var/log/asterisk/cdr-custom

# possible error fix
if [ ! -L /usr/local/bin/lame ]; then
    ln -s /usr/bin/lame /usr/local/bin/lame
fi

# recording fix
chmod -R 777 /var/spool/asterisk/monitor


# cc new logic sound files
#/usr/src/mor/sh_scripts/install_mor9_sounds.sh

# backups fix
chmod -R 777 /usr/local/mor/backups

# my.cnf configure
cd /usr/src/mor/sh_scripts
./configure_mycnf.sh

# persmission problem fix
chmod -R 666 /var/log/httpd


cp -f /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_restore.sh /usr/local/mor/
cp -f /usr/src/mor/sh_scripts/backup/make_backup.sh /usr/local/mor/

touch /var/log/mor/monitorings.log /tmp/mor_session.log
chmod 666 /var/log/mor/monitorings.log /tmp/mor_session.log

/usr/src/mor/test/scripts/various/yum-updatesd.sh

cd /usr/src/mor/scripts
./install.sh


#mor ad fix
cp -fr /usr/src/mor/mor_ad/agi/mor_ad_agi.c /home/mor_ad/agi
cd /home/mor_ad/agi
./install.sh

cp -fr /usr/src/mor/mor_ad/app/mor_ad_cron.c  /home/mor_ad/app
cd /home/mor_ad/app
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

cp -n /var/lib/asterisk/sounds/mor/mor_callingcard_choices.wav /var/lib/asterisk/sounds/mor/ivr_voices/en/mor_callingcard_choices.wav



chmod -R 777 /home/mor/tmp
/usr/src/mor/test/scripts/gui/xsendfile.sh  # Fix for big static files like backups download - will not consume a lot of RAM

#some scripts needs to use right version of ruby. Those will use following simlink which point to ruby-1.9.3-p194@12 which is right version in case of MOR X3:




#======Various ruby migration scripts=====
/usr/local/mor/mor_ruby /usr/src/mor/upgrade/12/ccl_delete_old_dependencies.rb  # Remove starting from X5
