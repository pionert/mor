#! /bin/bash

#-------- Parameters from console ---------

firstParam="$1"
secondParam="$2"
thirdParam="$3"
fourthParam="$4"

#------------------------------------------

N_VERSION="2.9.9.0"

PROFILE="0"

SELENIUM_SERVER_VERSION="2.24.1"

#--- Important ---
BRAIN="brain.kolmisoft.com"      #  /etc/hosts must be configured to contain hostname entry like this: 192.168.0.13 brain2

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

N_DEBUG=0

N_DEBUG_RESOURCE_USAGE=0

BRAIN_MONITORING_GROUP="mindaugas.mardosas@kolmisoft.com"

XVFB_SERVES_TESTS_BEFORE_RESTART="5"

GUI_WAS_UPDATED="FALSE"
#---

#   Author:     Mindaugas   Mardosas
#   Company:    Kolmisoft
#   Year:       2011-2012
#   About:      This is a 2nd generation MOR billing and Kolmisoft CRM 1 testing tool
#       Improvements:
#           1. Caching for DB import
#           2. Caching for GUI version change/update/downgrade
#           3. Ability to report to internal Kolmisoft testing system "brain"
#           4  Ability to receive and complete job requests
#           5. CMR 1 testing support
#           6. Speed improvements
#
#   Usage:
#       n -l                                    # update current version using cache if possible
#       n -l [8, 9, 10, 11, 12]              # upgrade/downgrade to specified MOR version
#       n -l [8, 9, 10, 11, 12] [REVISION]   # upgrade/downgrade to specified MOR version AND revision
#       c -l                                    # update to current CRM 1 version



#===== README ====
# MOR installation must be upgraded to the most recent version
# This script upgrades mor GUI only with a command specified by GUI_UPGRADE_CMD  variable
# selenium-server must be running
# start selenium server with command:
# 		n -s
#
#==============
set +x
#-------- Parameters from console ---------

firstParam="$1"
secondParam="$2"
thirdParam="$3"
fourthParam="$4"


if [ "$thirdParam" == "DEBUG" ] ||  [ "$fourthParam" == "DEBUG" ] || [ "$secondParam" == "DEBUG" ]; then
    export DEBUG="DEBUG"
fi

#-------- Includes -------------------------
if [ -f /usr/src/mor/test/node2/node_functions.sh ]; then
    . /usr/src/mor/test/node2/node_functions.sh
fi

. /usr/src/mor/test/framework/bash_functions.sh
#============SETTINGS========================
LAST_REVISION_FILE="/usr/local/mor/test_environment/last_revision"; #here we will track completed tests
TEST_RUNNING_LOCK="/tmp/.mor_test_is_running";
#=============================MAIN============================

#=======Global variables=============
dbVersionsToKeep=1;        # this amount of db dumps will be kept in /var/lib/mysql_pool/$TEST_MOR_VERSION/ dir
#====================================

_mor_time;

if [ "$N_DEBUG" == "1" ]; then
    report "DEBUG mode enabled" 3
fi


if [ "$firstParam" == "-l" ]; then
    if [ "$N_DEBUG" != "1" ]; then
        upgrade_mor_install_scripts
        echo "labas"
	mkdir -p /etc/m2
	cp -fr /usr/src/mor/test/node2/system.conf /etc/m2/
    fi
    actions_before_new_revision &
    #====== MOR/CRM GUI prepare
        #====== GUI version: 0.8, 9, 10, trunk or crm
        if [ -n "$secondParam" ]; then  #string is not null;  "$secondParam" - MOR version
            if [ "$secondParam" == "trunk" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="trunk"
            elif [ "$secondParam" == "11" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="11"
            elif [ "$secondParam" == "extend" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="12.126"
                
            elif [ "$secondParam" == "x3" ] ||  [ "$secondParam" == "X3" ] || [ "$secondParam" == "12" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="12"

            elif [ "$secondParam" == "x4" ] ||  [ "$secondParam" == "X4" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="x4"
            elif [ "$secondParam" == "x5" ] ||  [ "$secondParam" == "X5" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="x5"
                
            elif [ "$secondParam" == "m2" ] ||  [ "$secondParam" == "M2" ]; then
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="m2"
            else
                TEST_PRODUCT="mor"
                TEST_MOR_VERSION="$secondParam"

            fi
        elif [ "$0" == "c" ] || [ "$0" == "/bin/c" ] ; then       #second one is needed when debugging with /bin/sh -x /bin/mcrm
            #when the script is invoked via symlink: c -l   this part will be executed
            TEST_MOR_VERSION="tickets"
            TEST_PRODUCT="crm"
        else
            mor_gui_current_version &> /dev/null
            # rieik pakeisti situo: node_gui_current_version
            TEST_MOR_VERSION=$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS   #current MOR GUI version in the system: 0.8, 9, 10, trunk, etc
        fi


        #====== Revision for MOR or crm
        if [ -n "$thirdParam" ]; then   #if revision specified - set variable to get that version of GUI
            TEST_REVISION="$thirdParam";
        elif [ "$0" == "c" ] || [ "$0" == "/bin/c" ] ; then       #second one is needed when debugging with /bin/sh -x /bin/mcrm
            #when the script is invoked via symlink: c -l   this part will be executed
            TEST_REVISION=`svn info http://svn.kolmisoft.com/crm/branches/ror3 | grep Revision | awk '{print $2}'`
        else                            #if revision is not specified - set variable to get the latest revision

            if [ "$TEST_MOR_VERSION" == "trunk" ]; then
                TEST_REVISION=`svn info http://svn.kolmisoft.com/mor/gui/trunk | grep 'Last Changed Rev' | awk '{print $NF}'`  #get the latest MOR GUI revision
            
            elif [ "$TEST_MOR_VERSION" == "m2" ]; then
                TEST_REVISION=`svn info http://svn.kolmisoft.com/m2/gui/trunk/ | grep 'Last Changed Rev' | awk '{print $NF}'`
            else
                TEST_REVISION=`svn info http://svn.kolmisoft.com/mor/gui/branches/$TEST_MOR_VERSION | grep 'Last Changed Rev' | awk '{print $NF}'`  #get the latest MOR GUI revision
            fi
            if [ "$N_DEBUG" == "1" ]; then echo "[DEBUG] Retrieved TEST_REVISION: $TEST_REVISION using bash_functions.sh function: gui_revision_check"; fi
        fi

        gui_revision_check &>  /dev/null    # to get current information about MOR in this system

        if [ "$N_DEBUG" == "1" ]; then
           echo -e "[DEBUG] Current MOR version in system: $TEST_MOR_VERSION;   Revision in system: $GUI_REVISION_IN_SYSTEM"
           echo -e "[DEBUG] Current MOR version in repository: $TEST_MOR_VERSION;   Revision in repository: $GUI_REVISION_IN_REPOSITORY"
        fi

        echo "Prepairing GUI and DB: $TEST_MOR_VERSION Revision: $TEST_REVISION";
        cleanup_various_files &
        prepare_gui

        echo "Prepairing DB for $TEST_MOR_VERSION Revision: $TEST_REVISION"
       
        prepare_db
        echo "Done. Prepaired: $TEST_MOR_VERSION Revision: $TEST_REVISION";
        
        check_if_gui_accessible 1 3 EXIT
        if [ "$TEST_PRODUCT" == "mor" ]; then
            change_email_in_environment_rb
        fi
elif [ "$firstParam" == "-a" ]; then
        is_another_test_still_running #exit if another instance is running
        cleanup_various_files &
        /usr/src/mor/test/node2/fix_eth_interface.sh # fix DNS if missing
        #killall -9 Xvfb &> /dev/null
        #check_if_xvfb_is_running
        remove_unneeded_crons
        kill_not_needed_services &
        gem_rest_client_check_and_install &
        #start_selenium_server   # check if selenium is started, if not - starts
        chmod 777 /etc/ssh/sshd_config  # required for crm tests

        XVFB_SERVED_TESTS=0     # how many tests were running since service start

        #check_if_x11_is_working
        default_interface_ip    #getting default system IP
        
        #gem_selenium_client #do we still need it?

        OLD_REVISION=0 #initializing it to lowest possible value
        
        while true; do
            job_ask >> /var/log/mor/n  #exits if no jobs available
            touch "$TEST_RUNNING_LOCK"  #creating the lock
            #restart_xvfb_if_not_enough_ram &
            if [ "$OLD_REVISION" != "$TEST_REVISION" ]; then
                upgrade_mor_install_scripts
                prepare_gui
                actions_before_new_revision
                check_if_gui_accessible 1 3 EXIT
            else
                actions_before_new_test &            # house cleaning, etc.
            fi

            prepare_db
            
            wait        #waiting till all threads completes their work
            #initialize_gui_quick &
            convert_and_run_rb
            OLD_REVISION="$TEST_REVISION"
        done; #/while
elif [ "$firstParam" == "-add" ]; then
    report "Adding node to cluster of brain nodes" 3
    #-----------------------------------------------
    touch /tmp/.mor_test_is_running
    n_update_source
    unlink /bin/n
    ln -s /usr/src/mor/test/node2/node.sh /bin/n
    chmod +x /bin/n
    #echo "*/1 * * * * root /bin/sh -l /bin/n -a >> /var/log/mor/n" > /etc/cron.d/test
    
    echo "*/1 * * * * root /bin/sh -l /usr/src/mor/test/cluster1/x5/mor_test_run.sh -a >> /var/log/mor/test_system" > /etc/cron.d/test
    if [ `ps aux | grep asterisk | grep -v grep | wc -l` != 2 ]; then
       /etc/init.d/asterisk stop
       killall -9 asterisk
       killall -9 safe_asterisk
       service asterisk start
    fi
    
    echo "*/5 * * * * root wget -o /dev/null -O /dev/null http://brain.kolmisoft.com/api/node_ping" > /etc/cron.d/brain
    
    rm -rf /tmp/.mor_test_is_running
    report "done, node added to brain cluster" 3

elif [ "$firstParam" == "-remove" ]; then
    report "Removing node from cluster" 3
    CURRENT_PROCESS=$$
    ps aux | grep "ruby\|\/bin\/n\|firefox\|Xvfb\|java" | awk '{print $2}' | grep -v $CURRENT_PROCESS | xargs kill  &> /dev/null #killing all ruby processes (possibly running tests?)
    /usr/src/mor/test/stop_tests.sh
    touch /tmp/.mor_test_is_running
    
    rm -rf /etc/cron.d/brain
    rm -rf /etc/cron.d/test
    report "done, node removed from brain cluster. Now use command n -l MOR_VERSION   OR     c -l   to prepare CRM" 3

elif [ "$firstParam" == "n" ]; then
    tail -f /var/log/mor/test_system
    
elif [ "$firstParam" == "one" ]; then
    # About: This tool allows to run single test on selenium server
    default_interface_ip
    TEST_NAME=`echo "$secondParam" | awk -F "/" '{print $NF}'`
    sed -e 's/<\/thead><tbody>/<\/thead><tbody>\n<tr>\n<td>setTimeout<\/td>\n<td>60000<\/td>\n<td><\/td>\n<\/tr>/g' $secondParam  > /tmp/"$TEST_NAME.html"
    generate_suite_file $TEST_NAME $secondParam
    copy_selenium_to_ram_if_not_present
    DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /dev/shm/selenium-server-standalone-$SELENIUM_SERVER_VERSION.jar -singleWindow -userExtensions /usr/src/mor/test/files/selenium/user-extensions.js -htmlSuite "*firefox" "http://$DEFAULT_IP" "/tmp/suite.html" "/home/mor/public/rezultatas.html"
    report "Testing finised. You can find results by visiting address: http://$DEFAULT_IP/billing/rezultatas.html" 3
elif [ "$firstParam" == "-v" ]; then
   gui_revision_check &> /dev/null #getting current version of GUI, provides variable: MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS
   echo "MOR GUI version: $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
   echo "MOR GUI revision: $GUI_REVISION_IN_SYSTEM"
   echo "node.sh version: $N_VERSION";
elif [ "$firstParam" == "-f" ]; then
    # this is a place for one time fixes
    fix_pdf_wrapper
    disable_services
    fix_update_rc_local
    rm -rf /var/log/mor/assets_log /etc/cron.d/mor_ad  /etc/cron.d/mor_daily_actions /etc/cron.d/mor_hourly_actions  /etc/cron.d/mor_monthly_actions /etc/cron.d/mor_minute_actions  /etc/httpd/conf.d/mod_fcgid_include.conf  # force to recompile assets + deletes not needed crontabs
    etc_hosts
    cleanup_various_files
    
    #backup scripts fix
    cp -fr /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/mor_install_functions.sh
    cp -fr /usr/src/mor/sh_scripts/backup/make_restore.sh /usr/local/mor/make_restore.sh
    cp -fr /usr/src/mor/sh_scripts/backup/make_backup.sh /usr/local/mor/make_backup.sh

elif [ "$firstParam" == "status" ]; then
    n_status

elif [ "$firstParam" == "bigdb" ]; then
    service mysqld stop
    killall -9 mysqld mysql
    rm -rf /var/lib/mysql/*
    unlink /var/lib/mysql
    mkdir -p /var/lib/mysql
    chown -R mysql: /var/lib/mysql
    sed -i 's%/dev/shm/mysql%/var/lib/mysql%g' /etc/my.cnf
    service mysqld start
    mysql -e "DROP database mor"
    mysql < /usr/src/mor/db/init.sql
    mysql -e "CREATE database tickets;"
    
    report "Node is ready! Go and import your big MOR DB :)" 3
    
elif [ "$firstParam" == "tail" ]; then
    tail -f /var/log/httpd/* /home/mor/log/* /tmp/mor_crash.txt

elif [ "$firstParam" == "ctail" ]; then
    tail -f /var/log/httpd/* /home/tickets/log/*
    
elif [ "$firstParam" == "dbcheck" ]; then
    mysql mor -e "SELECT * FROM conflines where name='DB_Update_From_Script'"

elif [ "$firstParam" == "cdb" ]; then
    LATEST_GUI_REV_DB=`ls -1 /dev/shm/pool/tickets | sort | tail -n 1`
    mysql tickets < /dev/shm/pool/tickets/$LATEST_GUI_REV_DB/*.sql
    report "Imported DB of MOR: tickets, DB Revision: $LATEST_GUI_REV_DB" 3    

elif [ "$firstParam" == "db" ]; then
    mor_gui_current_version
    
    if [ ! -d "/dev/shm/pool/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS" ]; then
        report "There are no DBs cached for this version" 1
        exit 0  
    fi
    
    LATEST_GUI_REV_DB=`ls -1 /dev/shm/pool/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS | sort | tail -n 1`
    
    MOR_GUI_CURRENT_REV=`svn info /home/mor | grep 'Last Changed Rev' | awk '{print $NF}'`
    mysql mor < /dev/shm/pool/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS/$LATEST_GUI_REV_DB/*.sql
    
    mkdir -p /dev/shm/sessions/
    chmod 777 -R /dev/shm/sessions/
    rm -rf /dev/shm/sessions/*
    report "Imported DB of MOR: $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS, GUI revision: $LATEST_GUI_REV_DB" 3    

# DB management on dev.kolmisoft.com

# n DROP ticket_number
elif [ "$firstParam" == "DROP" ] || [ "$firstParam" == "drop" ]; then
    DB_TO_DROP="$secondParam"

    check_if_variable_is_int "$DB_TO_DROP"
    if [  IS_INTEGER = "FALSE" ]; then
        report "Please supply ticket number as integer" 1
        exit 1
    fi

    ssh root@dev.kolmisoft.com -p 6666  "mkdir -p /dev/shm/db_load_requests; echo 'DROP' > /dev/shm/db_load_requests/$DB_TO_DROP"
    if [ "$?" == "0" ]; then
        report "Added task for dev.kolmisoft.com to DROP DB $DB_TO_DROP" 3
    else
        report "Failed to add task for dev.kolmisoft.com to DROP DB $DB_TO_DROP" 3
    fi

    #----- Let developer know when his task will be completed -------
    JOB_DONE="FALSE"
    while [ "$JOB_DONE" == "FALSE" ]; do
        sleep 5
        JOB_DONE=`ssh root@dev.kolmisoft.com -p 6666 "if [ -f '/dev/shm/db_load_requests/$DB_TO_DROP' ]; then echo FALSE; else echo TRUE; fi"`
        report "`date` DB DROP completed: $JOB_DONE" 3
    done


elif [ "$firstParam" == "IMPORT" ] || [ "$firstParam" == "import" ]; then
    IMPORT_DB="$secondParam"

    check_if_variable_is_int "$IMPORT_DB"
    if [  IS_INTEGER = "FALSE" ]; then
        report "Please supply ticket number as integer" 1
        exit 1
    fi

    ssh root@dev.kolmisoft.com -p 6666 "mkdir -p /dev/shm/db_load_requests; echo 'IMPORT' > /dev/shm/db_load_requests/$IMPORT_DB"
    if [ "$?" == "0" ]; then
        report "Added task for dev.kolmisoft.com to IMPORT DB $IMPORT_DB" 3
    else
        report "Failed to add task for dev.kolmisoft.com to IMPORT DB $IMPORT_DB" 3
    fi  

    #----- Let developer know when his task will be completed -------
    JOB_DONE="FALSE"
    while [ "$JOB_DONE" == "FALSE" ]; do
        sleep 5
        JOB_DONE=`ssh root@dev.kolmisoft.com -p 6666 "if [ -f '/dev/shm/db_load_requests/$IMPORT_DB' ]; then echo FALSE; else echo TRUE; fi"`
        report "`date` DB import completed: $JOB_DONE" 3
    done
# n list  - lists all available databases that are already imported
elif [ "$firstParam" == "list" ] || [ " $firstParam" == "LIST" ]; then
    echo "Already imported databases in dev.kolmisoft.com"
    ssh root@dev.kolmisoft.com -p 6666 'mysql -e "show databases" | grep -v "^performance_schema$\|^mor_test$\|^mysql$\|^test$\|^Database$\|^information_schema$"'

elif [ "$firstParam" == "priority" ]; then
    echo "Listing tasks priority"
    ssh root@dev.kolmisoft.com -p 6666 'ls -t1 /dev/shm/db_load_requests | tac'

# n database  - configures GUI to use specific DB
elif [ "$firstParam" == "database" ] || [ " $firstParam" == "DATABASE" ]; then

    PREPARE_DB="$secondParam"
    check_if_variable_is_int "$PREPARE_DB"

    if [ "$PREPARE_DB" == "mor" ] || [ "$PREPARE_DB" == "default" ]; then
        reconfigure_db mor localhost
        report "Node configured to use local MOR DB" 3
        exit 0
    fi

    if [  IS_INTEGER = "FALSE" ]; then
        report "Please supply ticket number as integer" 1
        exit 1
    fi

    reconfigure_db "$PREPARE_DB" dev.kolmisoft.com
    report "Node configured to use DB: $PREPARE_DB on dev.kolmisoft.com" 3
elif [ "$firstParam" == "mysql" ]; then
    mysql_connect_data_v2 
    /usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" 

elif [ "$firstParam" == "ror" ] || [ "$firstParam" == "ROR" ]; then

    PATH_TO_CHECK="$secondParam"
    source "/usr/local/rvm/scripts/rvm" &> /dev/null


    if [ ! -d "$PATH_TO_CHECK" ] && [ ! -f "$PATH_TO_CHECK" ]; then
        PATH_TO_CHECK="/home/mor/app"
    fi

    if [ `gem list | grep reek | wc -l` == "0" ]; then
        gem install reek
        if [ "$?" != "0" ]; then report "Reek gem install failed" 1; exit 1; fi
    fi

    rvm `cat /dev/shm/last_used_ruby_version` do reek "$PATH_TO_CHECK"

#---- HELP
elif [ "$firstParam" == "help" ] || [ "$firstParam" == "-h" ] || [ "$firstParam" == "-help" ] || [ "$firstParam" == "--help" ] || [ "$firstParam" == "--h" ]; then
    echo "Help:"
    echo "n db - reloads only database quickly"
    echo "n -l [x3, x4, x5, 12.126 11, 10, 9, 8] - prepares required MOR version"
    echo "n bigdb - by default DB is stored in RAM which is limited to 100 MB, when this command is launched - DB is stored in HDD normally and you can import bigger databases"
    echo "n ror PATH - runs ruby quality check tests"
fi
 
