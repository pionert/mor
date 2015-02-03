#! /bin/bash
#===== README ====
# MOR installation must be upgraded to the most recent version
# This script upgrades mor GUI only with a command specified by GUI_UPGRADE_CMD  variable
# selenium-server must be running
# start selenium server with command:
# 		./mor_test_run.sh -s
#
#==============

. /usr/local/mor/test_environment/mor_test.cfg

. /usr/src/mor/test/framework/bash_functions.sh

SELENIUM_SERVER_VERSION="2.24.1"

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

another_java_instance()
{
    if [ `ps aux | grep java | grep -v grep  | wc -l` != "0" ]; then
        echo "There is another java instance running! " >> /var/log/mor/n
        exit 0
    fi
    
}
restart_services_if_not_enough_ram()
{
    if [ `free -m | grep cache | awk '{ print \$4}' | tail -n 1` -lt "150" ]; then
        service httpd restart
        killall -9 dispatch.fcgi
        ipcs -s | grep apache | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
        service mysqld restart
    else
        service httpd reload
    fi   
}
actions_before_new_test()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This is a place for all house cleaning actions before new test
    #== House cleaning before tests
    #killall -9 dispatch.fcgi    # removing all dispatch processes. As they are hanging up and consuming RAM;           We are using passenger now

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

initialize_ror()
{
    # initiate apache/compile ror
    
    if [ `curl http://127.0.0.1/billing/callc/login 2> /dev/null | grep "login_username" | wc -l` != "2" ]; then
        echo "MOR GUI is not accessible" >> /var/log/mor/n
        exit 0
    fi    
}
drop_and_free_swap()
{
    sysctl -w vm.swappiness=0
    echo 0 >/proc/sys/vm/swappiness
    # kill some nonsense
    killall -9 wnck-applet
    # clean mem cache
    sync; echo 3 > /proc/sys/vm/drop_caches

    swapoff -a  # turning of all swap if any
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

    grep -v -F "warn: Current subframe appears" $TMP_FILE | grep "error:\|warn:"   &> /dev/null     # first grep - naisty hack for crm to ignore the message by selenium and report that test as ok
    if [ "$?" == "0" ]; then
        STATUS_v2="FAILED";
    else
        STATUS_v2="OK";
    fi
    TEST_NODE_ID_FROM_BRAIN="123" #hack to be compatible with brain2
    TEST_PRODUCT="mor"      #porting function here from more advanced scripts
    
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
                    local result=`ruby /usr/src/mor/test/node2/brain-scripts/reporter.rb 'tickets' $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "$TEST_NODE_ID_FROM_BRAIN" "$JOB_RECEIVED_TIMESTAMP" "$SELENIUM_START_TIMESTAMP" "$SELENIUM_FINISH_TIMESTAMP"  "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
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

start_selenium_server()
{
    running=`ps aux | grep -m 1 selenium-server.jar | awk '{ print $NF}'`
    if [ "$running" == "-singleWindow" ]; then
        echo "Selenium server is already running";
    else
        echo "Starting selenium server"
        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar -singleWindow >> /var/log/mor/selenium_server.log &
    fi
}
#start_selenium_server
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
#--- git-------


git_check_and_install()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func installs git if it is not present
    if [ ! -f /usr/bin/git ]; then
        cd /usr/src/
        wget -c http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm
        rpm -Uvh epel-release-*
        yum check-update
        yum -y install git
    fi
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

checkout_brain_script()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func downloads latest Kolmisoft TEST SYSTEM v2 brain scripts from brain git repo
    git_check_and_install
    rm -rf /usr/src/brain-scripts
    cd /usr/src
    git clone git://$GIT_REPO_ADDRESS/brain-scripts.git &
}

#git_check_and_install
#gem_rest_client_check_and_install
#checkout_brain_script


#---- /git-----

#------------------------------------------
prepare_db(){

	# recreate ramdisk
	cd /usr/local/mor
	./rebuild_mysql_ram.sh > /var/log/mor/rebuild_mysql_ram.log 2>&1

	cd /usr/src/mor/db/0.8/
	./make_new_db.sh nobk

        mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;
        if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/9/import_changes.sh" 3; fi
        /usr/src/mor/db/9/import_changes.sh
        if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/10/import_changes.sh" 3; fi
        /usr/src/mor/db/10/import_changes.sh
        if [ "$N_DEBUG" == "1" ]; then report "Running /usr/src/mor/db/11/import_changes.sh" 3; fi
        /usr/src/mor/db/11/import_changes.sh
        mysql mor < /home/mor/selenium/mor_trunk_testdb.sql
        
	echo "Exporting prepared db to ramdisk"
	#rm -fr /home/ramdisk/mor.sql
	mysqldump -h localhost -u mor -pmor mor > /home/ramdisk/mor.sql

}


#------------------------------------------
import_db(){
	echo "Importing test mor database from /home/ramdisk/mor.sql";
	mysql mor < /home/ramdisk/mor.sql
}
#------------------------------------------
#------------------------------------------
dir_exists()
{
   if [ -d "$1" ];
			then
					[ $dbg == 1 ] && echo "$1 is dir";
					return 0;
      else return 1;
   fi
}
#-------------------------------------------
_mor_time()
{
	mor_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
}
#--------------------------------------------
last_dir_file_in_path()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2010
    #   About:  This function extracts last dir/file from path and assigns that string to GLOBAL variable $LAST_STRING_IN_PATH
    #
    #   Arguments:
    #       $1  - Path. For example "/var/log/mor"
    #
    #   Other notes:
    #       There should be no spaces in the path
    #
    #   Usage examples:
    #       last_dir_file_in_path "/var/log/mor"    #the string "mor" will be assigned to variable $LAST_STRING_IN_PATH
    #

    DEBUG=0     #   { 0 - debug OFF, 1 - debug ON}

    LAST_STRING_IN_PATH=`echo "$1" | awk -F"/" '{ print $NF}'`
    if [ "$DEBUG" == "1" ]; then
        echo "$LAST_STRING_IN_PATH"
    fi
}
run_all_rb()
{
                rm -rf /tmp/mor_session.log /tmp/session.log.tar.gz
                touch /tmp/mor_session.log
		chmod 777 /tmp/mor_session.log

		echo -e "REVISION: $CURRENT_REVISION\nLAST AUTHOR: $LAST_AUTHOR">>$report
                echo "Converting files which starts with: $TESTS_STARTS_WITH"
        
                find $TEST_DIR -name "*.case" | sort | while read testas;  do

                    TEST_DIR_LENGTH=${#TEST_DIR}+1
                    TEST_FIRST_LETTER=${testas:$TEST_DIR_LENGTH:1}
                    POSITION_IN_ARRAY=`expr index "$TESTS_STARTS_WITH" $TEST_FIRST_LETTER`

                    if [ $POSITION_IN_ARRAY != "0" ] ; then
                        echo -ne "\nStarting new test: "
                        
                        JOB_RECEIVED_TIMESTAMP=`date +%s`
                        
                        JOB_RECEIVED_HUMAN=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`
                        another_java_instance   #check for another java instance - kill this script if found
                        actions_before_new_test &
                        
                        dir_exists testas; #checking whether we have path to dir or file
                        if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..
                        import_db &  # creating thread dropping and importing a fresh database
                            
                        # cleanup
                        rm -rf /home/mor/public/ad_sounds/*.wav /tmp/rezultatas.html &
                        # cleaning test IVR files
                        find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf 
                        #-----
    
                        echo "Proceeding test: $testas"
                        TMP_FILE=`mktemp`
                        
                        TEST_NAME=`echo "$testas" | awk -F "/" '{print $NF}' |  awk -F "." '{print $1}'`
                        TEST_TEST="$testas"
                        
                        generate_suite_file $TEST_NAME $TEST_TEST

                        # Here is is very important part - the script adds here at the beginning of test new command setTimeout which sets timeout for each command in the test. 60000 = 60 seconds
                       
                        sed -e 's/<\/thead><tbody>/<\/thead><tbody>\n<tr>\n<td>setTimeout<\/td>\n<td>10000<\/td>\n<td><\/td>\n<\/tr>/g' $TEST_TEST > /tmp/$TEST_NAME.html
                      
                        wait
                        restart_services_if_not_enough_ram      #to do: later he add procedures to track tests which eat up all ram
                        initialize_ror &
                       
                        SELENIUM_START_TIMESTAMP=`date +%s`
                        SELENIUM_START_HUMAN=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`
                        echo -ne "$JOB_RECEIVED_HUMAN - Started to prepare VM for $testas \n$SELENIUM_START_HUMAN - Selenium start\n" >> /var/log/mor/time
                        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar -timeout 600 -singleWindow -htmlSuite "*firefox" "http://$DEFAULT_IP" "/tmp/suite.html" "/tmp/rezultatas.html"
                        SELENIUM_FINISH_TIMESTAMP=`date +%s`
                        SELENIUM_FINISH_HUMAN=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`
                        echo -e "$SELENIUM_FINISH_HUMAN - Selenium end\n\n\n" >> /var/log/mor/time
                        echo -ne "\nSelenium finished: "
                           
                        # memory
                        free -m
                        killall -9 dispatch.fcgi
                        killall -9 ruby
                        free -m
                        
                        if [ ! -f /tmp/rezultatas.html ]; then
                            echo "Something went wrong -  /tmp/rezultatas.html does not exist. Cancelling this machine tests" >> /var/log/mor/n
                            killall -9 java &> /dev/null
                            killall -9 firefox &> /dev/null
                            exit 0
                        fi
                        
                        #echo -ne "Time log for all tests in this machine:\n\nhttp://$DEFAULT_IP/time\n\n" >> $TMP_FILE
                        cat /tmp/rezultatas.html >> $TMP_FILE
                        job_report 0 >> /var/log/mor/n  &   #moving job reporting to separate thread
                    fi
                done
                
                mv /var/log/mor/time /var/log/mor/time_previous
                touch /var/log/mor/time
                
		echo -e "Report was generated...\nReport was saved to $report\n";
}
#=====================
delete_all_rb()
{
	echo "Deleting stale *.rb files";
		find $TEST_DIR -name "*.rb" | sort | while read testas
		do
			dir_exists testas; #checking whether we have path to dir or file
			if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..'

			rm -rf $testas
		done
		echo "All stale *rb files were deleted";
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
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][MOR TESTS $SERVER_NAME $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS     `cat $report`" -a /tmp/session.log.tar.gz  $EMAIL_SEND_OPTIONS > /tmp/mor_temp

		elif [ "$STATUS" == "FAILED" ]; then
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][MOR TESTS $SERVER_NAME $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS `cat $report`" -a  /tmp/session.log.tar.gz -a $MOR_CRASH_LOG $EMAIL_SEND_OPTIONS > /tmp/mor_temp
		fi

		else echo "$SEND_EMAIL NOT FOUND!";
	fi

	if [ $? == 0 ]; then echo "Email was sent"; fi
}
#=====================================================================
skip_failed_test()
{   
    #   Author: Mindaugas Mardosas
    #   About: This function checks if this test was converted successfully - if not - forces to skip the test (problem was already reported)
    
    grep "$testas" /tmp/failed_conversions   &> /dev/null
    if [ "$?" == "0" ]; then
        echo "$testas was not converted successfully, skipping"
        continue;
    fi
}
convert_html_cases_to_rb()
{

	echo "Converting files which starts with: $TESTS_STARTS_WITH"

	find $TEST_DIR -name "*.case" | sort | while read testas
		do

			TEST_DIR_LENGTH=${#TEST_DIR}+1
			TEST_FIRST_LETTER=${testas:$TEST_DIR_LENGTH:1}
			POSITION_IN_ARRAY=`expr index "$TESTS_STARTS_WITH" $TEST_FIRST_LETTER`

			if [ $POSITION_IN_ARRAY != "0" ] ; then

			    dir_exists testas; #checking whether we have path to dir or file
			    if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..'
			    echo "Converting test: $testas"
                            TEMP=`/bin/mktemp`
			    ruby /home/mor/selenium/converter/converter.rb -h "http://$1" $testas &> /tmp/test_convert_error

                            grep "flunk\|converter.rb\|syntax error" /tmp/test_convert_error &> /dev/null
            
                            if [ "$?" == "0" ]; then    #error was found!
                                #===report to brain
                                if [ -f /usr/src/brain-scripts/reporter.rb ]; then
                                    RELATVE_PATH_TO_TEST=`echo $testas | sed 's/\/home\/mor\/selenium\/tests\///'`
            
                                    local counter=0;
                                    while [ "$counter" != "5" ]; do
                                        counter=$(($counter+1))
                                        local temp=`mktemp`
            
                                        local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST "FAILED" "test_log /tmp/test_convert_error" | tee -a $temp /tmp/reporter.log`
            
                                        grep "RECEIVED" $temp &> /dev/null
                                        if [ "$?" == "0" ]; then
                                            rm -rf $temp $TMP_FILE
                                            break;
                                        fi
            
                                        rm -rf $temp
                                        sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
                                    done
                                else
                                    echo "The reporter script was not found"
                                fi
                                echo "$testas" >> /tmp/failed_conversions
                            fi
                        #======
        
                        rm -rf /tmp/test_convert_error    # cleanup
                        #================================
			else
			    echo "Skipping file: $testas"
			fi

		done
		
}
#====================================================================
is_another_test_still_running()
{
	if [ -f "$TEST_RUNNING_LOCK" ]; then
		echo "$mor_time Another test is already running, exiting";
		exit 0;
	fi
}



#====================================MAIN============================
_mor_time;




if [ -z "$1" ];
	then
		echo -e "\n\n=========MOR TEST ENGINE CONTROLLER=======";
		echo "Arguments:";
		echo -e "\t-a \tUpgrades GUI, resets a database, runs all tests, sends the report by email.";
		echo -e "\t-i \tGives you a fresh database, by importing $PATH_TO_DATABASE_SQL";
		echo -e "\t-d \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS";
		echo -e "\t-r \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS and replaces the default database file $PATH_TO_DATABASE_SQL \n";
		echo -e "\t-s \tStart a Selenium RC server\n";

	elif [ "$1" == "-a" ]; then  #do all tasks

		URL="$2" #saving second parameter before it gets overwritten by set command

		is_another_test_still_running #if another instance is running - script will terminate.

                mor_gui_current_version
		touch "$TEST_RUNNING_LOCK"  #creating the lock
                
                killall java  &> /dev/null      #ensuring that no other Java instances are running
                copy_selenium_to_ram_if_not_present
                rm -rf /tmp/failed_conversions
                default_interface_ip    #getting this node IP

		svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
		chmod +x /usr/bin/mor
		#chmod +x /home/mor/selenium/scripts/test_run.sh

		rm -rf /tmp/mor_crash.log
		echo -e "\n------\n" >> /var/log/mor/selenium_server.log
		touch /tmp/mor_crash.log
		chmod 777 /tmp/mor_crash.log

		svn status /home/mor | grep "app\|selenium" | awk '{print $2}' | xargs rm -rf      #clean old trash if any
	        svn update /home/mor
		

		set $(cd /home/mor/ && svn info | grep "Last Changed Rev") &> /dev/null
		CURRENT_REVISION="$4";  #newest

		set $(cat "$LAST_REVISION_FILE" | tail -n 1 ) &> /dev/null


		LAST_REVISION=$2;

		set $(cd /home/mor/ && svn info | grep "Last Changed Author:");
		LAST_AUTHOR="$4"

		[ $dbg == 1 ] && echo "Current revision: $CURRENT_REVISION";
		[ $dbg == 1 ] && echo "Last revision: $LAST_REVISION";
		[ $dbg == 1 ] && echo "Last author: $LAST_AUTHOR";


            if [ "$CURRENT_REVISION" != "$LAST_REVISION" ] || [ "$MODE" == "0" ]; then
                [ $dbg == 1 ] && echo "Versions didn't matched, running the tests"
                /etc/init.d/httpd restart
                report="$DIR_FOR_LOG_FILES/$LOGFILE_NAME.$mor_time.txt"
                prepare_db;
                echo "House cleaning...."
                # turn off swap
                drop_and_free_swap &
                echo "Initiating apache/compiling ror..."

                run_all_rb "$URL";
                
                drop_and_free_swap &
                # house cleaning
                restart_services_if_not_enough_ram
        
                rm -fr /tmp/CGI* /tmp/file* /tmp/_sox* /tmp/tmp.* /tmp/*.json.part /tmp/*.pdf.part

                finish_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
                echo "Started: $mor_time      Finished: $finish_time"
                echo "Started:  $mor_time" >> $report
                echo "Finished: $finish_time" >> $report
                echo "Processed tests starting with: $TESTS_STARTS_WITH" >> $report

                #====checking for errors or failures
                grep "Error:" $report
                if [ "$?" == "0" ]; then
                        STATUS="FAILED";
                        else STATUS="OK";
                fi

                grep "Failure:" $report
                if [ "$?" == "0" ]; then STATUS="FAILED"; fi
                #===================================

                #----- put session log to email
                #if [ -f /tmp/mor_session.log ]; then
                #    echo -e "\n\n=========== SESSION LOG ===================" >> $report
                #    tar czf /tmp/session.log.tar.gz /tmp/mor_session.log                   
                #else
                #    echo -e "\n\n\nSession log /tmp/mor_session.log not found" >> $report
                #fi
                #-----
                
                #send_report_by_email;
                echo -e "$mor_time\t$CURRENT_REVISION\t\t$LAST_AUTHOR\t$STATUS" >> $LAST_REVISION_FILE
            fi

            rm -rf "$TEST_RUNNING_LOCK";
            if [ "$?" != "0" ]; then echo "$mor_time Failed to delete $TEST_RUNNING_LOCK lock"; fi;

	elif [ "$1" == "-l" ]; then
		cd /home/mor
		./gui_upgrade_light_4test.sh
		svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
		prepare_db;
		import_db; 	#import
		chmod +x /usr/bin/mor
		chmod +x /home/mor/selenium/scripts/mor_test_run.sh

	elif [ "$1" == "-i" ]; then
         svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
	    	import_db; 	#import
	elif [ "$1" == "-b" ]; then   #RUN BETA TESTS
				is_another_test_still_running #if another instance is running - script will terminate.
				touch "$TEST_RUNNING_LOCK"  #creating the lock
				
				rm -rf "$TEST_RUNNING_LOCK";
				if [ "$?" != "0" ]; then echo "$mor_time Failed to delete $TEST_RUNNING_LOCK lock"; fi;
	elif [ "$1" == "-d" ]; then   # prepare db
				prepare_db;
	elif [ "$1" == "-di" ]; then   # import db
				import_db;
	elif [ "$1" == "-s" ]; then
			start_selenium_server;


fi

