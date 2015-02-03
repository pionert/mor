#! /bin/sh

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
    echo -e "\n============RAM===================\n\n" >> $TMP_FILE
    free -m >> $TMP_FILE
    echo -e "\n\n============Full System Process List===================\n\n" >> $TMP_FILE
    ps aux >> $TMP_FILE
    echo -e "\n\n============MySQL Process List===================\n\n" >> $TMP_FILE
    mysql mor -e "show processlist" 2>&1>> $TMP_FILE
}
#--------RVM
rvm_is_installed() 
{
    #   Author: Mindaugas Mardosas
    #   Year:  2011
    #   About:  This function checks if rvm (ruby version manager) is installed in the system.
    #    
    #   Returns:
    #       0   -   OK
    #       1   -   FAILED

    rvm list &> /dev/null
    if [ "$?" == "0" ]; then
        return 0;
    else
        return 1;
    fi
}

install_rvm()
{   
    # Author: Mindaugas Mardosas
    # Year:  2011
    #   About:  This function checks if rvm (ruby version manager) is installed in the system.
    #    
    #   Returns:
    #       0   -   OK
    #       1   -   FAILED 

    #==== yum bug
    yum clean metadata
    yum clean all
    #===============    
    yum -y install  wget curl make git bzip2 gcc openssl openssl-devel zlib zlib-devel sudo


    #   ----------Autoconf install-----------
    cd /usr/src/ 
    wget -c http://ftp.gnu.org/gnu/autoconf/autoconf-2.63.tar.gz
    tar xvzf autoconf-2.63.tar.gz
    cd autoconf-2.63
    ./configure --prefix=/usr
    make
    make install
    cd ..
    #== rvm
    #bash < <(curl -sk https://rvm.beginrescueend.com/install/rvm)
    echo "source /usr/local/rvm/scripts/rvm" >> /etc/profile    #adding to profile, so that rvm would be loaded every time a shell session is started
}
install_ruby_1_9_2()  #=== ruby 1.9.2
{
    # Author: Mindaugas Mardosas
    # Year:  2011 

    source "/usr/local/rvm/scripts/rvm"
    rvm install ruby-1.8.5
    rvm install 1.8.7       #nasty hack, without this ruby 1.9.2 won't install correctly
    rvm install 1.9.2 -C --with-openssl-dir=/usr/local --with-zlib-dir=$HOME/.rvm/usr --with-readline-dir=$HOME/.rvm/usr
}
check_if_xvfb_is_running()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function ensures, that Xvfb frame buffer is started
    
    DEBUG=0; 
    
    local xvfb_processes=`ps aux | grep Xvfb | wc -l` # OK - 2 processes, 1 for Xvfb, 1 for grep :)
    if [ "$xvfb_processes" != "2" ]; then
        Xvfb :0 -ac -screen 0 1024x768x16  &> /dev/null &
        report "Xvfb was not running, fixed" 4
    elif [ "$DEBUG" == "1" ]; then
        report "Xvfb frame buffer is running" 0
    fi
}

actions_before_new_test()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This is a place for all house cleaning actions before new test

    #== House cleaning before tests
    killall -9 dispatch.fcgi    # removing all dispatch processes. As they are hanging up and consuming RAM
    sysctl -w vm.swappiness=0  &> /dev/null # turn off swap
    echo 0 >/proc/sys/vm/swappiness  &> /dev/null 
    sync; echo 3 > /proc/sys/vm/drop_caches &> /dev/null # clean mem cache
    #==
    check_if_xvfb_is_running
    
    #=======================LOGS==============================
    killall -9 httpd
    for i in `ipcs -s | awk '/apache/ {print $2}'`; do (ipcrm -s $i); done # clean apache semaphores: http://rackerhacker.com/2007/08/24/apache-no-space-left-on-device-couldnt-create-accept-lock/
    
    rm -rf /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log
    chmod 777 /var/log/httpd/access_log /var/log/httpd/error_log /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/mor/selenium_server.log
    service httpd restart
    #=====================================================
    gem_selenium_client
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
install_rails_3()
{
    gem install rails -v3.0.6
}
install_crm2()
{
    mv /home/tickets /home/tickets_OLD
    svn co http://svn.kolmisoft.com/crm/branches/ror3 /home/tickets
    rm -rf /home/tickets/selenium
    svn update /home/tickets
    chmod +x /home/tickets/selenium/scripts/tickets_test_run.sh
    cd /home/tickets
    bundle install
    /etc/init.d/httpd restart 
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

    SELENIUM_SERVER_LOG="/var/log/mor/selenium_server.log"
    running=`ps aux | grep -m 1 selenium-server.jar | awk '{ print $NF}' | head -n 1`
    if [ "$running" == "-singleWindow" ]; then
        return 0
    else
        echo "[`date +%0k\:%0M\:%0S`] Starting selenium server"
        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -singleWindow >> /var/log/mor/selenium_server.log &
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
    # Year: 2011
    # About: check if files are missing. If yes - checks them out from repo

    GUI_PATH="$1"
    if [ `svn status $GUI_PATH | grep ! | wc -l` != "0" ]; then
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
       if [ "$TEST_MOR_VERSION" == "crm" ]; then    #updating current version
            local DB_VERSION=`svn info /home/crm/selenium/sql | grep 'Last Changed Rev:' | awk '{print $4}'`
        else
            if [ "$TEST_MOR_VERSION" == "8" ]; then    # if we want specific version (mor -l 8)
                local DB_VERSION=`svn info /usr/src/mor/db/0.8 | grep 'Last Changed Rev:' | awk '{print $4}'`       #for historical numbering purposes
            elif [ "$TEST_MOR_VERSION" == "10" ] || [ "$TEST_MOR_VERSION" == "trunk" ]; then
                local DB_VERSION=`svn info /usr/src/mor/db/trunk | grep 'Last Changed Rev:' | awk '{print $4}'`
            else
                local DB_VERSION=`svn info /usr/src/mor/db/$TEST_MOR_VERSION | grep 'Last Changed Rev:' | awk '{print $4}'`
            fi
        fi

        if [ ! -f /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION ]; then
            rm -rf /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION;
        fi
    #-------- /Checking if DB revision is newest

    if [ ! -f /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/mor.sql ]; then
        if [ "$TEST_MOR_VERSION" == "crm" ]; then    #updating current version
            mysql crm -e "show tables" | grep -v Tables_in | grep -v "+" | gawk '{print "drop table " $1 ";"}' | mysql crm
            cd /home/crm/selenium/sql
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Importing fresh CRM DB"

            mysql crm < /home/crm/selenium/sql/struckt.sql
            mysql crm < /home/crm/selenium/sql/translations.sql
            mysql crm < /home/crm/selenium/sql/conflines.sql
            mysql crm < /home/crm/selenium/sql/emails.sql
            mysql crm < /home/crm/selenium/sql/hearfromusplaces.sql
            mysql crm < /home/crm/selenium/sql/directions.sql
            mysql crm < /home/crm/selenium/sql/roles.sql
            mysql crm < /home/crm/selenium/sql/role_rights.sql
            mysql crm < /home/crm/selenium/sql/permissions.sql
            mysql crm < /home/crm/selenium/sql/datas.sql
        else
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Creating fresh DB for $TEST_MOR_VERSION Revision: $TEST_REVISION"

            cd /usr/src/mor/db/0.8/
            ./make_new_db.sh nobk

            if [ "$TEST_MOR_VERSION" == "8" ]; then    # if we want specific version (mor -l 8)
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;

            elif [ "$TEST_MOR_VERSION" == "9" ]; then  # if we want specific version (mor -l 9)
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                /usr/src/mor/db/9/import_changes.sh
                mysql mor < /home/mor/selenium/mor_9_testdb.sql
            elif [ "$TEST_MOR_VERSION" == "10" ]; then
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                /usr/src/mor/db/9/import_changes.sh
                mysql mor < /home/mor/selenium/mor_9_testdb.sql
                /usr/src/mor/db/10/import_changes.sh
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
            elif [ "$TEST_MOR_VERSION" == "11" ] || [ "$TEST_MOR_VERSION" == "trunk" ]; then
                mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
                /usr/src/mor/db/9/import_changes.sh
                /usr/src/mor/db/10/import_changes.sh
                /usr/src/mor/db/trunk/import_changes.sh
                mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
            fi
        fi
                    #/usr/local/mor/rebuild_mysql_ram.sh > /var/log/mor/rebuild_mysql_ram.log 2>&1      	# recreate ramdisk, later...
                    #mkdir -p /home/ramdisk
                    #echo "Exporting prepared db to ramdisk"
                    #mysqldump -h localhost -u mor -pmor mor > /home/ramdisk/mor.sql

        mkdir -p /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION

        rotate_files_dirs /var/lib/mysql_pool/"$TEST_MOR_VERSION" "$dbVersionsToKeep" on      #   rotating

        echo "[`date +%0k\:%0M\:%0S`] Exporting DB to /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION";

        if [ "$TEST_MOR_VERSION" == "crm" ]; then    #updating current version
            mysqldump crm > /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/mor.sql

        else
            mysqldump -h localhost -u mor -pmor mor > /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/mor.sql
        fi

        #--Marking which DB version according to svn we have
        touch /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/$DB_VERSION

    else    #we already have such db of such revision
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Importing DB from /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/mor.sql"
        mysql -h localhost -u mor -pmor mor < /var/lib/mysql_pool/$TEST_MOR_VERSION/$TEST_REVISION/mor.sql
    fi
}
convert_and_run_rb()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function converts and runs a single test case
    TMP_FILE=`mktemp`
    echo -e "\n\n============RAM Before Test===================\n\n" >> $TMP_FILE
    free -m >> $TMP_FILE
    echo -e "\n\n============/RAM Before Test===================\n\n" >> $TMP_FILE
    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Converting /home/mor/selenium/tests/$TEST_TEST.case"
    ruby /home/mor/selenium/converter/converter.rb -h "http://$DEFAULT_IP" "/home/mor/selenium/tests/$TEST_TEST.case" 2>&1>> $TMP_FILE
    if [ "$?" != "0" ]; then
        job_report "$?"
    else    
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Running /home/mor/selenium/tests/$TEST_TEST.rb"
        ruby -rubygems "/home/mor/selenium/tests/$TEST_TEST.rb" &> $TMP_FILE
        job_report "$?"
    fi
    rm -rf $TMP_FILE
    
}
is_another_test_still_running()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if the script is already running

	if [ -f "$TEST_RUNNING_LOCK" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Found a lock and it seems that no tests are running. Lock can be removed by: rm -rf $TEST_RUNNING_LOCK";
	    exit 0;
	fi
}
#----------- Job_ask ---------

job_ask()
{
#   Author: Mindaugas Mardosas
#   Year:  2011
#   About: This function gets a job from brain.

    set +x 
	local DEBUG="1"
    local PRODUCT="$1"
    local VERSION="$2"
    local REVISION="$3"

    actions_before_new_test             # house cleaning, etc.

    default_interface_ip #getting IP and mac address
    # --- pvz ----
    #  http://brain2/api/request_job?version=trunk&revision=20077&product=mor&mac=00:0c:9f:f0:01&ip=192.168.0.55

	local work=`/bin/mktemp`
    #curl "http://$BRAIN/api/request_job?version=$VERSION&revision=$REVISION&product=$PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work

    if [ "$TEST_PRODUCT" != "" ] && [ "$TEST_MOR_VERSION" != "" ] && [ "$TEST_REVISION" != "" ]; then
        if [ "$DEBUG" == "1" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. curl http://$BRAIN/api/request_job?version=$TEST_MOR_VERSION&revision=$TEST_REVISION&product=$TEST_PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"
        fi
        curl "http://$BRAIN/api/request_job?version=$TEST_MOR_VERSION&revision=$TEST_REVISION&product=$TEST_PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work
        #wget -O $work "http://$BRAIN/api/request_job?version=$TEST_MOR_VERSION&revision=$TEST_REVISION&product=$TEST_PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"
    else
        if [ "$DEBUG" == "1" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. curl http://$BRAIN/api/request_job?mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"
        fi
        curl "http://$BRAIN/api/request_job?mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work  
        #wget -O $work "http://$BRAIN/api/request_job?mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP"  
    fi

    BEGIN_TEST=`cat $work | awk -F"," '{print $1}'`
    TEST_PRODUCT=`cat $work | awk -F","  '{print $2}'`
    TEST_MOR_VERSION=`cat $work | awk -F"," '{print $3}'`
    TEST_REVISION=`cat $work | awk -F"," '{print $4}'`
    TEST_TEST=`cat $work | awk -F","  '{print $5}'`
    TEST_TEST=`echo $TEST_TEST | awk -F"." '{print $1}'`
	if [ "$DEBUG" == "1" ]; then
	       echo "BEGIN_TEST: $BEGIN_TEST"
	   	   echo "TEST_PRODUCT: $TEST_PRODUCT"
           echo "TEST_MOR_VERSION: $TEST_MOR_VERSION"
           echo "TEST_REVISION: $TEST_REVISION"
           echo "TEST_TEST: $TEST_TEST"
	fi

    rm -rf $work
    if [ "$BEGIN_TEST" != "1" ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. No Jobs" | tee -a /var/log/mor/test_system
        rm -rf "$TEST_RUNNING_LOCK";
        rm -rf /usr/local/mor/backups/GUI/* &
        exit 0
    fi
}


job_report()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function reports test results after each test

    local STATUS="$?"
    _mor_time
    if [ ! -f /usr/src/brain-scripts/reporter.rb ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. /usr/src/brain-scripts/reporter.rb not found" | tee -a /var/log/mor/test_system
        rm -rf "$TEST_RUNNING_LOCK";
        exit 1;
    fi

    grep "Error:\|Failure:" $TMP_FILE  &> /dev/null
    if [ "$?" == "0" ] || [ "$STATUS" != "0" ]; then
        STATUS_v2="FAILED";
    else
        STATUS_v2="OK";
    fi

    if [ -f /usr/src/brain-scripts/reporter.rb ]; then
	echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Reporting to BRAIN..."
        RELATVE_PATH_TO_TEST=`echo $TEST_TEST | sed 's/\/home\/mor\/selenium\/tests\///'`
        local counter=0;
        while [ "$counter" != "5" ]; do
            counter=$(($counter+1))
            local temp=`mktemp`


            if [ "$STATUS_v2" == "OK" ]; then
                local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log` 
                echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"test_log $TMP_FILE\""
            else
                gather_log_about_machine_state_after_failed_test  # the test failed, gathering additional logs
                local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"my_debug /tmp/mor_debug.txt\" \"crash_log /tmp/mor_crash.log\" \"production_log /home/mor/log/production.log\" \"access_log /var/log/httpd/access_log\" \"error_log  /var/log/httpd/error_log\" \"selenium_server_log /var/log/mor/selenium_server.log\" \"test_log $TMP_FILE\""
            fi
            grep "RECEIVED" $temp &> /dev/null
            if [ "$?" == "0" ]; then
                rm -rf /tmp/reporter.log $temp
                echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Reporting complete!"
                break;
            fi
            rm -rf /tmp/reporter.log $temp
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Still reporting..."
            sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
        done
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


    if [ "$TEST_MOR_VERSION" != "crm" ]; then
        mor_gui_current_version
        _mor_time
        if [ -d /home/mor ]; then
            mkdir -p /home/gui_pool

            if [ -d /home/mor ]; then #moving if directory exists
                mv /home/mor /home/gui_pool/$MOR_VERSION_YOU_ARE_TESTING
                echo "$mor_time Moved /home/mor to /home/gui_pool/$MOR_VERSION_YOU_ARE_TESTING"
            fi
        else
            echo "$mor_time Failed to move /home/mor - /home/mor does not exist!"
        fi
    fi
}
get_gui_from_pool()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function gets required MOR/CRM GUI from available gui pool

    mkdir -p /home/gui_pool

    if [ "$TEST_MOR_VERSION" != "crm" ]; then
        if [ -d "/home/gui_pool/$TEST_MOR_VERSION" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Moving /home/gui_pool/$TEST_MOR_VERSION /home/mor"
            mv /home/gui_pool/$TEST_MOR_VERSION /home/mor     #this operation is very guick because it just physically rewrites the address of a directory!
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating $TEST_MOR_VERSION from svn to revision: $TEST_REVISION"
            svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
            svn status /home/mor | grep -v "public\|lang\|config\|gui_upgrade\|TRANS.TBL" | xargs rm -rf

            svn update -r $TEST_REVISION /home/mor &> /dev/null

            #post_MOR gui_update:
            mkdir -p /home/mor/public/ad_sounds
            ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad &> /dev/null
            chmod -R 777 /home/mor/public/images/logo /home/mor/public/images/cards /home/mor/public/ad_sounds &> /dev/null
        else
            #Download MOR GUI and copy configs
            _mor_time
            echo "$mor_time: /home/gui_pool/$TEST_MOR_VERSION is not available, downloading MOR GUI"
            #--------------
            mkdir -p /home/gui_pool
            cd /home/gui_pool
            wget -c http://192.168.0.13/files/gui/mor_$TEST_MOR_VERSION.tar.gz
            tar xzvf mor_$TEST_MOR_VERSION.tar.gz
            mv mor $TEST_MOR_VERSION
            if [ ! -d "$TEST_MOR_VERSION" ]; then
                echo "Failed to download and prepare MOR GUI, check get_gui_from_pool function!"
            else
                get_gui_from_pool   #running the function again
            fi
        fi
    else    # ==crm
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating /home/crm from svn to revision: $TEST_REVISION"
        if [ ! -d /home/crm ]; then
            mkdir -p /home/gui_pool
            cd /home/gui_pool
            wget -c http://192.168.0.13/files/gui/crm.tar.gz
            tar xzvf crm.tar.gz
            mv crm /home/crm
        else
            svn status /home/crm | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/crm" | xargs rm -rf
            svn update -r $TEST_REVISION /home/crm
        fi
    fi

    if [ "$TEST_MOR_VERSION" == "crm" ] && [ ! -d "/home/crm" ]; then   #"crm" is historical crm name
        _mor_time
        echo "[`date +%0k\:%0M\:%0S`] $mor_time: /home/crm is not available, fix this"
    fi
}
change_ip_if_does_not_match()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function changes IP in environment.rb if it does not match any ip from ifconfig output
    #
    default_interface_ip
    if [ `grep -F "$DEFAULT_IP" /home/mor/config/environment.rb | wc -l` != "2" ]; then
        replace_line /home/mor/config/environment.rb "Recordings_Folder" "Recordings_Folder = \"http://$DEFAULT_IP/billing/recordings/\"" 
        replace_line /home/mor/config/environment.rb "Web_URL" "Web_URL = \"http://$DEFAULT_IP\""
    fi
}
prepare_gui()
{
    #
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function prepares required MOR, crm GUI version AND revision for testing
    #
    #
    #   Other notes:
    #       This function depends on: /usr/src/mor/test/framework/bash_functions.sh functions:
    #           mor_gui_current_version
    #
    
    if [ "$TEST_MOR_VERSION" != "crm" ]; then
        rvm ruby-1.8.6
        mor_gui_current_version  &> /dev/null #getting current version of GUI, provides variable: MOR_VERSION_YOU_ARE_TESTING
        if [ "$MOR_VERSION_YOU_ARE_TESTING" != "$TEST_MOR_VERSION" ]; then
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Changing MOR version to $TEST_MOR_VERSION"
            move_current_gui_to_pool
            get_gui_from_pool
            change_email_in_environment_rb
            change_ip_if_does_not_match
            gui_revision_check 0
            if [ "$GUI_REVISION_IN_SYSTEM" != "$TEST_REVISION" ]; then
                svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
                svn update -r $TEST_REVISION /home/mor
            else
                svn_update_if_files_are_missing "/home/mor"
            fi

            #/etc/init.d/httpd restart  #if GUI version changes httpd restart is a MUST

            #============================================================
        else
            gui_revision_check 0
            if [ "$GUI_REVISION_IN_SYSTEM" != "$TEST_REVISION" ]; then
                svn status /home/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/mor" | xargs rm -rf
                svn update -r $TEST_REVISION /home/mor
            else
                svn_update_if_files_are_missing "/home/mor"
            fi
        fi
        # clean uploaded auto dialer files; Hardcoding for now. Please note that this value can also be set in environment.rb. Also please note that the path currently set there is just a symlink
        rm -rf /home/mor/public/ad_sounds/*.wav
        
        # cleaning test IVR files
        find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf

    elif [ "$TEST_MOR_VERSION" == "crm" ]; then
        if [ -d /home/crm ]; then
            gui_revision_check
            if [ "$MOR_VERSION_YOU_ARE_TESTING" != "$TEST_MOR_VERSION" ]; then
                svn status /home/crm | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/home/crm" | xargs rm -rf
                svn update -r $TEST_REVISION /home/crm
            else
                svn_update_if_files_are_missing "/home/crm"
            fi

            cd /home/crm
            ./start_ferret.sh
        else
            get_gui_from_pool
        fi
        #/etc/init.d/httpd restart
    fi

}
upgrade_mor_install_scripts()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function updates install script from the repository

    if [ ! -d /usr/src/mor ]; then
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Checking out /usr/src/mor"
        svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor &> /dev/null
    else
        echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Updating /usr/src/mor"
        svn status /usr/src/mor | sed 's/ //g' | awk -F"M" '{print $2}' | grep "/usr/src/mor" | xargs rm -rf
        svn update /usr/src/mor &> /dev/null
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
crm_gui_revision_check()
{
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This function checks if the system has the newest revision of CRM GUI
#
#   Arguments:
#       1   -   #{1 - on,0 - off} messages
#
#   Returns:
#       0   -   GUI is already the newest version
#       1   -   GUI needs to be upgraded

    MESSAGES="$1"

    DEBUG=0     # {1 - on, 0 - off}


    crm_gui_current_version #getting release version. Possible values are: 8,9, 10, trunk, etc...

    CRM_GUI_REVISION_IN_SYSTEM=`svn info /home/mor | sed -n '9p' | sed 's/ //g' | awk -F":" '{print $NF}'`

    if [ "$MOR_VERSION_YOU_ARE_TESTING" == "trunk" ]; then
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/mor/gui/trunk | sed -n '8p' | sed 's/ //g' | awk -F":" '{print $NF}'`
    elif [ "$MOR_VERSION_YOU_ARE_TESTING" == "crm" ]; then
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/crm/trunk | sed -n '8p' | sed 's/ //g' | awk -F":" '{print $NF}'`
    else
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/mor/gui/branches/$MOR_VERSION_YOU_ARE_TESTING | sed -n '8p' | sed 's/ //g' | awk -F":" '{print $NF}'`
    fi

    if [ "$CRM_GUI_REVISION_IN_SYSTEM" -lt "$GUI_REVISION_IN_REPOSITORY" ]; then
        if [ "$MESSAGES" == "1" ]; then
            report "There is a newer version GUI, please upgrade your GUI to the newest. Your GUI current revision is: $CRM_GUI_REVISION_IN_SYSTEM, Repository revision: $GUI_REVISION_IN_REPOSITORY" 1
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "[`date +%0k\:%0M\:%0S`] System GUI  revision: $CRM_GUI_REVISION_IN_SYSTEM\nLatest GUI revision version: $GUI_REVISION_IN_REPOSITORY";
        fi
        return 1;
    else
        if [ "$MESSAGES" == "1" ]; then
            report "[`date +%0k\:%0M\:%0S`] System already has the newest GUI version. Revision: $CRM_GUI_REVISION_IN_SYSTEM" 0
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "[`date +%0k\:%0M\:%0S`] System GUI  revision: $CRM_GUI_REVISION_IN_SYSTEM\nLatest GUI revision: $GUI_REVISION_IN_REPOSITORY";
        fi
        return 0;
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
    # ruby 1.8.6
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

    # ruby 1.9.3
    
    
}
prepare_new_node()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function prepares new node as a testing machine

    yum -y update
    yum -y groupinstall "X Window System" "GNOME Desktop Environment"
    yum -y install vim-enhanced vim-common firefox vixie-cron screen gcc make mysql-server mysql git subversion httpd curl-devel libxml2 libxml2-devel libxslt libxslt-devel openssl openssl-devel glib2 glib2-devel libtool

 
 
    #gem install actionmailer actionpack actionwebservice activerecord activesupport archive-tar-minitar builder color  fcgi  git hoe json_pure mime-types mysql pdf-wrapper pdf-writer rails rake rest-client rubyforge Selenium selenium-client transaction-simple 

    #copy "test_environment" to /usr/local/mor/
    #install selenium gem!!!
    ln -s /usr/src/mor/test/test_node/node.sh /bin/mor
    #----creating crontab
    #echo -e "*/1 * * * * root /bin/mor >> /var/log/mor/test_system\n0 * * * * root /usr/sbin/ntpdate pool.ntp.org >> /var/log/ntpdate.log\n" > /etc/cron.d/test_system

    #crm
    mysql -e "CREATE DATABASE crm";
    ln -s /home/crm /var/www/html/crm &> /dev/null
    ln -s /var/log/httpd/error_log /var/www/html/error_log &> /dev/null
    ln -s /var/log/httpd/access_log /var/www/html/access_log &> /dev/null
    ln -s /tmp/mor_debug.txt /var/www/html/mor_debug.txt &> /dev/null
    gem install ferret
    chmod 777 /var/www/html/access_log /var/www/html/error_log /var/www/html/mor_debug.txt

}



