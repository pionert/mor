#! /bin/bash
searchd_installed()
{
    # Returns:
    #   0   -   OK, searchd is installed
    #   1   -   Failed, searchd is not installed

    if [ -f /usr/local/bin/searchd ]; then
        return 0
    else
        cd /usr/src/
        wget -c  http://www.kolmisoft.com/packets/src/sphinx-0.9.9.tar.gz
        tar xzvf sphinx-0.9.9.tar.gz
        cd sphinx-0.9.9
        ./configure
        make
        make install
        if [ -f /usr/local/bin/searchd ]; then
            return 0
        else
            return 1
        fi
    fi
}

reconfigure_db()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function reconfigures database to be in use by GUI
    #
    #   Arguments:
    #       $1 - database name, for example "mor"
    #       $2 - host, for example localhost

    DB_name="$1"
    DB_host="$2"

    sed -i "s/database:.*/database: '$DB_name'/g" /home/mor/config/database.yml
    sed -i "s/username:.*/username: '$DB_name'/g" /home/mor/config/database.yml
    sed -i "s/password:.*/password: '$DB_name'/g" /home/mor/config/database.yml
    sed -i "s/host:.*/host: '$DB_host'/g" /home/mor/config/database.yml
    
    service httpd reload
}

download_gui_from_brain()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function is responsible for download prepared TEST GUI from brain.kolmisoft.com
    
    local gui_version="$1"
    
    cd /home/gui_pool
    if [ ! -d "/home/gui_pool/$gui_version" ]; then
        
        wget -c http://brain.kolmisoft.com/files/gui/mor_$gui_version.tar.gz
        tar xzvf mor_$gui_version.tar.gz
    fi
}

searchd_running()
{
    searchd_installed
    if [ "$?" == "0" ]; then

        local running=`ps aux | grep searchd  | grep tickets | wc -l`
        if [ "$running" == "1" ]; then
            chmod 777  /home/tickets/log/searchd.production.pid
            echo "Searchd is OK"
            return 0
        else
            /usr/local/bin/searchd --config /home/tickets/config/production.sphinx.conf
            sh /home/tickets/lib/sphinx_reindex.sh
            chmod 777  /home/tickets/log/searchd.production.pid
            return 1
        fi
    else
        echo "Searchd is not installed and failed to fix this"
        return 1
    fi
}
n_update_source()
{
    if [ "$N_DEBUG" != "1" ]; then
        svn status /usr/src/mor &> /dev/null
        if [ "$?" != "0" ]; then
            report "Anomalies detected in /usr/src/mor, deleting and redownloading" 3
            rm -rf /usr/src/mor
            svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
        else
            if [ -d "/usr/src/mor" ]; then
                svn update /usr/src/mor
            else
                svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
            fi
        fi
    else
        report "DEBUG MODE ENABLED - will not do any actions against /usr/src/mor" 3
    fi
}

restart_xvfb_if_not_enough_ram()
{
    if [ `free -m | grep cache | awk '{ print \$4}' | tail -n 1` -lt "150" ]; then
        kill -9 Xvfb &> /dev/null
        check_if_xvfb_is_running
    fi   
}


n_status()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function checks all services that are required for testing
    #
    rm -rf /tmp/.mor_global_test-fix_framework_variables
    if [ `ps aux | grep Xvfb | grep -v grep | wc -l` != "1" ]; then
        report "Xvfb: running" 0
    else
        report "Xvfb: stopped (normal when using with n -l)" 3
    fi

    mysql_is_running
        report "MySQL server" $?

    apache_is_running
        report "Apache server" $?


    if [ `svn status /usr/src/mor | grep ^M | wc -l` != "0" ]; then
        report "There are custom modification in /usr/src/mor. Use svn status /usr/src/mor | grep ^M  to check what are those modified files" 2
    else
        report "Custom modification in /usr/src/mor not present" 0
    fi
}
kill_not_needed_services()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function kills not needed services
    #

    killall -9 plymouthd &> /dev/null

}
copy_selenium_to_ram_if_not_present()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function copies Selenium Server to RAM for faster execution
    #
    if [ ! -f /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar ]; then
        if [ ! -f /usr/src/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar ]; then
            wget -c http://selenium.googlecode.com/files/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar -O /usr/src/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar
            if [ "$?" != "0" ]; then
                report "Failed to download selenium " 3
                exit 0;
            fi
        fi
        rm -rf /dev/shm/selenium-server-standalone* #deleting possible old versions
        cp -fr  /usr/src/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar
    fi
}
check_if_x11_is_working()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function checks if some kind of X11 session is working where Firefox could draw windows.
    #
    if [ `ps aux | grep gnome-session | grep -v grep | wc -l` != "1" ]; then
        report "No X11 (gnome) sessions are running, removing node from brain to prevent incorrect results" 1
        n -remove
        exit 0
    fi
}

remove_unneeded_crons()
{
    rm -rf /etc/cron.d/mor_hourly_actions /etc/cron.d/mor_logrotate /etc/cron.d/mor_minute_actions /etc/cron.d/mor_monthly_actions
}

stop_delayed_jobs()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function stops delayed jobs for CRM is started, starts if not. More documentation regarding delayed jobs can be found here http://support.kolmisoft.com:8082/display/kolmisoft/CRM+Delayed_jobs
    #
    killall -9 delayed_job &> /dev/null
}

debug_resource_usage()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function prints information about system resources usage
    #
    # Arguments:
    #   $1 - message to print

    local CUSTOM_MESSAGE="$1"

    if [ "$N_DEBUG_RESOURCE_USAGE" == "1" ]; then
        echo -e "\n\n====================$CUSTOM_MESSAGE==================\n\n" >> /var/log/mor/n
        top -n 1 >> /var/log/mor/n
        free -m >> /var/log/mor/n
        echo -e "\n\n======================================================\n\n" >> /var/log/mor/n
    fi
}

mor_addons()
{
    mor_gui_current_version
    mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
    
    if [ "$MOR_MAPPED_VERSION_WEIGHT" -lt "140" ]; then
        report "Adding addons" 3
        ADDON_LIST=(CC_Active AD_Active RS_Active SMS_Active REC_Active PG_Active CS_Active MA_Active SKP_Active RSPRO_Active CALLB_Active PROVB_Active AST_18 WP_Active)
        for element in $(seq 0 $((${#ADDON_LIST[@]} - 1)))
        do
            if [ `awk -F"#" '{print $1}' /home/mor/config/environment.rb  | grep ${ADDON_LIST[$element]} | grep "1" | wc -l` == "0" ]; then
                echo "${ADDON_LIST[$element]} = 1" >> /home/mor/config/environment.rb
                report "Added ${ADDON_LIST[$element]} = 1 was added to /home/mor/config/environment.rb" 4
            fi
        done
    
        if [ `grep "TEST_MACHINE=1\|TEST_MACHINE = 1" /home/mor/config/environment.rb | wc -l` == "0" ]; then
            echo "TEST_MACHINE = 1" >> /home/mor/config/environment.rb
        fi
    fi
}

cleanup_various_files()
{
    #rm -rf /var/lib/mysql/mysql-bin.* /var/lib/mysql/master-log-bin.index
    rm -rf /tmp/*.csv /tmp/Last_calls*  /tmp/customProfile* /tmp/*.html /tmp/tmp.* /tmp/file* /tmp/_sox* /tmp/*.gz /tmp/*.pdf /usr/local/mor/backups/GUI/*
    find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf
}
etc_hosts()
{
    report "Setting up /etc/hosts in order DNS would not be hit every time we need Kolmisoft infrastructure" 3
    if [ `grep "213.197.141.162" /etc/hosts | wc -l` == "0" ]; then
        echo -e "213.197.141.162    svn.kolmisoft.com brain2.marsassolutions.com\n91.121.143.102      www.kolmisoft.com\n" >> /etc/hosts
    fi
}

check_if_rebundle_is_needed()
{
    # Author: Mindaugas Mardosas
    # Year: 2012-2013
    # About:  This function checks if  gem bundle is needed for product dir

    TEST_PRODUCT_DIR="$1"

    if [ -f "$TEST_PRODUCT_DIR/Gemfile" ]; then
        report "Checking if re-bundle for gems is needed" 3

        current_gemfile_revision=`/usr/bin/svn info $TEST_PRODUCT_DIR/Gemfile | grep -F 'Last Changed Rev' | awk '{print $NF}'`

        if [ ! -f "$TEST_PRODUCT_DIR/last_bundle_revision" ] || [ `cat $TEST_PRODUCT_DIR/last_bundle_revision` != "$current_gemfile_revision" ]; then
            report "Bundling gems for $TEST_PRODUCT_DIR" 3
            cd $TEST_PRODUCT_DIR
            bundle install --local
            if [ "$?" == "0" ]; then
                report "Bundle complete. Putting last Gemfile revision to $TEST_PRODUCT_DIR/last_bundle_revision" 4
                echo "$current_gemfile_revision" > $TEST_PRODUCT_DIR/last_bundle_revision
                return 4
            else
                report "Bundle failed, network problems? Will try once more" 1
                cd $TEST_PRODUCT_DIR
                bundle package
                if [ "$?" == "0" ]; then
                    report "Bundle complete after second attempt.  Putting last Gemfile revision to $TEST_PRODUCT_DIR/last_bundle_revision" 4
                    echo "$current_gemfile_revision" > $TEST_PRODUCT_DIR/last_bundle_revision
                    return 4
                else
                    report "Bundle failed" 1
                    echo "Bundle did not succeeded after 2 attempts. Removing node from brain" >> /var/log/mor/n
                    /bin/n -remove
                    return 1
                fi
            fi
        else
            report "All gems are up to date" 0
        fi
    else
        report "$TEST_PRODUCT_DIR/Gemfile not found, bundling is not needed" 3
    fi
}
change_ruby_version()
{
    # Author: Mindaugas Mardosas
    # Year: 2012-2013
    # About: This functions switches ruby version

    # Arguments:
    #   $1  - required ruby version

    local REQUIRED_RUBY_VERSION="$1"
    
    #--- Quick hack for 1.9.3xxxx patchlevels
    if [ "$REQUIRED_RUBY_VERSION" == "1.9.3" ]; then
        if [ "$TEST_MOR_VERSION" == "12" ]; then
            REQUIRED_RUBY_VERSION="$REQUIRED_RUBY_VERSION-p194"
        elif [ "$TEST_MOR_VERSION" == "x4" ]; then
            REQUIRED_RUBY_VERSION="$REQUIRED_RUBY_VERSION-p327@x4"
        fi
    elif [ "$REQUIRED_RUBY_VERSION" == "1.8.7" ]; then
        REQUIRED_RUBY_VERSION="1.8.7-p358"
    fi
    
    source "/usr/local/rvm/scripts/rvm" &> /dev/null
    
    #---- Take Last cached ruby version
    if [ -f "/dev/shm/last_used_ruby_version" ] && [ `cat /dev/shm/last_used_ruby_version` == "$REQUIRED_RUBY_VERSION" ]; then        
        return 0 # We already have required version
    fi

    CURRENT_RUBY_VERSION=`/usr/local/rvm/bin/rvm list | grep -F '=*' | head -n 1 | awk -F" " '{print $2}'`

    if [ "$N_DEBUG" ]; then
        report "Switching ruby version to $REQUIRED_RUBY_VERSION" 3
        echo -e "Debuging variables:\nTEST_MOR_VERSION: $TEST_MOR_VERSION\nCURRENT_RUBY_VERSION: $CURRENT_RUBY_VERSION\nREQUIRED_RUBY_VERSION: $REQUIRED_RUBY_VERSION\n"
    fi
    
    if [ "$CURRENT_RUBY_VERSION" != "$REQUIRED_RUBY_VERSION" ]; then
        #if [ `rvm list | grep "ruby-$REQUIRED_RUBY_VERSION" | wc -l` == 0 ]; then
        #    rvm install ruby-$REQUIRED_RUBY_VERSION --movable
        #fi
        rvm alias create default ruby-$REQUIRED_RUBY_VERSION
    else
        report "$REQUIRED_RUBY_VERSION is already set" 3
    fi

    rvm $REQUIRED_RUBY_VERSION
    # settting up apache config
    passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
    
    echo "$REQUIRED_RUBY_VERSION" > /dev/shm/last_used_ruby_version
    
}

create_ramdisk()
{
    # Author: Mindaugas Mardosas
    # Year: 2012
    # About: This functions creates when needed virtual ram disk for MySQL DB in order to speed up the tests

    FREE_MB_LEFT_IN_RAMDISK=`df -m | grep shm | awk '{print $4}'`

    if [ "$FREE_MB_LEFT_IN_RAMDISK" == "-" ] || [ -z "$FREE_MB_LEFT_IN_RAMDISK" ] || [ "$FREE_MB_LEFT_IN_RAMDISK" -lt "40" ] || [ ! -d "/dev/shm/mor" ] || [ ! -d "/dev/shm/tickets" ] || [ ! -h "/var/lib/mysql" ]; then
        report "No or little space left on MySQL ramdisk. Recreating the ramdisk partition" 3
        service mysqld stop &
        MySQL_PROCESS_ID=$!

        rm -rf /var/lib/mysql


        wait $MySQL_PROCESS_ID
        umount /dev/shm #unmounting temporary RAM storage
        mount -a #remounting

        ln -s /dev/shm /var/lib/mysql
        chown -R mysql: /var/lib/mysql

        local temp=`mktemp`
        sed -e '/datadir/d' -e '/log-bin-index/d' -e '/log-bin/d' -e '/expire_logs_days/d' -e  '/socket/d' /etc/my.cnf > $temp

        mv $temp /etc/my.cnf
        echo -e "datadir=/dev/shm/mysql\nsocket=/dev/shm/mysql/mysql.sock" >> /etc/my.cnf

        service mysqld start &
        MySQL_PROCESS_ID=$!
        wait $MySQL_PROCESS_ID

        # recreate MOR db
        mysql < /usr/src/mor/db/init.sql
        mysql -e "GRANT FILE ON *.* TO 'mor'@'localhost'; FLUSH PRIVILEGES;"


        # recreate tickets db
        mysql -e "CREATE DATABASE tickets CHARACTER SET utf8;"
        mysql -e "GRANT FILE ON *.* TO 'tickets'@'localhost'; FLUSH PRIVILEGES;"
    fi
}

mor_check_fix_assets()
{
    # Author: Mindaugas Mardosas
    # Year: 2012
    # About: This functions recompiles assets if there are any changes in /home/mor/app/assets

    if [ "$TEST_MOR_VERSION" == "12" ] || [ "$TEST_MOR_VERSION" == "x4" ]; then
        if [ -f "/home/mor/assets_log" ]; then
            LAST_COMPILED_ASSETS_REVISION=`tail -n 1 /home/mor/assets_log`
        else
            echo "[DEBUG] /home/mor/assets_log not found"
        fi

        CURRENT_ASSETS_REVISION=`svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}'`

        if [ "$CURRENT_ASSETS_REVISION" != "$LAST_COMPILED_ASSETS_REVISION" ]; then
            if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Going to recompile assets. Current assets revision in /home/mor/app/assets: $CURRENT_ASSETS_REVISION;  LAST_COMPILED_ASSETS_REVISION: $LAST_COMPILED_ASSETS_REVISION"; fi
            change_ruby_version "1.9.3"
            report "Recompiling MOR assets. This will take some time" 3
            rm -rf /home/mor/tmp
            mkdir -p /home/mor/app/assets
            cd /home/mor
            report "Cleaning Assets" 3
            rake assets:clean &> /dev/null #--trace
            report "Recompiling assets" 3
            rake assets:precompile &> /dev/null #--trace

            svn info /home/mor/app/assets | grep -F 'Last Changed Rev' | awk '{print $NF}' > /home/mor/assets_log

        fi
        mkdir -p /home/mor/tmp /home/mor/app/assets
        chmod 777 -R /home/mor/tmp /home/mor/app/assets
    fi
    # this file should be empty and readable		
    rm -fr /home/mor/Gemfile.lock 
    touch /home/mor/Gemfile.lock 
    chmod 666 /home/mor/Gemfile.lock 

}

#==== One time fixes
fix_update_rc_local()
{
    if [ `awk -F"#" '{ print $1 }' /etc/rc.local | grep "fix_eth_interface.sh" | wc -l` != "1" ]; then
        echo "sh -x /usr/src/mor/test/node2/fix_eth_interface.sh" >> /etc/rc.local
    fi

    if [ `awk -F"#" '{ print $1 }' /etc/rc.local | grep "configure_mycnf" | wc -l` != "1" ]; then
        echo "sh -x /usr/src/mor/sh_scripts/configure_mycnf.sh" >> /etc/rc.local
    fi
}
disable_services()
{
    #service asterisk stop
    #chkconfig --levels 2345 asterisk off

    service fail2ban stop
    chkconfig --levels 2345 fail2ban off

    service iptables stop
    chkconfig --levels 2345 iptables off

    service ip6tables stop
    chkconfig --levels 2345 ip6tables off

    service netfs stop
    chkconfig --levels 2345 netfs off

    service postfix stop
    chkconfig --levels 2345 postfix off
}
fix_pdf_wrapper()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This functions checks if ruby gem needs a fix

    change_ruby_version "1.8.7"
    if [ `gem list | grep "cairo\|pango" | wc -l` -lt "2" ]; then
        gem install cairo pango
    fi

    BINDINGS_VERSION_EXCEPTION=`grep -F 'too low. At least 1.5 is required" if Cairo::BINDINGS_VERSION' /usr/local/rvm/gems/ruby-1.8.7*/gems/pdf-wrapper-0.1.0/lib/pdf/wrapper.rb | wc -l`
    if [ "$BINDINGS_VERSION_EXCEPTION" != "0" ]; then
        tmp=`mktemp`
        sed '/At least 1.5 is required/d' /usr/local/rvm/gems/ruby-1.8.7-p358/gems/pdf-wrapper-0.1.0/lib/pdf/wrapper.rb > $tmp
        mv $tmp /usr/local/rvm/gems/ruby-1.8.7-p358/gems/pdf-wrapper-0.1.0/lib/pdf/wrapper.rb
        BINDINGS_VERSION_EXCEPTION=`grep -F 'too low. At least 1.5 is required" if Cairo::BINDINGS_VERSION' /usr/local/rvm/gems/ruby-1.8.7*/gems/pdf-wrapper-0.1.0/lib/pdf/wrapper.rb | wc -l`
        if [ "$BINDINGS_VERSION_EXCEPTION" == "0" ]; then
            report "Fixed pdf-wrapper gem" 4
        else
            report "pdf-wrapper gem fix failed. Most probably patch level changed, check if file is accessible under this link: /usr/local/rvm/gems/ruby-1.8.7-p358/gems/pdf-wrapper-0.1.0/lib/pdf/wrapper.rb" 1
        fi
    fi

    chmod 777  -R /usr/local/rvm
}
#========================

mor_conf()
{
    if [ ! -f /etc/httpd/conf.d/mod_fcgid_include.conf ]; then
        echo "
        <VirtualHost *:80>
            PassengerUser apache
            PassengerGroup apache
            DocumentRoot /var/www/html
            <Directory /var/www/html>
                Allow from all
            </Directory>
            RailsBaseURI /billing
            <Directory /var/www/html/billing>
                Options -MultiViews
           </Directory>
        </VirtualHost>
        " > /etc/httpd/conf.d/mor.conf
        chmod 777 /tmp/*.log
        rm -rf /etc/httpd/conf.d/crm.conf  #removing to not interfier      
    fi

}
crm_conf()
{
    if [ ! -f /etc/httpd/conf.d/mod_fcgid_include.conf ]; then
        echo "
        <VirtualHost *:80>
            PassengerUser apache
            PassengerGroup apache
            DocumentRoot /var/www/html
            <Directory /var/www/html>
                Allow from all
            </Directory>
            RailsBaseURI /tickets
            <Directory /var/www/html/tickets>
                Options -MultiViews
           </Directory>
        </VirtualHost>
        " > /etc/httpd/conf.d/crm.conf
        chmod 777 /tmp/*log /tmp/*txt
        rm -rf /etc/httpd/conf.d/mor.conf    # removing to not interfier
    fi
}
gem_selenium_client()
{
    local selenium_client=`gem list | grep selenium-client | wc -l`
    if [ "$selenium_client" == "0" ]; then
        cd /usr/src
        wget -c http://www.kolmisoft.com/packets/selenium/selenium-client-1.2.18.gem
        gem install selenium-client
        local selenium_client=`gem list | grep selenium-client | wc -l`
        if [ "$selenium_client" == "0" ]; then
            report "Failed to install selenium-client gem" 1
        else
            report "Installed selenium-client gem" 4
        fi
    fi
}
gather_log_about_machine_state_after_failed_test()
{
    # Author: Mindaugas Mardosas
    # Year:  2012
    # About:  This function logs all required info to a log which is sent to brain after a failed test.
    echo -e "\n\n============[`date +%0k\:%0M\:%0S`]  Additinional logs gathered after a failed test===================\n\n" >> $TMP_FILE

    echo -e "\n============ Top ===================\n\n" >> $TMP_FILE
    top -n 1 >> $TMP_FILE

    echo -e "\n============RAM===================\n\n" >> $TMP_FILE
    free -m >> $TMP_FILE
    echo -e "\n\n============Full System Process List===================\n\n" >> $TMP_FILE
    ps aux >> $TMP_FILE
    echo -e "\n\n============MySQL Process List===================\n\n" >> $TMP_FILE
    mysql mor -e "show processlist" 2>&1>> $TMP_FILE
}
#--------RVM
install_ruby_versions()
{
    # Author: Mindaugas Mardosas
    # Year:  2012
    # About: This function installs required Ruby versions
    source "/usr/local/rvm/scripts/rvm" &> /dev/null
    Ruby_versions=("1.8.7" "1.9.2-p318" "1.9.3")
    for element in $(seq 0 $((${#Ruby_versions[@]} - 1))); do   #will go throw the config and check against every setting mentioned in variable MOR_SETTINGS_LIST
        ruby_version=`echo ${Ruby_versions[$element]}`
        requirements=`rvm requirements $ruby_version | grep "ruby" | grep gcc | awk -F":" '{print $2}'`
        eval $requirements # installing requirements
        rvm install $ruby_version
    done
}

check_if_xvfb_is_running()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function ensures, that Xvfb frame buffer is started

    DEBUG=0;

    local xvfb_processes=`ps aux | grep Xvfb | grep -v 'grep' | wc -l` # OK - 2 processes, 1 for Xvfb, 1 for grep :)
    if [ "$xvfb_processes" != "1" ]; then
        if [ ! -f "/usr/bin/Xvfb" ]; then   # install if not present
            yum -y install xorg-x11-server-Xvfb
        fi
        killall -9 Xvfb &> /dev/null
        sleep 2 # giving a few seconds to finish. As it not allways finishes to stop on time

        echo "------ Xvfb debug -----------" >> /var/log/mor/n
        Xvfb :0 -ac -screen 0 1024x768x16 -ld 10240 -ls 1024 -lf 20 -to 60 -reset >> /var/log/mor/n &

        xvfb_processes=`ps aux | grep Xvfb | grep -v 'grep' | wc -l`
        if [ "$xvfb_processes" != "1" ]; then
            report "Xvfb failed to start" 1
            debug_resource_usage "Resource before attempt to start Xvfb"
            return 1 # failure - Xvfb failed to start
        else
            report "Xvfb works" 4
            return 0
        fi
    elif [ "$DEBUG" == "1" ]; then
        report "Xvfb frame buffer is running" 0
    fi
}
remove_apache_evil_semaphores()
{
    for i in `ipcs -s | awk '/apache/ {print $2}'`; do (ipcrm -s $i); done # clean apache semaphores: http://rackerhacker.com/2007/08/24/apache-no-space-left-on-device-couldnt-create-accept-lock/
}
actions_before_new_test()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This is a place for all house cleaning actions before new test
    #== House cleaning before tests
    #killall -9 dispatch.fcgi    # removing all dispatch processes. As they are hanging up and consuming RAM;           We are using passenger now
    mkdir -p  /dev/shm/sessions
    chmod 777 -R  /dev/shm/sessions
    
    sync; echo 3 > /proc/sys/vm/drop_caches &> /dev/null # clean mem cache
    #=======================LOGS==============================

    
    rm -rf /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log /tmp/mor_pdf_test.pdf
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log
    chmod 777 /var/log/httpd/access_log /var/log/httpd/error_log /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/mor/selenium_server.log
        
    # clean uploaded auto dialer files; Hardcoding for now. Please note that this value can also be set in environment.rb. Also please note that the path currently set there is just a symlink
    rm -rf /home/mor/public/ad_sounds/*.wav
    # cleaning test IVR files
    find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf
    touch  /tmp/mor_crash_email.txt /tmp/mor_debug.txt /tmp/mor_crash.log /tmp/mor_crash.txt /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log
    mkdir -p /home/mor/log /var/log/httpd
    chmod 777 /tmp/mor_crash_email.txt /tmp/mor_debug.txt /tmp/mor_crash.log /tmp/mor_crash.txt /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log

    #=====================================================
}
actions_before_new_revision()
{
    remove_apache_evil_semaphores
    sysctl -w vm.swappiness=0  &> /dev/null # turn off swap
    echo 0 >/proc/sys/vm/swappiness  &> /dev/null
    chmod -R 777 /usr/local/mor/backups/restore
    rm -rf /home/DB_BACKUP_*
}

install_sphinx()
{
    cd /urs/src
    wget -c  http://sphinxsearch.com/files/sphinx-0.9.9.tar.gz
    tar xzvf sphinx-0.9.9.tar.gz
    cd sphinx-0.9.9
    ./configure
    make
    make install
    /usr/local/bin/searchd --config /home/tickets/config/production.sphinx.conf
    cd /home/tickets;
    rake thinking_sphinx:index RAILS_ENV=production
}
install_crm2()
{
    yum -y install screen subversion httpd httpd-devel mysql vim-enhanced mcedit anacron mysq-devel mysql-server curl curl-devel mod_ssl
    if [ -d "/home/tickets" ]; then mv /home/tickets /home/tickets_OLD; fi
    svn co http://svn.kolmisoft.com/crm/branches/ror3 /home/tickets
    rm -rf /home/tickets/selenium
    svn update /home/tickets
    crm_conf
    cd /home/tickets
    rvm alias create default ruby-1.9.2-p318
    rvm ruby-1.9.2-p318
    bundle
    passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
}

#===========================
#-------- GIT -----------
#git_check_and_install()
#{
#    #   Author: Mindaugas Mardosas
#    #   Year:   2010
#    #   About:  This func installs git if it is not present
#    if [ ! -f /usr/bin/git ]; then
#        cd /usr/src/
#        wget -c http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm
#        rpm -Uvh epel-release-*
#        yum check-update
#        yum -y install git
#    fi
#}
#----------- gems ----------
gem_rest_client_check_and_install()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func installs rest-client gem if it is not present
    /usr/bin/gem list | grep rest &> /dev/null
    if [ "$?" != "0" ]; then
        /usr/bin/gem install rest-client
        if [ "$?" != "0" ]; then
            echo "[`date +%0k\:%0M\:%0S`] FAILED TO INSTALL GEM: rest-client" | tee -a /var/log/mor/test_system
            rm -rf /tmp/.mor_test_is_running
            exit 1;
        fi
    fi
}
#------- BRAIN--------------------
#checkout_brain_script()
#{
#    #   Author: Mindaugas Mardosas
#    #   Year:   2010
#    #   About:  This func downloads latest Kolmisoft TEST SYSTEM v2 brain scripts from brain git repo
#    GIT_REPO_ADDRESS="192.168.0.13"
#    #git_check_and_install
#    #rm -rf /usr/local/mor/test_environment/brain-scripts
#    #cd /usr/local/mor/test_environment
#    rm -rf /usr/src/brain-scripts
#    cd /usr/src
#    /usr/bin/git clone git://$GIT_REPO_ADDRESS/brain-scripts.git
#}
#---------------------------

default_interface_ip()
{
    #Author: Mindaugas Mardosas
    #This function makes available in your scripts 2 variables: DEFAULT_INTERFACE  - this will be the name of the default interface throw which the traffic will be routed when no other destination adress mathced in kernel routing table. DEFAULT_IP - this is the IP assigned to DEFAULT_INTERFACE
    #How to use this function:
        # write anywhere in your script a call to this function and then you can use those two global variables for that script. Example:
        #       default_interface_ip;
        #       echo $DEFAULT_INTERFACE;
        #       echo $DEFAULT_IP;

    DEFAULT_INTERFACE=`/bin/netstat -nr | (read; cat) | (read; cat) | grep "^0.0.0.0" | awk '{ print $8}'` #Gets kernel routing table, when skips 2 first lines, when grep's the default path and finally prints the interface name
    DEFAULT_IP=`/sbin/ip addr show $DEFAULT_INTERFACE | grep "inet " | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`
}

#-----------Selenium------------
start_selenium_server()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if selenium-server is already running in the server

    # outdated



    SELENIUM_SERVER_LOG="/var/log/mor/selenium_server.log"
    running=`ps aux | grep -m 1 selenium-server.jar | awk '{ print $NF}' | head -n 1`
    if [ "$running" == "-singleWindow" ]; then
        return 0
    else
        echo "[`date +%0k\:%0M\:%0S`] Starting selenium server"
        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar -singleWindow >> /var/log/mor/selenium_server.log &
    fi
}
#-------------------------------------------
_mor_time()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2008
    #   About:  This function gets current system time in a convenient time format

 	mor_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
}
svn_update_if_files_are_missing()
{
    # Author: Mindaugas Mardosas
    # Year: 2011-2012
    # About: check if files are missing. If yes - checks them out from repo

    GUI_PATH="$1"
    if [ `svn status $GUI_PATH | grep ! | wc -l` != "0" ]; then
        report "Found missing files in $GUI_PATH, getting those files from svn. In order to check for missing files manualy use command: svn status $GUI_PATH | grep !" 3
        svn update $GUI_PATH
    fi
}


#======== MOR/CRM related=========
prepare_db()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function prepares a correct db version for that GUI revision. This function keeps x last db versions of each version and rotates them.
    #
    #   Requires:
    #       Global variable dbVersionsToKeep=20;

    #---checking if DB revision is newest
        if [ "$TEST_MOR_VERSION" == "tickets" ] || [ "$TEST_PRODUCT" == "crm" ]; then    #updating current version
            local DB_VERSION=`svn info /home/tickets/selenium/sql | grep 'Last Changed Rev:' | awk '{print $4}'`
        else
            if [ "$TEST_MOR_VERSION" == "8" ]; then    # if we want specific version (mor -l 8)
                local DB_VERSION=`svn info /usr/src/mor/db/0.8 | grep 'Last Changed Rev:' | awk '{print $4}'`       #for historical numbering purposes
            elif [ "$TEST_MOR_VERSION" == "trunk" ]; then
                local DB_VERSION=`svn info /usr/src/mor/db/trunk | grep 'Last Changed Rev:' | awk '{print $4}'`
               
            # FIX ME:
            # As for now we are using the same database revision for m2 as for X5
            # As don not have /usr/src/mor/db/m2 yet
            
            elif [ "$TEST_MOR_VERSION" == "m2" ]; then
                local DB_VERSION=`svn info /usr/src/mor/db/m2 | grep 'Last Changed Rev:' | awk '{print $4}'`
            else
                local DB_VERSION=`svn info /usr/src/mor/db/$TEST_MOR_VERSION | grep 'Last Changed Rev:' | awk '{print $4}'`
            fi
        fi
    #-------- /Checking if DB revision is newest

    #======= For GUI sessions cleanup============
    rm -rf /dev/shm/sessions 
    mkdir -p /dev/shm/sessions
    chmod 777 -R /dev/shm/sessions        
    #=================================
    
    create_ramdisk  # recreate only if there is not enough free space or virtual disk does not exist

    if [ ! -f /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql ]; then
        report "/dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql not found, creating new DB for this revision"  3

        n_update_source

        if [ "$TEST_MOR_VERSION" == "tickets" ] || [ "$TEST_PRODUCT" == "crm" ]; then    #updating current version
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Importing fresh CRM DB"
            mysql tickets -e "show tables" | grep -v Tables_in | grep -v "+" | gawk '{print "drop table " $1 ";"}' | mysql tickets
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/struckt.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/struckt.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/translations.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/translations.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/conflines.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/conflines.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/emails.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/emails.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/hearfromusplaces.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/hearfromusplaces.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/directions.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/directions.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/permissions.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/permissions.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/datas.sql" 3; fi
            mysql tickets < /home/tickets/selenium/sql/datas.sql
            if [ "$N_DEBUG" == "1" ]; then report "Importing /home/tickets/selenium/sql/permissions_data_changes.sql" 3; fi
            mysql tickets < /home/tickets/doc/permissions_data_changes.sql
        else
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Creating fresh DB for $TEST_MOR_VERSION Revision: $TEST_REVISION"

            if [ "$N_DEBUG" == "1" ]; then report "Creating fresh db: /usr/src/mor/db/0.8//make_new_db.sh nobk" 3; fi
            cd /usr/src/mor/db/0.8/
            ./make_new_db.sh nobk

            if [ "$TEST_MOR_VERSION" == "8" ]; then    # if we want specific version (mor -l 8)
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;

            elif [ "$TEST_MOR_VERSION" == "9" ]; then  # if we want specific version (mor -l 9)
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_9_testdb.sql
            elif [ "$TEST_MOR_VERSION" == "10" ]; then
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_9_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_9_testdb.sql
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
                /usr/src/mor/db/10/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_trunk_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql

            elif [ "$TEST_MOR_VERSION" == "trunk" ]; then # MOR 11 normal
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
                /usr/src/mor/db/10/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/trunk/import_changes.sh" 3; fi
                /usr/src/mor/db/trunk/import_changes.sh
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql

            elif [ "$TEST_MOR_VERSION" == "11" ]; then # MOR 11 EXTENDED
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
                /usr/src/mor/db/10/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/11/import_changes.sh" 3; fi
                /usr/src/mor/db/11/import_changes.sh
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql

            elif [ "$TEST_MOR_VERSION" == "12.126" ]; then # MOR 12 with ROR 1.26 (previously called MOR 11 Extend)
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_0.8_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
                /usr/src/mor/db/10/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/11/import_changes.sh" 3; fi
                /usr/src/mor/db/12.126/import_changes.sh
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql

            elif [ "$TEST_MOR_VERSION" == "12" ]; then  # MOR 12 with ROR3
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
                /usr/src/mor/db/9/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
                /usr/src/mor/db/10/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/trunk/import_changes.sh" 3; fi
                /usr/src/mor/db/trunk/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/12/import_changes.sh" 3; fi
                /usr/src/mor/db/12/import_changes.sh
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_trunk_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
                /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh
                
            elif [ "$TEST_MOR_VERSION" == "x4" ]; then  # MOR 12 with ROR3
                if [ "$N_DEBUG" == "1" ]; then report "Importing /usr/src/mor/test/node2/12.sql" 3; fi
                mysql mor < /usr/src/mor/test/node2/12.sql
                
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/local/rvm/bin/ruby-1.9.3-p327@x4  /usr/src/mor/upgrade/x4/sipchaning.rb " 3; fi
                /usr/local/rvm/bin/ruby-1.9.3-p327@x4  /usr/src/mor/upgrade/x4/sipchaning.rb 
                
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/x4/import_changes.sh" 3; fi
                /usr/src/mor/db/x4/import_changes.sh "NO_SCREEN"            
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_trunk_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
                /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh
                
            elif [ "$TEST_MOR_VERSION" == "x5" ]; then  # MOR 12 with ROR3
                if [ "$N_DEBUG" == "1" ]; then report "Importing /usr/src/mor/test/node2/db/x4.sql" 3; fi
                mysql mor < /usr/src/mor/test/node2/db/x4.sql
                #if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/x4/import_changes.sh" 3; fi
                #/usr/src/mor/db/x4/import_changes.sh "NO_SCREEN"
                
                if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/x5/import_changes.sh" 3; fi
                /usr/src/mor/db/x5/import_changes.sh "NO_SCREEN"
                
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_trunk_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
                /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh 
                
            elif [ "$TEST_MOR_VERSION" == "m2" ]; then  # MOR 12 with ROR3
                if [ "$N_DEBUG" == "1" ]; then report "Importing /usr/src/mor/test/node2/db/x4.sql" 3; fi
                mysql mor < /usr/src/mor/test/node2/db/x4.sql
                #if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/x4/import_changes.sh" 3; fi
                #/usr/src/mor/db/x4/import_changes.sh "NO_SCREEN"
                
                report "Running /usr/src/mor/db/m2/import_changes_dev.sh" 3;
                /usr/src/mor/db/m2/import_changes_dev.sh
                
                if [ "$N_DEBUG" == "1" ]; then report "Importing /home/mor/selenium/mor_trunk_testdb.sql" 3; fi
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
                /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh 
            fi

            reconfigure_db "mor" "localhost"
            
        fi

        

        rotate_files_dirs /dev/shm/pool/"$TEST_MOR_VERSION" "$dbVersionsToKeep" on   &> /dev/null   #   rotating
        echo "[`date +%0k\:%0M\:%0S`] Exporting DB to /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql";

        report "Dumping $TEST_MOR_VERSION for later use as cache: /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql" 3      
        #--- dumping DB for later use as cache
        mkdir -p /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION
        if [ "$TEST_MOR_VERSION" == "tickets" ]; then    #updating current version
            mysqldump --single-transaction tickets > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
            if [ "$?" != "0" ]; then
                mysqldump --single-transaction tickets > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
                if [ "$?" != "0" ]; then
                    report "Database dump: mysqldump --single-transaction tickets > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql failed 2 times. Removing node from brain" 1
                    rm -rf /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
                    n -remove
                fi
            fi
        else
            mysqldump --single-transaction -h localhost -u mor -pmor mor > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
            if [ "$?" != "0" ]; then
                mysqldump --single-transaction -h localhost -u mor -pmor mor > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
                if [ "$?" != "0" ]; then
                    report "Database dump: mysqldump --single-transaction -h localhost -u mor -pmor mor > /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql failed 2 times. Removing node from brain" 1
                    rm -rf /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
                    n -remove
                fi
            fi            
        fi

    else    #we already have such db of such revision
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Importing DB from /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql"
        if [ "$TEST_MOR_VERSION" == "tickets" ]; then
            mysql tickets < /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
        else
            mysql -h localhost -u mor -pmor mor < /dev/shm/pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION.sql
            reconfigure_db "mor" "localhost"
        fi
    fi
}


check_if_required_services_are_running()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function checks if all required service for test are running. If not - aborts testing

    local DO_NO_EXIT="$1"
    local abort=0 #abort is not needed

    if [ `service mysqld status | grep running | wc -l` != "1" ]; then
        report "MySQLd is not running, aborting test" 1
        MYSQLd_STATUS=1
        abort=1
    fi

    if [ `service httpd status | grep running | wc -l` != "1" ]; then
        report "HTTPd is not running, aborting test" 1
        HTTPd_STATUS=1
        abort=1
    fi

    #check_if_xvfb_is_running
    #if [ `ps aux | grep Xvfb | grep -v grep | wc -l` != "1" ]; then
    #    report "Xvfb is not running (not critical), attempting to fix this" 3


        #report "Xvfb is not running, aborting test" 1
        #XVFB_STATUS=1
        #abort=1
    #fi

    if [ "$abort" == "1" ]; then
        echo "Further testing was abbrted because one of required services were not running" >> /var/log/mor/n
        default_interface_ip
        /usr/local/mor/sendEmail -f 'brain@kolmisoft.com' -t $BRAIN_MONITORING_GROUP -m "IP: $DEFAULT_IP\nMAC: $DEFAULT_INTERFACE_MAC" -u "[BRAIN NODE $DEFAULT_IP DEAD]" -s "vilnius.balt.net"
        if [ "$DO_NO_EXIT" != "DO_NO_EXIT" ]; then
            debug_resource_usage
            /bin/n -remove  # automatically removing node from brain
            exit 1
        else
            debug_resource_usage
            return 1
        fi
    fi
}

generate_suite_file()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function works as a wrapper for old selenium tests
    #
    # $1  - test to add to suite file
    
    local TEST_NAME="$1"
    local TEST_TEST="$2"
    
    echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
  <title>Test Suite</title>
</head>
<body>
<table id="suiteTable" cellpadding="1" cellspacing="1" border="1" class="selenium"><tbody>
<tr><td><b>Test Suite</b></td></tr>
<tr><td><a href="'$TEST_NAME.html'">'$TEST_TEST'</a></td></tr>
</tbody></table>
</body>
</html>' > /tmp/suite.html    
    
}
convert_and_run_rb()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function converts and runs a single test case
    
    #if [ "$PROFILE" == "1" ]; then
        TMP_FILE=`mktemp`
        echo -e "\n\n============RAM Before Test===================\n\n" >> $TMP_FILE
        free -m >> $TMP_FILE
        echo -e "\n\n============/RAM Before Test===================\n\n" >> $TMP_FILE
    
        debug_resource_usage "Resources before running test $TEST_TEST.case"
    #fi
        
    report "Generating test suite file" 3
    
    TEST_NAME=`echo "$TEST_TEST" | awk -F "/" '{print $NF}'`
    generate_suite_file $TEST_NAME $TEST_TEST

    #killall -9 Xvfb &> /dev/null
    #killall -9 java &> /dev/null

    report "$TEST_TEST now will be tested" 3

    rm -rf /tmp/rezultatas.html
    report "Launching testing" 3
    cd /tmp
    # Here is is very important part - the script adds here at the beginning of test new command setTimeout which sets timeout for each command in the test. 60000 = 60 seconds
    if [ "$TEST_PRODUCT" == "mor" ]; then
        sed -e 's/<\/thead><tbody>/<\/thead><tbody>\n<tr>\n<td>setTimeout<\/td>\n<td>10000<\/td>\n<td><\/td>\n<\/tr>/g' /home/mor/selenium/tests/$TEST_TEST.case > /tmp/$TEST_NAME.html
    elif [ "$TEST_PRODUCT" == "crm" ]; then
        sed -e 's/<\/thead><tbody>/<\/thead><tbody>\n<tr>\n<td>setTimeout<\/td>\n<td>10000<\/td>\n<td><\/td>\n<\/tr>/g' /home/tickets/selenium/tests/$TEST_TEST.case > /tmp/$TEST_NAME.html
    fi

    copy_selenium_to_ram_if_not_present
    SELENIUM_START_TIMESTAMP=`date +%s`
    DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar  -userExtensions /usr/src/mor/test/files/selenium/user-extensions.js  -singleWindow -htmlSuite "*firefox" "http://$DEFAULT_IP" "/tmp/suite.html" "/tmp/rezultatas.html"
    SELENIUM_FINISH_TIMESTAMP=`date +%s`

    #TEST_STATUS="$?"
    echo "========= HTML ATASKAITA ============" >> $TMP_FILE
    cat /tmp/rezultatas.html >> $TMP_FILE
    job_report 0 >> /var/log/mor/n

    rm -rf $TMP_FILE

}
is_another_test_still_running()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if the script is already running

	if [ -f "$TEST_RUNNING_LOCK" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Found a lock. Lock can be removed by: rm -rf $TEST_RUNNING_LOCK";
	    exit 0;
	fi
}
#----------- Job_ask ---------

job_ask()
{
#   Author: Mindaugas Mardosas
#   Year:  2011-2012
#   About: This function gets a job from brain.

    set +x
    local DEBUG="1"
    local PRODUCT="$1"
    local VERSION="$2"
    local REVISION="$3"



    default_interface_ip #getting IP and mac address

    local work=`/bin/mktemp`

    if [ "$TEST_PRODUCT" != "" ] && [ "$TEST_MOR_VERSION" != "" ] && [ "$TEST_REVISION" != "" ]; then
        if [ "$DEBUG" == "1" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. curl http://$BRAIN/api/request_job?version=$TEST_MOR_VERSION&revision=$TEST_REVISION&product=$TEST_PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"
        fi
        curl "http://$BRAIN/api/request_job?version=$TEST_MOR_VERSION&revision=$TEST_REVISION&product=$TEST_PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work
    else
        if [ "$DEBUG" == "1" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. curl http://$BRAIN/api/request_job?mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"
        fi
        curl "http://$BRAIN/api/request_job?mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work
    fi

    JOB_RECEIVED_TIMESTAMP=`date +%s`

    BEGIN_TEST=`cat $work | awk -F"," '{print $1}'`
    TEST_PRODUCT=`cat $work | awk -F","  '{print $2}'`
    TEST_MOR_VERSION=`cat $work | awk -F"," '{print $3}'`
    TEST_REVISION=`cat $work | awk -F"," '{print $4}'`
    TEST_TEST=`cat $work | awk -F","  '{print $5}'`
    TEST_NODE_ID_FROM_BRAIN=`cat $work | awk -F","  '{print $6}'`

    TEST_TEST=`echo $TEST_TEST | awk -F"." '{print $1}'`
    
    report "Got answer: BEGIN_TEST: $BEGIN_TEST, TEST_PRODUCT: $TEST_PRODUCT, TEST_MOR_VERSION: $TEST_MOR_VERSION, TEST_REVISION: $TEST_REVISION, TEST_TEST: $TEST_TEST, TEST_NODE_ID_FROM_BRAIN: $TEST_NODE_ID_FROM_BRAIN" 3

    if [ "$BEGIN_TEST" == "9" ]; then   # launch fixes
        n_update_source
        if [ "$?" != "0" ]; then    # wait till any lock is removed
            sleep 10
        fi
        report "Got signal 9 from brain. Restarting test script" 2

        CURRENT_PROCESS=$$
        ps aux | grep "ruby\|java\|firefox\|Xvfb\|\/bin\/n" | awk '{print $2}' | grep -v $CURRENT_PROCESS | xargs kill
        exit 0 #exit ant wait till the tests begins again
    fi

    rm -rf $work
    if [ "$BEGIN_TEST" != "1" ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. No Jobs" | tee -a /var/log/mor/test_system
        rm -rf "$TEST_RUNNING_LOCK";
        
        cleanup_various_files
        exit 0
    fi
}
job_report()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011-2012
    #   About:  This function reports test results after each test

    _mor_time
    if [ ! -f /usr/src/brain-scripts/reporter.rb ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. /usr/src/brain-scripts/reporter.rb not found" | tee -a /var/log/mor/test_system
        rm -rf "$TEST_RUNNING_LOCK";
        exit 1;
    fi

    grep -v -F "^warn: Current subframe appears" $TMP_FILE | grep "^error:\|^warn:"   &> /dev/null     # first grep - naisty hack for crm to ignore the message by selenium and report that test as ok
    if [ "$?" == "0" ]; then
        STATUS_v2="FAILED";
    else
        STATUS_v2="OK";
    fi

    if [ -f /usr/src/brain-scripts/reporter.rb ]; then
	echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Reporting to BRAIN..."
        if [ "$TEST_PRODUCT" == "mor" ]; then
            RELATVE_PATH_TO_TEST=`echo $TEST_TEST | sed 's/\/home\/mor\/selenium\/tests\///'`
        elif [ "$TEST_PRODUCT" == "crm" ]; then
            RELATVE_PATH_TO_TEST=`echo $TEST_TEST | sed 's/\/home\/tickets\/selenium\/tests\///'`
        fi
        local counter=0;
        while [ "$counter" != "5" ]; do
            counter=$(($counter+1))
            local temp=`mktemp`


            if [ "$STATUS_v2" == "OK" ]; then
                if [ "$TEST_PRODUCT" == "mor" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN"  "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 $TEST_NODE_ID_FROM_BRAIN  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"test_log $TMP_FILE\""
                elif [ "$TEST_PRODUCT" == "crm" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb 'tickets' $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN" "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP"  "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb tickets $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 $TEST_NODE_ID_FROM_BRAIN  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"test_log $TMP_FILE\""
                fi
            else
                gather_log_about_machine_state_after_failed_test  # the test failed, gathering additional logs

                if [ "$TEST_PRODUCT" == "mor" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN"  "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP" "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"$TEST_NODE_ID_FROM_BRAIN\"  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"my_debug /tmp/mor_debug.txt\" \"crash_log /tmp/mor_crash.log\" \"production_log /home/mor/log/production.log\" \"access_log /var/log/httpd/access_log\" \"error_log  /var/log/httpd/error_log\" \"selenium_server_log /var/log/mor/selenium_server.log\" \"test_log $TMP_FILE\""
                elif [ "$TEST_PRODUCT" == "crm" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb 'tickets' $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN" "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP"  "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb tickets $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"$TEST_NODE_ID_FROM_BRAIN\"  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"my_debug /tmp/mor_debug.txt\" \"crash_log /tmp/mor_crash.log\" \"production_log /home/mor/log/production.log\" \"access_log /var/log/httpd/access_log\" \"error_log  /var/log/httpd/error_log\" \"selenium_server_log /var/log/mor/selenium_server.log\" \"test_log $TMP_FILE\""
                fi

            fi
            grep "RECEIVED" $temp &> /dev/null
            if [ "$?" == "0" ]; then
                rm -rf /tmp/reporter.log $temp
                echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Reporting complete! Job WAS RECEIVED BY BRAIN"
                break;
            fi
            rm -rf /tmp/reporter.log $temp
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Still reporting..."
            sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
        done
        if [ "$counter" -ge "5" ]; then # if reporting to brain failed
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Test reporting to brain failed: [ $STATUS_v2 ] $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $TEST_REVISION $RELATVE_PATH_TO_TEST "
        fi
    else
        echo "[`date +%0k\:%0M\:%0S`] The reporter script was not found"
    fi
}
#---------GUI--------------------
change_email_in_environment_rb()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function replaces default reporting mail

    sed 's/guicrashes@kolmisoft.com\|support@kolmisoft.com/kolmisoft.mindaugas.crm@gmail.com/g'  /home/mor/config/environment.rb > /home/mor/config/environment.rb2
    mv /home/mor/config/environment.rb2 /home/mor/config/environment.rb
}
move_current_gui_to_pool()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function moves current MOR/CRM GUI to safe place for the next time

    if [ "$TEST_MOR_VERSION" != "tickets" ]; then
        mor_gui_current_version
        _mor_time
        if [ -d /home/mor ]; then
            mkdir -p /home/gui_pool
            if [ "$N_DEBUG" == "1" ]; then
                echo "[DEBUG] F: move_current_gui_to_pool: TEST_MOR_VERSION: $TEST_MOR_VERSION"
            fi

            if [ -d /home/mor ]; then #moving if directory exists
                mv /home/mor /home/gui_pool/"$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
                echo "$mor_time Moved /home/mor to /home/gui_pool/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
            fi
        else
            echo "$mor_time Failed to move /home/mor - /home/mor does not exist!"
        fi
    fi
}
get_gui_from_pool()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011-2012
    #   About:  This function gets required MOR/CRM GUI from available gui pool
    #source "/usr/local/rvm/scripts/rvm"
    if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Entered function get_gui_from_pool()"; fi
    mkdir -p /home/gui_pool
    #killall -9 httpd &> /dev/null
    if [ "$TEST_MOR_VERSION" != "tickets" ]; then
        if [ -d "/home/gui_pool/$TEST_MOR_VERSION" ]; then
            if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Found matching folder in /home/gui_pool/$TEST_MOR_VERSION"; fi
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Moving /home/gui_pool/$TEST_MOR_VERSION /home/mor"
            mv /home/gui_pool/$TEST_MOR_VERSION /home/mor     #this operation is very guick because it just physically rewrites the address of a directory!
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating $TEST_MOR_VERSION from svn to revision: $TEST_REVISION"
            svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
            svn status /home/mor | grep -v "public\|lang\|config\|gui_upgrade\|TRANS.TBL\|assets_log" | xargs rm -rf
            svn update -r $TEST_REVISION /home/mor &> /dev/null

            #-- bundle update here if version is greater or equal MOR 12
                           
            mor_check_fix_assets    # recompiles assets if needed: MOR X3 and MOR X4 only
            

            #post_MOR gui_update:
            mkdir -p /home/mor/public/ad_sounds
            ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad &> /dev/null
            chmod -R 777 /home/mor/public/images/logo /home/mor/public/images/cards /home/mor/public/ad_sounds &> /dev/null

            touch  /tmp/mor_crash_email.txt /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log
            mkdir -p /home/mor/log /var/log/httpd
            chmod 777 /tmp/mor_crash_email.txt /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log
        else
            #Download MOR GUI and copy configs
            _mor_time
            echo "$mor_time: /home/gui_pool/$TEST_MOR_VERSION is not available, downloading MOR GUI"
            #--------------
            mkdir -p /home/gui_pool
            cd /home/gui_pool
            
            # TO DO how to upload m2 to http://$BRAIN/files/gui
            # which function/script does that?
            
            echo "$TEST_MOR_VERSION"
            
            if [ "$TEST_MOR_VERSION" == "m2" ]; then
                mkdir -p /home/gui_pool/m2
                svn co  http://svn.kolmisoft.com/m2/gui/trunk/ /home/gui_pool/m2 &> /dev/null
            else
                wget -c http://$BRAIN/files/gui/mor_$TEST_MOR_VERSION.tar.gz
                tar xzvf mor_$TEST_MOR_VERSION.tar.gz
                mv mor $TEST_MOR_VERSION
            fi
            
            if [ ! -d "$TEST_MOR_VERSION" ]; then
                echo "Failed to download and prepare MOR GUI, check get_gui_from_pool function!"
            else
                get_gui_from_pool   #running the function again
            fi
        fi
    else    # ==crm (tickets)
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating /home/tickets from svn to revision: $TEST_REVISION"
        if [ ! -d /home/tickets ]; then
            mkdir -p /home/gui_pool
            cd /home/gui_pool
            wget -c http://$BRAIN/files/gui/tickets.tar.gz
            tar xzvf tickets.tar.gz
            mv tickets /home/tickets
        else
            svn status /home/tickets | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/tickets" | xargs rm -rf
        fi
        svn update -r $TEST_REVISION /home/tickets
        cd /home/tickets
        rvm alias create default ruby-1.9.2-p318
        rvm ruby-1.9.2-p318
        bundle &
        BUNDLER_P_ID=$!

        passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
        #--------
        change_crm_ip_if_does_not_match # fixes CRM WEB_URL
        change_crm_web_dir_does_not_match
        #--------
        wait $BUNDLER_P_ID
        service httpd start
    fi

    if [ "$TEST_MOR_VERSION" == "tickets" ] && [ ! -d "/home/tickets" ]; then   #"crm" is historical crm name
        _mor_time
        echo "[`date +%0k\:%0M\:%0S`] $mor_time: /home/tickets is not available, fix this"
    fi
    
    # Fix me: quick hack to get environment.rb and database.yml
    if [ "$TEST_MOR_VERSION" == "m2" ]; then
        cp /usr/src/mor/upgrade/x5/files/environment.rb /home/mor/config/environment.rb
        cp /usr/src/mor/upgrade/x5/files/database.yml  /home/mor/config/database.yml
        reconfigure_db "mor" "localhost"
    fi
}
change_ip_if_does_not_match()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function changes IP in environment.rb if it does not match any ip from ifconfig output
    #
    #default_interface_ip
    #DEFAULT_IP=`echo $DEFAULT_IP | awk '{print $NF}'`
    # "default ip" is now changed to node.kolmisoft.com DNS address
    DEFAULT_IP="node.kolmisoft.com"
    if [ `grep -F "$DEFAULT_IP" /home/mor/config/environment.rb | wc -l` != "2" ]; then
        replace_line /home/mor/config/environment.rb "Recordings_Folder" "Recordings_Folder = \"http://$DEFAULT_IP/billing/recordings/\""
        replace_line /home/mor/config/environment.rb "Web_URL" "Web_URL = \"http://$DEFAULT_IP\""
    fi
}
change_crm_web_dir_does_not_match()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function changes Web_Dir in environment.rb
    #

        replace_line /home/tickets/config/environment.rb "Web_Dir" "Web_Dir = \"/tickets\""
}
change_crm_ip_if_does_not_match()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function changes IP in environment.rb if it does not match any ip from ifconfig output
    #
    default_interface_ip
    if [ `grep -F "$DEFAULT_IP" /home/tickets/config/environment.rb | wc -l` != "2" ]; then
        replace_line /home/tickets/config/environment.rb "Web_URL" "Web_URL = \"http://$DEFAULT_IP\""
    fi
}
disable_sql_caching()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function disables very nasty rails feature with caching. After database import/reload rails sees old DB structure

    if [ `grep config.cache_classes /home/mor/config/environments/production.rb | grep true | wc -l` == "1" ]; then
        local temp=`mktemp`
        sed '/config.cache_classes/d' /home/mor/config/environments/production.rb > $temp
        echo  "config.cache_classes = false " >> $temp
        mv $temp /home/mor/config/environments/production.rb
        chmod 777 /home/mor/config/environments/production.rb
    fi
}
prepare_gui()
{
    #
    #   Author: Mindaugas Mardosas
    #   Year:   2011-2013
    #   About:  This function prepares required MOR, crm GUI version AND revision for testing
    #

    
    if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Entered function prepare_gui()"; fi

    if [ "$TEST_MOR_VERSION" != "tickets" ]; then
        
        mor_gui_current_version  &> /dev/null #getting current version of GUI, provides variable: MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS
        if [ "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS" != "$TEST_MOR_VERSION" ] || [ -f "/etc/httpd/conf.d/crm.conf" ]; then
            if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS:|$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS| TEST_MOR_VERSION:|$TEST_MOR_VERSION|"; fi
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Changing MOR version to $TEST_MOR_VERSION"

            move_current_gui_to_pool
            get_gui_from_pool
            change_email_in_environment_rb
            change_ip_if_does_not_match
            mor_addons

            touch /tmp/mor_crash.txt /tmp/mor_debug.log
            chmod 777 /tmp/mor_crash.txt /tmp/mor_debug.log
                
            #INSERT TESTING SESSION: to measure session size
            if [ `awk -F'#' '{print $1}' /home/mor/config/environment.rb | grep  TEST_MACHINE_SESSION | wc -l` == "0" ]; then
                echo "TEST_MACHINE_SESSION=1" >> /home/mor/config/environment.rb
            fi                
            
            #------ Ruby and other environment options for specific MOR version ----
            if [ "$TEST_MOR_VERSION" == "8" ] || [ "$TEST_MOR_VERSION" == "9" ] || [ "$TEST_MOR_VERSION" == "10" ] || [ "$TEST_MOR_VERSION" == "11" ] || [ "$TEST_MOR_VERSION" == "trunk" ] || [ "$TEST_MOR_VERSION" == "12.126" ]; then
                if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] TEST_MOR_VERSION: $TEST_MOR_VERSION. Preparing ruby-1.8.7"; fi
                change_ruby_version "1.8.7"
                disable_sql_caching # rails bug
            elif [ "$TEST_MOR_VERSION" == "12" ]; then
                if [ `/usr/local/rvm/bin/rvm list | grep ruby-1.9.3-p194 | head -n 1 | awk '{print $1}'` != "=*" ]; then
                    if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] TEST_MOR_VERSION: $TEST_MOR_VERSION. Preparing ruby-1.9.3-p194"; fi
                    change_ruby_version "1.9.3"

                fi
            elif [ "$TEST_MOR_VERSION" == "x4" ]; then
                if [ `/usr/local/rvm/bin/rvm list | grep 1.9.3-p327 | head -n 1 | awk '{print $1}'` != "=*" ]; then
                    if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] TEST_MOR_VERSION: $TEST_MOR_VERSION. Preparing ruby-1.9.3-p327"; fi
                    change_ruby_version "1.9.3"
                fi                
            elif [ "$TEST_MOR_VERSION" == "x5" ] || [ "$TEST_MOR_VERSION" == "m2" ]; then
                if [ `/usr/local/rvm/bin/rvm list | grep 2.0.0-p247 | head -n 1 | awk '{print $1}'` != "=*" ]; then
                    if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] TEST_MOR_VERSION: $TEST_MOR_VERSION. Preparing ruby-2.0.0-p247"; fi
                    change_ruby_version "2.0.0-p247@x5"
                fi                
            fi
            
            unlink /home/mor/public/recordings &> /dev/null
            mor_conf
            #-----------------------------------------------------------------------
            gui_revision_check 0
            
            if [ "$GUI_REVISION_IN_SYSTEM" != "$TEST_REVISION" ]; then
                if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Current system revision: $GUI_REVISION_IN_SYSTEM and request to test revision: $TEST_REVISION do not match:"; fi
                echo -e "GUI_REVISION_IN_SYSTEM: $GUI_REVISION_IN_SYSTEM\tTEST_REVISION: $TEST_REVISION"
                svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
                svn update -r $TEST_REVISION /home/mor
                GUI_WAS_UPDATED="TRUE"
                if [ -f "/home/mor/Gemfile" ]; then
                    check_if_rebundle_is_needed "/home/mor"
                fi
            else
                svn_update_if_files_are_missing "/home/mor"
            fi

            mor_check_fix_assets    # X4 and X3 only
            #============================================================
        else
            if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] MOR version matched."; fi
            gui_revision_check 0
            
            if [ "$GUI_REVISION_IN_SYSTEM" != "$TEST_REVISION" ]; then
                svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
                svn update -r $TEST_REVISION /home/mor
                GUI_WAS_UPDATED="TRUE"
            else
                if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] MOR revisions matched also."; fi
                svn_update_if_files_are_missing "/home/mor"
            fi

            if [ "$TEST_MOR_VERSION" == "12" ] || [ "$TEST_MOR_VERSION" == "x4" ]; then
                change_ruby_version "1.9.3"
                mor_check_fix_assets
                check_if_rebundle_is_needed "/home/mor"
            elif [ "$TEST_MOR_VERSION" == "x5" ] || [ "$TEST_MOR_VERSION" == "m2" ]; then
                change_ruby_version "2.0.0-p247@x5"
                #mor_check_fix_assets
                check_if_rebundle_is_needed "/home/mor"
            else
                #--------- Fixes
                disable_sql_caching # rails bug
                change_ruby_version "1.8.7"
            fi
        fi
        
        #==== Enable debug loggin if disabeld ====
        if [ -f "/home/mor/config/environments/production.rb" ]; then
            sed 's!config.log_level = :info!config.log_level = :debug!' /home/mor/config/environments/production.rb > /tmp/mor_tmp 
            mv /tmp/mor_tmp  /home/mor/config/environments/production.rb
        fi
        
        touch /home/mor/log/production.log /home/mor/log/development.log /tmp/mor_debug.log  /tmp/new_log.txt /tmp/mor_debug.log /tmp/mor_crash.log
        chmod -R 777 /home/mor/log /tmp/mor_debug.log /tmp/mor_crash.log
        chown -R apache: /home/mor /tmp/mor_debug.log  /tmp/new_log.txt

    elif [ "$TEST_MOR_VERSION" == "tickets" ]; then
        if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] prepare_gui: entered tickets section"; fi
        if [ -d /home/tickets ]; then
            if [ "$TEST_REVISION" != `svn info /home/tickets | grep 'Last Changed Rev' | awk '{print $NF}'` ]; then
                if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Deleting possible modifications and updating from SVN"; fi
                svn status /home/tickets | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/tickets" | xargs rm -rf
                svn update -r $TEST_REVISION /home/tickets
                GUI_WAS_UPDATED="TRUE"
            else
                if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] /home/tickets current version matches the newest one: $TEST_REVISION. Updating missing files if any"; fi
                svn_update_if_files_are_missing "/home/tickets"
            fi
        else
            get_gui_from_pool
            GUI_WAS_UPDATED="TRUE"
        fi

        searchd_running
        change_ruby_version "1.9.2-p318"

        cp -n /home/tickets/selenium/files/environment.rb /home/tickets/config/environment.rb
        crm_conf
        check_if_rebundle_is_needed "/home/tickets"
        #stop_delayed_jobs
        #/home/tickets/delay_job_restart.sh & &>/dev/null
        DELAYED_JOBS_ID="$!"
        change_crm_ip_if_does_not_match # fixes CRM WEB_URL
        change_crm_web_dir_does_not_match
        rm -rf /home/tickets/public/attachments/*
        chmod 777 /home/tickets/public/attachments
        
        #sudo config for sphinx 
        cp -fr "/usr/src/mor/test/node2/sudo_for_sphinx_script" "/etc/sudoers.d/sudo_for_sphinx_script"

    fi

    if [ -d /home/mor/tmp ]; then
        chmod -R 777 /home/mor/tmp    
    fi
    killall -9 ruby &> /dev/null
    killall -9 httpd &> /dev/null
    /etc/init.d/httpd start

}
initialize_gui_quick()
{
    #initialize quickly
    if [ "$TEST_MOR_VERSION" != "tickets" ]; then
        curl http://127.0.0.1/billing/callc/login &> /dev/null
    else
        curl http://127.0.0.1/tickets/callc/login &> /dev/null
    fi
}

check_if_gui_accessible()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012-2013
    # About:    This function checks if MOR / CRM GUI is available.
    #
    # Arguments:
    #   See variables below


    
    local seconds_to_wait="$1"
    local times_to_test="$2"
    local exit_if_will_fail="$3"
    
    
    if [ "$GUI_WAS_UPDATED" == "FALSE" ]; then
        return 0
    fi
    
    report "Checking if GUI is acccessible. Don't wait - go to your GUI." 3
    
    local GUI_WAS_SUCCESSFULLY_OPENED="FALSE"
    
    apache_is_running
    if [ "$APACHE_IS_RUNNING" != "0" ]; then # restart Apache if not running
        report "Apache is not running" 3
        service httpd restart
    fi
    
    for NR in seq 1 times_to_test; do
        if [ "$TEST_MOR_VERSION" != "tickets" ]; then   #MOR
            if [ `curl http://127.0.0.1/billing/callc/login 2> /dev/null | grep "login_username" | wc -l` != "2" ]; then
                    if [ `curl http://127.0.0.1/billing/callc/login 2> /dev/null | grep "login_username" | wc -l` == "2" ]; then
                        GUI_WAS_SUCCESSFULLY_OPENED="TRUE"
                        break # Success
                    elif [ "$exit_if_will_fail" != "EXIT" ]; then
                        sleep $seconds_to_wait
                        continue    # Failure
                    fi
            fi
        else
            if [ `curl http://127.0.0.1/tickets/callc/login  2> /dev/null | grep "login_username" | wc -l` == "1" ]; then
                GUI_WAS_SUCCESSFULLY_OPENED="TRUE"
                break # Success
            elif [ "$exit_if_will_fail" != "EXIT" ]; then
                report "GUI is still not accessible, will wait: $seconds_to_wait seconds before retry" 3
                sleep $seconds_to_wait
                continue    # Failure
            fi
        fi
        
    done
    
    if [ "$GUI_WAS_SUCCESSFULLY_OPENED" == "TRUE" ]; then
        report "GUI OK" 0
        return 0
    else
        report "GUI does not open after $times_to_test retries" 1
        echo "GUI not ready! Login page does not open. FIX manually"  >> /var/log/mor/n
        if [ "$exit_if_will_fail" == "EXIT" ]; then
            exit 1
        else
            return 1
        fi
    fi
}

upgrade_mor_install_scripts()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function updates install script from the repository

    if [ ! -d /usr/src/mor ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Checking out /usr/src/mor"
        if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] MOR version matched. Checking if revisions matches also"; fi
        svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor &> /dev/null
    else
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating /usr/src/mor"
        if [ "$N_DEBUG" != "1" ]; then
            svn status /usr/src/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/usr/src/mor" | xargs rm -rf
        fi
        n_update_source &> /dev/null
    fi

    if [ -d /usr/src/mor/test/node ]; then
        chmod +x /usr/src/mor/test/node/node.sh /usr/src/mor/test/node/node_functions.sh

        if [ ! -s /bin/n ]; then                                # for mor testing
                ln -s /usr/src/mor/test/node/node.sh /bin/n
        fi
        if [ ! -s /bin/c ]; then                                # for crm testing
                ln -s /usr/src/mor/test/node/node.sh /bin/c
        fi
    fi
}
crm_exists()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function checks if a crm already exists in /home/tickets
    #
    #   Returns:
    #       0   -   OK, /home/tickets exists
    #       1   -   Failed, /home/tickets does not exist

    if [ -f  /home/tickets/config/database.yml   ]; then
        return 0
    else
        return 1
    fi
}

#-------------------------------------------------------------
crm_gui_current_version()
{
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This functions retrieves current CRM GUI version in system

#   Arguments
#       None
#   Returns:
#       Makes available global variable $CRM_VERSION_YOU_ARE_TESTING which holds CRM version currently installed in the system

    crm_exists

    if [ ! -f  /usr/bin/svn ]; then
        yum -y install subversion
        if [ ! -f  /usr/bin/svn ]; then
            report "Failed to find/install subversion" 1  | tee -a /var/log/mor/test_system
            exit 1
        fi
    fi

    CRM_VERSION_YOU_ARE_TESTING=`cat /home/tickets/.svn/entries | grep http | awk -F"/" '{
      if($6 == "ror3")
        print $6;
      else if($5 == "trunk")
        print $5;
      else
        print $7;
    }' | sed '/^$/d'`
}
#-------------------------------------------------------------
install_gems()
{
    source "/usr/local/rvm/scripts/rvm"
    # ruby 1.8.6

        change_ruby_version "1.8.7"
        mkdir -p /usr/src/node/gems
        cd /usr/src/node/gems
        wget -c http://www.kolmisoft.com/packets/gems/1.8.6.tar.gz
        tar xzvf 1.8.6.tar.gz
        cd 1.8.6
        gem install hoe -v=2.3.3 --no-rdoc --no-ri
        gem install actionmailer -v=1.3.6 --no-rdoc --no-ri
        gem install actionpack -v=1.13.6 --no-rdoc --no-ri
        gem install actionwebservice -v=1.2.6 --no-rdoc --no-ri
        gem install activerecord -v=1.15.6 --no-rdoc --no-ri
        gem install activesupport -v=1.4.4 --no-rdoc --no-ri
        gem install archive-tar-minitar -v=0.5.2 --no-rdoc --no-ri
        gem install builder -v=2.1.2 --no-rdoc --no-ri
        gem install color -v=1.4.0 --no-rdoc --no-ri
        gem install fcgi -v=0.8.7 --no-rdoc --no-ri
        gem install ferret -v=0.11.6 --no-rdoc --no-ri
        gem install hoe -v=2.3.3 --no-rdoc --no-ri
        gem install mime-types -v=1.16 --no-rdoc --no-ri
        gem install mysql -v=2.7 --no-rdoc --no-ri
        gem install pdf-wrapper -v=0.1.0 --no-rdoc --no-ri
        gem install pdf-writer -v=1.1.8 --no-rdoc --no-ri
        gem install rails -v=1.2.6 --no-rdoc --no-ri
        gem install rake -v=0.8.7 --no-rdoc --no-ri
        gem install rest-client -v=1.6.1 --no-rdoc --no-ri
        gem install rubyforge -v=1.0.4 --no-rdoc --no-ri
        gem install Selenium -v=1.1.14 --no-rdoc --no-ri
        gem install sources -v=0.0.1 --no-rdoc --no-ri
        gem install transaction-simple -v=1.4.0 --no-rdoc --no-ri
        gem install passenger --no-rdoc --no-ri
        gem install mysql -- --with-mysql-config=/usr/bin/mysql_config -v 2.8.1 --no-rdoc --no-ri
        gem install passenger -v 3.0.15 --no-rdoc --no-ri

        passenger-install-apache2-module -a
        
        
    # ruby 1.9.3
        passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
        gem install rest-client --no-rdoc --no-ri
        gem install bundle --no-rdoc --no-ri

    # ruby 1.9.2-p318
        rvm install ruby-1.9.2-p318
        passenger-install-apache2-module -a
        gem install rest-client
}
prepare_new_node()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011-2012
    #   About:  This function prepares new node as a testing machine
    
    service iptables stop
    chkconfig --levels 2345 iptables off
    
    service ip6tables stop
    chkconfig --levels 2345 ip6tables off
    
    
    yum -y update
    yum -y groupinstall "X Window System" "Desktop" 
    yum -y install xorg-x11-fonts-misc xorg-x11-fonts-Type1
    
    yum -y install vim-enhanced vim-common firefox vixie-cron screen gcc make mysql-server mysql git subversion httpd curl-devel libxml2 libxml2-devel libxslt libxslt-devel openssl openssl-devel glib2 glib2-devel libtool


    /usr/src/mor/sh_scripts/nodejs.sh
    

    echo "*/5 * * * * root wget -o /dev/null -O /dev/null http://brain.kolmisoft.com/api/node_ping" > /etc/cron.d/brain

    install_ruby_versions
    #gem install actionmailer actionpack actionwebservice activerecord activesupport archive-tar-minitar builder color  fcgi  git hoe json_pure mime-types mysql pdf-wrapper pdf-writer rails rake rest-client rubyforge Selenium selenium-client transaction-simple

    #copy "test_environment" to /usr/local/mor/
    #install selenium gem!!!
    
    unlink /bin/n &> /dev/null
    unlink /bin/c &> /dev/null
    
    
    
    ln -s /usr/src/mor/test/node2/node.sh /bin/n
    ln -s /usr/src/mor/test/node2/node.sh /bin/c
    ln -s /home/tickets/public /var/www/html/tickets &> /dev/null
    ln -s /home/mor/public /var/www/html/billing &> /dev/null
    #----creating crontab
    #echo -e "*/1 * * * * root /bin/mor >> /var/log/mor/test_system\n0 * * * * root /usr/sbin/ntpdate pool.ntp.org >> /var/log/ntpdate.log\n" > /etc/cron.d/test_system

    mkdir -p /home/gui_pool
    
    
    
    #====================== X5 ==============================
    rvm install ruby-2.0.0-p247
    rvm use ruby-2.0.0-p247
    rvm gemset create x5
    rvm use ruby-2.0.0-p247@x5
    


    download_gui_from_brain "x5"
    cd /home/gui_pool/x5
    bundle
    
    #====================== X4 ==============================
    rvm install ruby-1.9.3-p327
    rvm use ruby-1.9.3-p327
    rvm gemset create x4
    rvm use ruby-1.9.3-p327@x4
    
    download_gui_from_brain "x4"
    cd /home/gui_pool/x4
    bundle
    
    
    /usr/src/mor/upgrade/x4/passenger.sh
    

    

    # CRM
    
    svn co http://svn.kolmisoft.com/mor/install_script/trunk /usr/src/mor
    
    cp /usr/src/mor/scripts/sendEmail /usr/local/mor/sendEmail
    
    /usr/src/mor/upgrade/x4/rvm.sh
    
    bash
    
    rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm
    
    rvm install ruby-1.9.2-p318
    
    rvm gemset create crm2
    
    rvm use ruby-1.9.2-p318@crm2
    
    rvm alias create default ruby-1.9.2-p318@crm2
    
    gem install bundle --no-ri --no-rdoc
     
    gem install passenger -v=3.0.19 --no-ri --no-rdoc
    passenger-install-apache2-module -a

    
    
    svn co http://svn.kolmisoft.com/crm/branches/ror3 /home/tickets
    
    
    mysql -e "CREATE DATABASE crm";


    
    touch /tmp/mor_crash.txt
    chmod 777 /tmp /tmp/mor_crash.txt
    ln -s /var/log/httpd/error_log /var/www/html/error_log &> /dev/null
    ln -s /var/log/httpd/access_log /var/www/html/access_log &> /dev/null
    ln -s /tmp/mor_debug.txt /var/www/html/mor_debug.txt &> /dev/null
    gem install ferret
    chmod 777 /var/www/html/access_log /var/www/html/error_log /var/www/html/mor_debug.txt

    # disable not needed services

    #-----------------------------------
    # Manualy configure /etc/fstab: / ext4 defaults,data=writeback,noatime,nodiratime 1 1   # this disables ext4 journal
    rm -rf /etc/cron.d/mor_ad   /etc/cron.d/mor_daily_actions  /etc/cron.d/mor_hourly_actions  /etc/cron.d/mor_logrotate  /etc/cron.d/mor_minute_actions  /etc/cron.d/mor_monthly_actions
    
    
    
    rm -rf /home/mor /home/gui_pool/* /dev/shm/pool
}


check_if_variable_is_int()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    This function checks if given variable is integer
    #
    # Returns:
    #   IS_INTEGER {"TRUE", "FALSE"}
    #   0 - it is integer
    #   1 - it is not an integer
    # Arguments:
    #   $1  - variable to check

    VARIABLE="$1"

    if [ "$VARIABLE" -eq "$VARIABLE" ] 2>/dev/null; then
      IS_INTEGER="TRUE"
      return 0
    else
        IS_INTEGER="FALSE"
      return 1
    fi

}