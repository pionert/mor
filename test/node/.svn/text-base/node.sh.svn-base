#! /bin/bash

N_VERSION="1.4"

#--- Important ---

BRAIN="brain2"      #  /etc/hosts must be configured to contain hostname entry like this: 192.168.0.13 brain2

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
#--- 

#   Author:     Mindaugas   Mardosas
#   Company:    Kolmisoft
#   Year:       2011
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
#       n -l [8, 9, 10, 11, trunk]              # upgrade/downgrade to specified MOR version
#       n -l [8, 9, 10, 11, trunk] [REVISION]   # upgrade/downgrade to specified MOR version AND revision
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

#-------- Includes -------------------------
if [ -f /usr/src/mor/test/node/node_functions.sh ]; then
    . /usr/src/mor/test/node/node_functions.sh
else
    . /root/node_functions.sh
fi

. /usr/src/mor/test/framework/bash_functions.sh
#============SETTINGS========================
LAST_REVISION_FILE="/usr/local/mor/test_environment/last_revision"; #here we will track completed tests
TEST_RUNNING_LOCK="/tmp/.mor_test_is_running";
#=============================MAIN============================

#=======Global variables=============
dbVersionsToKeep=20;        # this amount of db dumps will be kept in /var/lib/mysql_pool/$TEST_MOR_VERSION/ dir
#====================================

_mor_time;

if [ "$firstParam" == "-l" ]; then
    upgrade_mor_install_scripts
    /etc/init.d/httpd stop
    #setting variables to later take advantage of existing functions and prepare a required GUI
    #====== MOR/CRM GUI prepare
        #====== GUI version: 0.8, 9, 10, trunk or crm
        if [ -n "$secondParam" ]; then  #string is not null;  "$secondParam" - MOR version
            if [ "$secondParam" == "11" ]; then
                TEST_MOR_VERSION="trunk"
            else
                TEST_MOR_VERSION="$secondParam"
            fi
        elif [ "$0" == "c" ] || [ "$0" == "/bin/c" ] ; then       #second one is needed when debugging with /bin/sh -x /bin/mcrm
            #when the script is invoked via symlink: c -l   this part will be executed
            TEST_MOR_VERSION="crm"
        else
            mor_gui_current_version &> /dev/null
            TEST_MOR_VERSION=$MOR_VERSION_YOU_ARE_TESTING   #current MOR GUI version in the system: 0.8, 9, 10, trunk, etc
        fi
        #====== Revision for MOR or crm
        if [ -n "$thirdParam" ]; then   #if revision specified - set variable to get that version of GUI
            TEST_REVISION="$thirdParam";
        elif [ "$0" == "c" ] || [ "$0" == "/bin/c" ] ; then       #second one is needed when debugging with /bin/sh -x /bin/mcrm
            #when the script is invoked via symlink: c -l   this part will be executed
            TEST_REVISION=`svn info http://svn.kolmisoft.com/crm/trunk | grep Revision | awk '{print $2}'`
        else                            #if revision is not specified - set variable to get the latest revision
            gui_revision_check &>  /dev/null
            TEST_REVISION=$GUI_REVISION_IN_REPOSITORY   #get the latest MOR GUI revision
        fi

        echo "Prepairing GUI and DB: $TEST_MOR_VERSION Revision: $TEST_REVISION";

        prepare_gui

        echo "Prepairing DB for $TEST_MOR_VERSION Revision: $TEST_REVISION"
        prepare_db
        echo "Done. Prepaired: $TEST_MOR_VERSION Revision: $TEST_REVISION";
        change_email_in_environment_rb
        /etc/init.d/httpd start
elif [ "$firstParam" == "-a" ]; then
        is_another_test_still_running #exit if another instance is running
        start_selenium_server   # check if selenium is started, if not - starts
        chmod 777 /etc/ssh/sshd_config
        while true; do
            job_ask #exits if no jobs available
            touch "$TEST_RUNNING_LOCK"  #creating the lock
            #--- git-------
#                git_check_and_install
                gem_rest_client_check_and_install
#                checkout_brain_script
            #---- /git-----
            upgrade_mor_install_scripts
            default_interface_ip    #getting default system IP
            prepare_db
            prepare_gui
            convert_and_run_rb
        done; #/while
elif [ "$firstParam" == "-v" ]; then
   gui_revision_check &> /dev/null #getting current version of GUI, provides variable: MOR_VERSION_YOU_ARE_TESTING
   echo "MOR GUI version: $MOR_VERSION_YOU_ARE_TESTING"
   echo "MOR GUI revision: $GUI_REVISION_IN_SYSTEM"
   echo "node.sh version: $N_VERSION";
fi

