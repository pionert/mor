#! /bin/bash
#===== README ====
# MOR installation must be upgraded to the most recent version
# This script upgrades mor GUI only with a command specified by GUI_UPGRADE_CMD  variable
# selenium-server must be running
# start selenium server with command:
# 		./mor_test_run.sh -s
#
#==============
#============SETTINGS========================
. /usr/src/mor/test/framework/bash_functions.sh

set +x

env >> /tmp/env

MODE=1; # 0 - mode for a local testing system (doesn't send email to all recipients, only the person who is testing, doesn't upgrade gui with tests). 1 - mode for a real test server

TESTER_EMAIL=""; #tests tester

MOR_VERSION_YOU_ARE_TESTING="TICKETS SYSTEM"
LOGFILE_NAME="mor_test_ataskaita";
DIR_FOR_LOG_FILES="/usr/local/mor/test_environment/reports"; #must end without slash ("/")
SEND_EMAIL="/usr/local/mor/sendEmail"
GUI_UPGRADE_CMD="/home/tickets/selenium/scripts/tickets_gui_upgrade_light.sh"
DIR_TO_STORE_DATABASE_DUMPS="/usr/local/mor/test_environment/dumps"
TEST_DIR="/home/tickets/selenium/tests"
LAST_REVISION_FILE="/usr/local/mor/test_environment/last_revision_tickets"; #here we will track completed tests
TEST_RUNNING_LOCK="/tmp/.mor_test_is_running";
MOR_CRASH_LOG="/tmp/crm_crash.log"
SELENIUM_SERVER_LOG="/var/log/mor/selenium_server.log"
EMAIL_SEND_OPTIONS="-o reply-to=mor_tests@kolmisoft.com tls=auto -s storm.kava.lt"
TESTS_STARTS_WITH="vsfupbwjkoxyz"


 mkdir -p /usr/local/mor/test_environment/reports/

if [ "$MODE" == "0" ]; then
	E_MAIL_RECIPIENTS="$TESTER_EMAIL" #separate each address with a space
elif [ "$MODE" == "1" ]; then
	E_MAIL_RECIPIENTS="serveriu.pranesimai@gmail.com aisteaisteb@gmail.com" #separate each address with a space
else  echo "Unknown error when selecting MODE"; fi

#=======OPTIONS========
: ${dbg:="1"}	# dbg= {0 - off, 1 - on }  for debuging purposes
#============FUNCTIONS====================
actions_before_new_test()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This is a place for all house cleaning actions before new test
    #== House cleaning before tests
    #killall -9 dispatch.fcgi    # removing all dispatch processes. As they are hanging up and consuming RAM;           We are using passenger now

    sync; echo 3 > /proc/sys/vm/drop_caches &> /dev/null # clean mem cache
    #=======================LOGS==============================

    rm -rf /home/tickets/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log 
    touch /home/tickets/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log
    chmod 777 /var/log/httpd/access_log /var/log/httpd/error_log /home/tickets/log/production.log /var/log/mor/selenium_server.log

    # clean uploaded auto dialer files; Hardcoding for now. Please note that this value can also be set in environment.rb. Also please note that the path currently set there is just a symlink
    rm -rf /home/mor/public/ad_sounds/*.wav
    # cleaning test IVR files
    
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /tmp/mor_crash.txt /home/tickets/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log
    mkdir -p /home/mor/log /var/log/httpd
    chmod -R 777 /home/tickets/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/httpd

    chmod 777 /tmp/mor*

}

check_if_there_is_available_new_revision()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function checks if a new revision is available, if yes and and all previously failed tests are already tested - current revision testing is canceled.

    REPO_CURRENT_REVISION=`svn info http://svn.kolmisoft.com/crm/branches/ror3 |  grep "Changed Rev:" | awk '{print \$NF}'`
    if [ "$REPO_CURRENT_REVISION" -gt "$CURRENT_REVISION" ]; then
        echo "Found new revision in repository, killing current revision testing and starting new one"
        echo "New revision found. Aborting current revision: $CURRENT_REVISION. Will start: $REPO_CURRENT_REVISION" >> /var/log/mor/current_test
        rm -rf /tmp/.mor_test_is_running    # cleaning the lock
        exit 0
    fi
    echo "No new revision found."
}
initialize_ror()
{
    # initiate apache/compile ror

    echo "Initializing GUI"
    if [ `curl http://127.0.0.1/tickets/callc/login 2> /dev/null | grep "login_username" | wc -l` != "1" ]; then
        echo "MOR GUI is not accessible, will wait 3 seconds" >> /var/log/mor/n
        sleep 3
        if [ `curl http://127.0.0.1/tickets/callc/login 2> /dev/null | grep "login_username" | wc -l` != "1" ]; then
            echo "Something happened with GUI - it is not accessbile even after giving 3 second for initialization" >> /var/log/mor/n
            exit 0
        fi
    fi
}
restart_services_if_not_enough_ram()
{

    rm -rf /home/tickets/public/javascripts/tiny_mce
    svn update /home/tickets


    if [ `free -m | grep cache | awk '{ print \$4}' | tail -n 1` -lt "150" ]; then
	echo "Not enough RAM, cleaning..."
        killall -9 dispatch.fcgi
        ipcs -s | grep apache | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
        service mysqld restart
        service httpd restart
    else
	echo "Reloading Apache"
        service httpd restart #what happens without reload?
    fi
}
default_interface_ip()
{
    #Author: Mindaugas Mardosas
    #This function makes available in your scripts 2 variables: DEFAULT_INTERFACE  - this will be the name of the default interface throw which the traffic will be routed when no other destination adress mathced in kernel routing table. DEFAULT_IP - this is the IP assigned to DEFAULT_INTERFACE
    #How to use this function:
        # write anywhere in your script a call to this function and then you can use those two global variables for that script. Example:
        #       default_interface_ip;
        #       echo $DEFAULT_INTERFACE;
        #       echo $DEFAULT_IP;

    DEFAULT_INTERFACE=`/bin/netstat -nr | (read; cat) | (read; cat) | grep "^0.0.0.0" | awk '{ print $8}' | head -n 1` #Gets kernel routing table, when skips 2 first lines, when grep's the default path and finally prints the interface name
    DEFAULT_IP=`/sbin/ip addr show $DEFAULT_INTERFACE | grep "inet " | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`
    DEFAULT_INTERFACE_MAC=`/sbin/ifconfig | grep eth | awk -F'HWaddr' '{print $2}' | sed 's/ //g'`
}
prepare_new_queue()
{


    rm -rf /var/log/mor/queue
    touch /var/log/mor/queue

    # 1. adding first_test tests from svn
    if [ -f /home/tickets/selenium/test_first ]; then
        FILE="/home/tickets/selenium/test_first"
        exec < $FILE
        while read testas; do
            if [ -f "$testas" ]; then
                echo $testas >> /var/log/mor/queue
            else
                echo "/home/tickets/selenium/test_first (maintained by programmers) contains incorrect test names or paths. Path $testas does not exist in file system, skipped adding to queue: /var/log/mor/queue"
            fi
        done
    fi



    # 2. adding failed tests from previous test-run
    if [ -f /var/log/mor/failed_tests ]; then
        cat /var/log/mor/failed_tests >> /var/log/mor/queue
        #deleting failed tests so they do not accumulate, e.g. will test first only tests which failed from last revision
        rm -fr /var/log/mor/failed_tests
    else
        touch /var/log/mor/queue # why we touch this file here??
    fi
    touch /var/log/mor/failed_tests



    # 3. adding recently changed tests in svn
    #    cd /home/mor/selenium
    #    svn diff --summarize -r28160:28168
    #    atmesti tuos, kurie prasideda D (deleted)
    #    imti -10 reviziju
    # todo...



    # 4. adding remaining tests in random order
    echo "success" >> /var/log/mor/queue # from this point it is assumed that later tests previously were successful

    TEST_DIR=/home/tickets/selenium/tests
    find $TEST_DIR -name "*.case" > /tmp/tests
    for i in `cat /tmp/tests`; do echo "$RANDOM $i"; done | sort | sed -r 's/^[0-9]+ //' > /tmp/randomized_tests    # Magic line to randomize lines order in files
    rm -rf /tmp/tests

    FILE="/tmp/randomized_tests"
    exec < $FILE
    while read testas; do
        TEST_DIR_LENGTH=${#TEST_DIR}+1
        TEST_FIRST_LETTER=${testas:$TEST_DIR_LENGTH:1}
        POSITION_IN_ARRAY=`expr index "$TESTS_STARTS_WITH" $TEST_FIRST_LETTER`

        if [ "$POSITION_IN_ARRAY" != "0" ]; then
            if [ `grep "$testas" /var/log/mor/queue | wc -l` == "0" ]; then  #not found in current queue
                echo "Adding test: $testas to queue /var/log/mor/queue"
                echo "$testas" >> /var/log/mor/queue
            else
                echo "$testas is already in queue with higher priority"
            fi
        fi
    done


    # remove duplicates in whole file but keep same test order
    awk '!x[$0]++' /var/log/mor/queue > /var/log/mor/queue_nodups
    rm -fr /var/log/mor/queue
    mv /var/log/mor/queue_nodups /var/log/mor/queue

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
    #mysql mor -e "show processlist" 2>&1>> $TMP_FILE
}

gems_update_with_bundler()
{
    CURRENT_RAKEFILE_VERSION=`md5sum /home/tickets/Gemfile | awk '{print $1}'`
    OLD_RAKEFILE_VERSION=`cat /usr/local/mor/test_environment/Gemfile`

    if [ "$CURRENT_RAKEFILE_VERSION" != "$OLD_RAKEFILE_VERSION" ]; then
        echo "Running bundler to update gems"
        cd /home/tickets
        bundle install
        echo "$CURRENT_RAKEFILE_VERSION" > /usr/local/mor/test_environment/Gemfile
    fi
}

clean_logs()
{
    rm -rf /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log /var/log/mor/test_system /tmp/crm_crash.log /home/tickets/log/production.log
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log /var/log/mor/test_system /tmp/crm_crash.log /home/tickets/log/production.log
    chmod 777 /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log /var/log/mor/test_system /tmp/crm_crash.log /home/tickets/log/production.log
}
restart_services()
{
    killall -9 java
    start_selenium_server;
}


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
            default_interface_ip
            if [ "$DEFAULT_IP" == "192.168.0.14" ]; then    # If production server IP - update till stable revision.
                STABLE_REVISION=`head -n 1 /home/tickets/stable_revision`
                svn update -r $STABLE_REVISION /home/tickets
            else
                svn update /home/tickets
            fi
            chmod 777  /home/tickets/log/searchd.production.pid
            return 1
        fi
    else
        echo "Searchd is not installed and failed to fix this"
        return 1
    fi
}
searchd_running


#------------------------------------------
import_db(){
	#dropping tables in tickets database
	mysql tickets -e "show tables" | grep -v Tables_in | grep -v "+" | gawk '{print "drop table " $1 ";"}' | mysql tickets

	cd /home/tickets/selenium/sql


	echo "importing struckt.sql"
	mysql tickets < /home/tickets/selenium/sql/struckt.sql

	echo "importing translations.sql"
	mysql tickets < /home/tickets/selenium/sql/translations.sql


	echo "importing conflines.sql"
	mysql tickets < /home/tickets/selenium/sql/conflines.sql

	echo "importing emails.sql"
	mysql tickets < /home/tickets/selenium/sql/emails.sql

	echo "importing hearfromusplaces.sql"
	mysql tickets < /home/tickets/selenium/sql/hearfromusplaces.sql

	echo "importing directions.sql"
	mysql tickets < /home/tickets/selenium/sql/directions.sql

	echo "importing permissions.sql"
	mysql tickets < /home/tickets/selenium/sql/permissions.sql

	echo "importing datas.sql"
	mysql tickets < /home/tickets/selenium/sql/datas.sql

    echo "importing permissions_data_changes.sql"
    mysql tickets < /home/tickets/doc/permissions_data_changes.sql

}
#------------------------------------------
dir_exists()
{
if [ -d "$1" ]; then
    [ $dbg == 1 ] && echo "$1 is dir";
        return 0;
    else return 1;
fi
}
#-------------------------------------------
_mor_time() { mor_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`; }

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

    # determine if test is OK or FAILED
    grep -v -F "subframe appears" $TMP_FILE | grep "^error:\|^warn:"   &> /dev/null     # first grep - nasty hack for crm to ignore the message by selenium and report that test as ok
    if [ "$?" == "0" ]; then
        STATUS_v2="FAILED";
        # Saving test state as failed to log - next time it will be launched first
        echo "$testas" >> /var/log/mor/failed_tests
    else
        STATUS_v2="OK";
    fi

    TEST_NODE_ID_FROM_BRAIN="123" #hack to be compatible with brain2
    TEST_PRODUCT="crm"      #porting function here from more advanced scripts

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
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN"  "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 $TEST_NODE_ID_FROM_BRAIN  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"test_log $TMP_FILE\""
                elif [ "$TEST_PRODUCT" == "crm" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb 'tickets' $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN" "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP"  "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb tickets $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 $TEST_NODE_ID_FROM_BRAIN  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"test_log $TMP_FILE\""
                fi
            else
                gather_log_about_machine_state_after_failed_test  # the test failed, gathering additional logs

                if [ "$TEST_PRODUCT" == "mor" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN"  "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP" "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"$TEST_NODE_ID_FROM_BRAIN\"  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"my_debug /tmp/mor_debug.txt\" \"crash_log /tmp/mor_crash.log\" \"production_log /home/mor/log/production.log\" \"access_log /var/log/httpd/access_log\" \"error_log  /var/log/httpd/error_log\" \"selenium_server_log /var/log/mor/selenium_server.log\" \"test_log $TMP_FILE\""
                elif [ "$TEST_PRODUCT" == "crm" ]; then
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb 'tickets' $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN" "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP"  "my_debug /tmp/crm_debug.txt" "crash_log /tmp/crm_crash.log" "production_log /home/tickets/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. [ $STATUS_v2 ] ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb tickets $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 \"$TEST_NODE_ID_FROM_BRAIN\"  \"$JOB_RECEIVED_TIMESTAMP\" \"$SELENIUM_START_TIMESTAMP\" \"$SELENIUM_FINISH_TIMESTAMP\" \"my_debug /tmp/mor_debug.txt\" \"crash_log /tmp/mor_crash.log\" \"production_log /home/mor/log/production.log\" \"access_log /var/log/httpd/access_log\" \"error_log  /var/log/httpd/error_log\" \"selenium_server_log /var/log/mor/selenium_server.log\" \"test_log $TMP_FILE\""
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
            echo "[`date +%0k\:%0M\:%0S`] PS ID: $$. Test reporting to brain failed: [ $STATUS_v2 ] $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS $CURRENT_REVISION $RELATVE_PATH_TO_TEST "
        fi
    else
        echo "[`date +%0k\:%0M\:%0S`] The reporter script was not found"
    fi
}
special_test_cases()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    There are cases when it's very hard to write a good test which behaves accoring to specific day it's run. For example first day of the month when calculations are totally different.
    #
    # This function reads test header and does some actions according to it. Available actions documentation:
    #   mor_condition;day;1;alternative_test_path
    #   mor_condition;day;1;/home/mor/selenium/exceptions/services_daily_first_day.case
    local tst=$1
    
    if [ `grep mor_condition $tst | wc -l` -gt "0" ]; then
        local condition=`grep mor_condition $tst | awk -F";" '{print $2}'`
        local argument=`grep mor_condition $tst | awk -F";" '{print $3}'`
        local alternative_test=`grep mor_condition $tst | awk -F";" '{print $4}'`
            
        if [ "$condition" = "day" ]; then
            local DAY_OF_MONTH=`date +%-d`
            if [ "$argument" == "$DAY_OF_MONTH" ]; then
                testas="$alternative_test"
            fi
        fi
    fi
}


#=====================================================================
last_directory_in_the_path()
{
	last_dir_in_path=`pwd | awk -F\/ '{print $(NF)}'`;
}
#===========================MAIL======================================
send_report_by_email()	{
	if [ -f "$SEND_EMAIL" ]; then

		if [ "$STATUS" == "OK" ]; then
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][TICKETS SERVER $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS     `cat $report`"  $EMAIL_SEND_OPTIONS > /tmp/mor_temp

		elif [ "$STATUS" == "FAILED" ]; then
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][TICKETS SERVER $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS `cat $report`" -a $MOR_CRASH_LOG $EMAIL_SEND_OPTIONS > /tmp/mor_temp
		fi

		else echo "$SEND_EMAIL NOT FOUND!";
	fi

	if [ $? == 0 ]; then echo "Email was sent"; fi
}

#====================================================================
is_another_test_still_running()
{
	if [ -f "$TEST_RUNNING_LOCK" ]; then
		echo "$mor_time Another test is already running, exiting";
		exit 0;
	fi
}
#======================================


ferret_check_and_start()
{
  ferret=`ps aux | grep ferret | grep -v grep | wc -l`;

  if [ "$ferret" == "1" ]; then
    echo "Ferret - OK";
    return 0;
  elif [ "$ferret" == "0" ]; then
    echo "Starting ferret";
      cd /home/tickets/
      ./start_ferret.sh
  else
    echo "Unknown error with ferret check/start";
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

run_all_rb()
{
                #/home/tickets/delay_job_restart.sh
                #killall -9 java

		echo -e "REVISION: $CURRENT_REVISION\nLAST AUTHOR: $LAST_AUTHOR">>$report
                echo "Converting files which starts with: $TESTS_STARTS_WITH"

                prepare_new_queue   #preparing new test queue, failed tests are tested first

                check_for_new_rev_on_every_test="0"

                FILE="/var/log/mor/queue"
                exec < $FILE


                while read testas;  do
	    

#-----------

		    #sleep 15

                    #---- Check if there is available new revision
                    if [ "$testas" == "success" ]; then
                        check_for_new_rev_on_every_test=1
                        continue
                    fi

                    if [ "$check_for_new_rev_on_every_test" == "1" ]; then
                        check_if_there_is_available_new_revision
                        echo "OK $testas" >> /var/log/mor/current_test
                    else
                        echo "FAILED $testas" >> /var/log/mor/current_test
                    fi

                    #--------- Checking if test exists in file  system
                    if [ ! -f "$testas" ]; then
                        echo "Test $testas does not exist on file system, skipping"
                        continue
                    fi

                    #--------------------------------------------

                    echo -ne "\nStarting new test: "

                    JOB_RECEIVED_TIMESTAMP=`date +%s`

                    JOB_RECEIVED_HUMAN=`date +%Y\-%-m\-%-d\ %-k\:%-M\:%-S`
                    
                    actions_before_new_test 

                    dir_exists testas; #checking whether we have path to dir or file
                    if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..


#----------

		    # loop which runs test 3 times, with a hope to get OK
		    # this is done to avoid messing with selenium-ajax issue where test sometimes fails because selenium cannot properly test ajax
                    for i in 1 2 3 # NEVER EVER change this -> waste of time
                    do

                	import_db  # creating thread dropping and importing a fresh database

                	echo "Proceeding test: $testas"
                	TMP_FILE=`mktemp`


   
                        ORIGINAL_TEST="$testas"
                        special_test_cases $testas # This function is required for very special cases when it's not possible to write tests for special cases for example for the first day of the month. What this function does - it launches alternative test in such case.
                        #-----

                	TEST_NAME=`echo "$testas" | awk -F "/" '{print $NF}' |  awk -F "." '{print $1}'`
                	TEST_TEST="$testas"

                	generate_suite_file $TEST_NAME $TEST_TEST

                	# Here is is very important part - the script adds here at the beginning of test new command setTimeout which sets timeout for each command in the test. 60000 = 60 seconds

                	sed -e 's/<\/thead><tbody>/<\/thead><tbody>\n<tr>\n<td>setTimeout<\/td>\n<td>20000<\/td>\n<td><\/td>\n<\/tr>/g' $TEST_TEST > /tmp/$TEST_NAME.html

			#echo "Waiting for BG jobs to complete"
                	#wait

                	restart_services_if_not_enough_ram      #to do: later he add procedures to track tests which eat up all ram

                	initialize_ror

                	echo "Starting Selenium"
                	SELENIUM_START_TIMESTAMP=`date +%s`
                	SELENIUM_START_HUMAN=`date +%Y\-%-m\-%-d\ %-k\:%-M\:%-S`
                	echo "$JOB_RECEIVED_HUMAN - Started to prepare VM for $testas" >> /var/log/mor/time
                	echo "$SELENIUM_START_HUMAN - Selenium start" >> /var/log/mor/time

                	# run the test
                        default_interface_ip    #getting IP each time - because if DHCP changes the IP - the whole revision will fail
                        
                        if [ "$ENABLE_PERFORMANCE_LOGGING" == "1" ]; then
                            log_performance_metrics "Performance metrics before test: $testas"
                        fi
                        
                        #rm -rf /home/tickets/public/javascripts/tiny_mce
                        #svn update /home/tickets/public/
                        
                        rm -rf  /home/tickets/public/attachments/*
                        chmod -R 777 /home/tickets/public
                        chmod +t /home/tickets/public
                        #-----
                        
                	DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -timeout 300 -singleWindow -log $SELENIUM_SERVER_LOG -htmlSuite "*firefox" "http://$DEFAULT_IP" "/tmp/suite.html" "/tmp/rezultatas.html"

                        
                        testas="$ORIGINAL_TEST"
                        TEST_TEST="$ORIGINAL_TEST"

                        
                	SELENIUM_FINISH_TIMESTAMP=`date +%s`
                	SELENIUM_FINISH_HUMAN=`date +%Y\-%-m\-%-d\ %-k\:%-M\:%-S`
                	echo "$SELENIUM_FINISH_HUMAN - Selenium end" >> /var/log/mor/time
                	echo -ne "\nSelenium finished: "
                        
                        if [ "$ENABLE_PERFORMANCE_LOGGING" == "1" ]; then
                            log_performance_metrics "Performance metrics after test: $testas"
                        fi
                	# memory
                	#free -m
                	#killall -9 dispatch.fcgi
                	#killall -9 ruby
                	free -m

                	if [ ! -f /tmp/rezultatas.html ]; then
                    	    echo "Something went wrong -  /tmp/rezultatas.html does not exist. Cancelling this machine tests" >> /var/log/mor/n
                    	    killall -9 java &> /dev/null
                    	    killall -9 firefox &> /dev/null
                    	    exit 0
                	fi

                	#echo -ne "Time log for all tests in this machine:\n\nhttp://$DEFAULT_IP/time\n\n" >> $TMP_FILE
                	cat /tmp/rezultatas.html >> $TMP_FILE

                	# check if test is OK or FAILED, finish if OK
                	grep -v -F "subframe appears" $TMP_FILE | grep "^error:\|^warn:"   &> /dev/null
                	if [ "$?" == "0" ]; then
                	    echo "Test Status $i: FAILED..."

                	    #reporting job to BRAIN
                	    job_report $testas >> /var/log/mor/n     #moving job reporting to separate thread

                	else
                	    echo "Test Status $i: OK!"
                    	    # get out of loop because we have OK!

                	    #reporting job to BRAIN
                	    job_report $testas >> /var/log/mor/n     #moving job reporting to separate thread

                    	    break
                	fi


		    #end for loop which runs test for 3 times till OK
                    done

                    # separate visually test logs
                    echo "" >> /var/log/mor/time


                done

                mv /var/log/mor/time /var/log/mor/time_previous
                touch /var/log/mor/time

		echo -e "Report was generated...\nReport was saved to $report\n";
}

#--------------------------------------------

#====================================MAIN============================
_mor_time;


if [ -z "$1" ]; then
    echo -e "\n\n=========Tickets TEST ENGINE CONTROLLER=======";
    echo "Arguments:";
    echo -e "\t-s \tStart a Selenium RC server\n";
    touch /tmp/ror_debug.log
    chmod 777 /tmp/ror_debug.log
elif [ "$1" == "-a" ]; then  #do all tasks
    

    
    URL="$2" #saving second parameter before it gets overwritten by set command
    is_another_test_still_running #if another instance is running - script will terminate.
    touch "$TEST_RUNNING_LOCK"  #creating the lock
    
    echo "Cleaning TinyMCE"
    rm -rf /home/tickets/index/
    rm -rf /home/tickets/public/javascripts/tiny_mce
    svn update /home/tickets


    
    cp -fr /home/tickets/selenium/files/environment.rb /home/tickets/config/environment.rb
    #rm -rf /home/tickets/index/
    
    #cp /home/tickets/selenium/files/dtree.js /home/tickets/public/javascripts/dtree.js
    chmod -R 777 /home/tickets/public/javascripts/dtree.js /home/tickets/public/images
    chmod 755 /etc/ssh/sshd_config
    
    #rm -rf  /home/tickets/public/attachments/*
    #chmod -R 777 /home/tickets/public/attachments/
    
    #if [ ! -f "/usr/bin/tickets" ]; then
    #    ln -s /home/tickets/selenium/scripts/tickets_test_run.sh /usr/bin/tickets
    #fi

    chmod +x /usr/bin/tickets /home/tickets/selenium/scripts/tickets_test_run.sh

    rm -rf /tmp/crm_crash.log
    echo -e "\n------\n" >> /var/log/mor/selenium_server.log
    touch /tmp/crm_crash.log
    chmod 777 /tmp/crm_crash.log

    [ $dbg == 1 ] && echo -e "\n$mor_time";

    #if [ "$MODE" == "1" ]; then	$GUI_UPGRADE_CMD; fi #upgrading GUI


    set $(cd /home/tickets/ && svn info | grep "Last Changed Rev") &> /dev/null
    CURRENT_REVISION="$4";  #newest

    set $(cat "$LAST_REVISION_FILE" | tail -n 1 ) &> /dev/null
#				set $(cat /usr/local/mor/test_environment/last_revision | tail -n 1 ) &> /dev/null

    LAST_REVISION=$2;

    set $(cd /home/tickets/ && svn info | grep "Last Changed Author:");
    LAST_AUTHOR="$4"

    [ $dbg == 1 ] && echo "Current revision: $CURRENT_REVISION";
    [ $dbg == 1 ] && echo "Last revision: $LAST_REVISION";
    [ $dbg == 1 ] && echo "Last author: $LAST_AUTHOR";


    if [ "$CURRENT_REVISION" != "$LAST_REVISION" ] || [ "$MODE" == "0" ]; then
        mv /dev/random /dev/random.real
        ln -s /dev/urandom /dev/random
        gems_update_with_bundler    #this command is long lasting, so it runs selectively only if needed
        chmod -R 777 /home/tickets/public/attachments/
        [ $dbg == 1 ] && echo "Versions didn't matched, running the tests"
        killall -9 httpd
        /etc/init.d/httpd restart
        report="$DIR_FOR_LOG_FILES/$LOGFILE_NAME.$mor_time.txt"
        run_all_rb "$URL";

        #====checking for errors or failures
        grep "Error:" $report
        if [ "$?" == "0" ]; then
                STATUS="FAILED";
                else STATUS="OK";
        fi

        grep "Failure:" $report
        if [ "$?" == "0" ]; then STATUS="FAILED"; fi
        #===================================

        [ $dbg == 1 ] && echo  "$STATUS";
        send_report_by_email;
        echo -e "$mor_time\t$CURRENT_REVISION\t\t$LAST_AUTHOR\t$STATUS" >> $LAST_REVISION_FILE
    fi

    rm -rf "$TEST_RUNNING_LOCK";
    if [ "$?" != "0" ]; then echo "$mor_time Failed to delete $TEST_RUNNING_LOCK lock"; fi;

elif [ "$1" == "-l" ]; then
    #ferret_check_and_start
    rm -rf /home/tickets/index/
    svn co http://svn.kolmisoft.com/crm/branches/ror3 /home/tickets
    rm -rf /home/tickets/index/

    rm -rf  /home/tickets/public/attachments/*
    chmod -R 777 /home/tickets/public/attachments/

    import_db; 	#import
    chmod +x /usr/bin/tickets /home/tickets/selenium/scripts/tickets_test_run.sh
    /etc/init.d/httpd restart


elif [ "$1" == "-rails" ]; then
    rm -rf /home/tickets/Gemfile* /home/tickets/public/javascripts/tiny_mce/
    tickets -l
    cd /home/tickets
    bundle
    bundle update rails
    /etc/init.d/httpd restart
fi
