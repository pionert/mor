#! /bin/bash
#===== README ====
# MOR installation must be upgraded to the most recent version
# This script upgrades mor GUI only with a command specified by GUI_UPGRADE_CMD  variable
# selenium-server must be running
# start selenium server with command:
# 		./mor_test_run.sh -s
#
#==============
export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"


. /usr/local/mor/test_environment/mor_test.cfg

. /usr/src/mor/test/framework/bash_functions.sh

e
if [ "$MODE" == "0" ]; then
	E_MAIL_RECIPIENTS="$TESTER_EMAIL" #separate each address with a space
elif [ "$MODE" == "1" ]; then
	E_MAIL_RECIPIENTS="serveriu.pranesimai@gmail.com aisteaisteb@gmail.com tankiaitaskuota@gmail.com kristinak.kolmisoft@gmail.com" #separate each address with a space
#	E_MAIL_RECIPIENTS="mkezys@gmail.com" #separate each address with a space
else
	echo "Unknown error when selecting MODE"
fi


#=======OPTIONS========
: ${dbg:="1"}	# dbg= {0 - off, 1 - on }  for debuging purposes
#============FUNCTIONS====================
job_ask()
{
#   Author: Mindaugas Mardosas
#   Year:  2011
#   About: This function gets a job from brain.
	local DEBUG="0"
    local PRODUCT="$1"
    local VERSION="$2"
    local REVISION="$3"
    default_interface_ip #getting IP and mac address
    # --- pvz ----
    #  http://brain2/api/request_job?version=trunk&revision=20077&product=mor&mac=00:0c:9f:f0:01&ip=192.168.0.55

	local work=`/bin/mktemp`
    curl "http://$BRAIN/api/request_job?version=$VERSION&revision=$REVISION&product=$PRODUCT&mac=$DEFAULT_INTERFACE_MAC&ip=$DEFAULT_IP" > $work

    BEGIN_TEST=`cat $work | awk -F"," '{print $1}'`
    TEST_PRODUCT=`cat $work | awk -F","  '{print $2}'`
    TEST_VERSION=`cat $work | awk -F"," '{print $3}'`
    TEST_REVISION=`cat $work | awk -F"," '{print $4}'`
    PATH_TO_TEST=`cat $work | awk -F","  '{print $5}'`
    PATH_TO_TEST=`echo $PATH_TO_TEST | awk -F"." '{print $1}'`
	if [ "$DEBUG" == "1" ]; then
	       echo "BEGIN_TEST: $BEGIN_TEST"
	   	   echo "TEST_PRODUCT: $TEST_PRODUCT"
           echo "TEST_VERSION: $TEST_VERSION"
           echo "TEST_REVISION: $TEST_REVISION"
           echo "PATH_TO_TEST: $PATH_TO_TEST"
	fi

    rm -rf $work

    if [ "$BEGIN_TEST" != "1" ]; then
        rm -rf $TEST_RUNNING_LOCK
        exit 0
    fi
}

start_selenium_server()
{
    running=`ps aux | grep -m 1 selenium-server.jar | awk '{ print $NF}'`
    if [ "$running" == "-singleWindow" ]; then
        echo "Selenium server is already running";
    else
        echo "Starting selenium server"
        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -singleWindow >> /var/log/mor/selenium_server.log &
    fi
}
start_selenium_server
clean_logs()
{
    rm -rf /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
    chmod 777 /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
}

restart_services()
{
    #selenium   
    killall -9 java
    start_selenium_server;
    #-------
}
gem_rest_client_check_and_install()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func installs rest-client gem if it is not present
    gem list | grep rest &> /dev/null
    if [ "$?" != "0" ]; then
        gem install rest-client
        if [ "$?" != "0" ]; then
            echo "FAILED TO INSTALL GEM: rest-client";
            exit 1;
        fi
    fi
}
#------------------------------------------
prepare_db(){

	# recreate ramdisk
	cd /usr/local/mor
	./rebuild_mysql_ram.sh > /var/log/mor/rebuild_mysql_ram.log 2>&1

	cd /usr/src/mor/db/0.8/
	./make_new_db.sh nobk
	mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;

    cd /usr/src/mor/db/9/
    ./import_changes.sh


    cd /usr/src/mor/db/10/
    ./import_changes.sh

    if [ "$TEST_VERSION" == "trunk" ] || [ "$TEST_VERSION" == "11" ]; then
		cd /usr/src/mor/db/trunk/
		./import_changes.sh

		mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
    fi


	echo "Exporting prepared db to ramdisk"
	mysqldump -h localhost -u mor -pmor mor > /home/ramdisk/mor.sql

}


#------------------------------------------
import_db(){
	echo "Importing test mor database from /home/ramdisk/mor.sql";
	mysql mor < /home/ramdisk/mor.sql
}

#-------------------------------------------
_mor_time()
{
	mor_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
}
#--------------------------------------------
#====================================================================
is_another_test_still_running()
{
	if [ -f "$TEST_RUNNING_LOCK" ]; then
		echo "$mor_time Another test is already running, exiting";
		exit 0;
	fi
}

cleanup_before_test()
{
	free -m
	killall -9 dispatch.fcgi
	free -m
    #------------
    find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf
    rm -rf /tmp/failed_conversions /home/mor/public/ad_sounds/*.wav
}

run_test()
{
    local testas="$1"
	TMP_FILE=`mktemp`
	ruby -rubygems $testas  | tee -a $report $TMP_FILE #logging the report to file   #| egrep "failures|Loaded"

    grep "Error:\|Failure:" $TMP_FILE &> /dev/null
    if [ "$?" == "0" ]; then
        STATUS_v2="FAILED";
    else
        STATUS_v2="OK";
    fi

    if [ -f /usr/src/brain-scripts/reporter.rb ]; then
        RELATVE_PATH_TO_TEST=`echo $testas | sed 's/\/home\/mor\/selenium\/tests\///'`
        local counter=0;
	echo "Reporting to BRAIN..."
        while [ "$counter" != "5" ]; do
            counter=$(($counter+1))
            local temp=`mktemp`
            echo "ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2" >> /tmp/reporter.log

            if [ "$STATUS_v2" == "OK" ]; then
                local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log` 
            else
                local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $TEST_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
            fi
            grep "RECEIVED" $temp &> /dev/null
            if [ "$?" == "0" ]; then
                rm -rf $temp $TMP_FILE
                echo "Reporting complete!"
                break;
            fi
            rm -rf $temp
            echo "Still reporting..."
            sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
        done
    else
        echo "The reporter script was not found"
    fi
    rm -rf $TMP_FILE
	echo -e "\n----\n" >> $report;
    clean_logs   
}

#====================================MAIN============================
_mor_time;

if [ -z "$1" ]; then
	echo -e "\n\n=========MOR TEST ENGINE CONTROLLER=======";
	echo "Arguments:";
	echo -e "\t-a \tUpgrades GUI, resets a database, runs all tests, sends the report by email.";
	echo -e "\t-i \tGives you a fresh database, by importing $PATH_TO_DATABASE_SQL";
	echo -e "\t-d \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS";
	echo -e "\t-r \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS and replaces the default database file $PATH_TO_DATABASE_SQL \n";
	echo -e "\t-s \tStart a Selenium RC server\n";
elif [ "$1" == "-a" ]; then  #do all tasks
        

	is_another_test_still_running #if another instance is running - script will terminate.
	touch "$TEST_RUNNING_LOCK"  #creating the lock
	svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
	rm -rf /tmp/mor_crash.log
	echo -e "\n------\n" >> /var/log/mor/selenium_server.log
	touch /tmp/mor_crash.log
	chmod 777 /tmp/mor_crash.log /usr/bin/mor

    #== House cleaning before tests
    # turn off swap
    sysctl -w vm.swappiness=0
    echo 0 >/proc/sys/vm/swappiness
    # kill some nonsense
    killall -9 wnck-applet
    # clean mem cache
    sync; echo 3 > /proc/sys/vm/drop_caches
    #===========

    BEGIN_TEST="1"; 
    LAST_REVISION="0"   #later_remove this
	report="$DIR_FOR_LOG_FILES/$LOGFILE_NAME.$mor_time.txt"
    DEFAULT_IP=`grep Web_URL /home/mor/config/environment.rb | awk -F"/|\"" '{print $4}'`       # taking this from environment.rb. Make sure the IP is correct there
    echo "DEFAULT_IP:$DEFAULT_IP"
    while [ "$BEGIN_TEST" == "1" ]; do 
        mor_gui_current_version
        gui_revision_check
        job_ask "mor" "$MOR_VERSION_YOU_ARE_TESTING" "$GUI_REVISION_IN_SYSTEM"   # BEGIN_TEST gets updated here to 0 when there will be no work
        if [ "$LAST_REVISION" != "$TEST_REVISION" ]; then
            svn update -r $TEST_REVISION /home/mor
            /etc/init.d/httpd restart
            prepare_db
            # initiate apache/compile ror
            wget http://127.0.0.1/billing/callc/login &> /dev/null & # we do not wait till this operation finishes
        else
            import_db   # savings for the first time when revision changes - after dump we don't need to import again    
        fi 
        
        rm -rf /home/mor/selenium/tests/$PATH_TO_TEST.rb
        ruby /home/mor/selenium/converter/converter.rb -h "http://$DEFAULT_IP" /home/mor/selenium/tests/$PATH_TO_TEST.case &> /tmp/test_convert_error 
        cleanup_before_test
        run_test /home/mor/selenium/tests/$PATH_TO_TEST.rb
    done
	rm -rf "$TEST_RUNNING_LOCK";

elif [ "$1" == "-s" ]; then # Starting a Selenium RC server
	start_selenium_server;
fi

