#! /bin/sh

#   YEAR: 2010
#   Author: Mindaugas Mardosas
#   Company: http://www.kolmisoft.com
#   About:  This script launches various repairing scripts for MOR VoIP Billing platform

. /usr/src/mor/test/framework/bash_functions.sh

# check if we have M2 or X5 ++, if so - they have their own test scripts and this one will terminate
mor_gui_current_version
mor_version_mapper $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "150" ]; then
    report "M2/X5++ are present in the server, use their own test-fix scripts from their folders. ABORTING"
    exit 0
fi


#--- Settings -----
export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

rm -rf /tmp/.mor_global_test-fix_framework_variables    #HOUSE cleaning
#--- Arguments ----
if [ "$1" == "-compact" ] || [ "$1" == "-c" ]; then   #if this option will be received the script produces less output. "OK" reporting scripts will not be displayed in the screen
    echo 'COMPACT_OUTPUT="COMPACT"' >> /tmp/.mor_global_test-fix_framework_variables     # updating GLOBAL test-fix framework variables
    COMPACT_OUTPUT="COMPACT"    #for this script internal use
fi
#------------------
if [ "$1" != "-compact" ] && [ "$1" != "-c" ]; then
    /usr/src/mor/sh_scripts/kolmisoft_logo_txt.sh
fi

if [ "$1" == "help" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "--h" ]; then
    set -u
    clear
    echo -e "\nInformation:"
    echo -e "\tMOR Softswitch test-fix tool\n"
    echo -e "Options:"
    echo -e "\t-h\t This help menu\n"
    echo -e "Usage:\n"
    echo -e "\tJust run the script: $0\n\n"
    echo -e "\tArguments:\n"
    echo -e "\t\tNo arguments: will produce output for every test script\n"
    echo -e "\t\t-compact or -c: will output only failed tests names. FIXED, NOTICE, FAILED and other status reporting scripts will be displayed\n"
    exit 0;
fi

#========= OPTIONS =============
DEBUG=0 #{ 1- ON, 0 - OFF}

lockfile="/tmp/test-fix.lock"
report_dir="/var/log/mor/test-fix-reports"
TEST_DIR="/usr/src/mor/test/scripts"

#--initialization--
mkdir -p $report_dir
test_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
report="$report_dir/test-fix_$test_time.txt"
if [ ! -d "$TEST_DIR" ]; then echo "No tests are available. Contact the Kolmisoft team"; fi

#------------------

#========= MAIN ================
if [ -f "/tmp/test-fix.lock" ]; then
   echo -e "\n\nFailed to acquire lockfile: $lockfile"
   echo "That means that test-fix script is already launched"
   echo -e "Held by $(cat $lockfile)\n\n"
   exit 0
fi
#-------------

if [ -d /usr/src/mor ]; then
    svn update /usr/src/mor &> /dev/null
fi

echo -e "TEST START TIME: $test_time" &> $report
find $TEST_DIR -type f \( -iname "*.sh" -or -iname "*.rb" -or -iname "*.py" \) | sort > /tmp/.mor_components_to_check

filecontent=( `cat "/tmp/.mor_components_to_check" `)
for testas in "${filecontent[@]}"
do
    if [ -d "$testas" ]; then continue; fi  #if it is a directory - move on to the next test in list
    if [ "$DEBUG" == "1" ]; then echo "Proceeding test: $testas"; fi

    #--------- DON'T TOUCH - very sensitive ---------
    if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
    then


        trap "echo 'NEVER DO THAT AGAIN! YOU WILL BREAK MOR SYSTEM, if have not done so already....' ; rm -f $lockfile; exit 1" INT TERM EXIT
        LANGUAGE=`echo "$testas" | awk -F"." '{print $NF}'`

        echo "$testas" >> $report

        if [ "$DEBUG" == "1" ]; then echo "TEST Language:$LANGUAGE"; fi

        if [ "$LANGUAGE" == "rb" ]; then
            /usr/bin/ruby -gems $testas 2>&1 | tee -a $report
        elif [ "$LANGUAGE" == "sh" ]; then
            /bin/sh $testas  2>&1 | tee -a $report
        else
            echo -e "Unknown test language: $LANGUAGE. Skipping this test, will proceed with others"
            continue
        fi

        echo -e "----\n" >> $report;  #spacing between tests

        rm -f "$lockfile"
        trap - INT TERM EXIT
    else
       echo "Failed to acquire lockfile: $lockfile"
       echo "That means that test-fix script is already launched"
       echo "Held by $(cat $lockfile)"
       exit 0;
    fi
    #--------- DON'T TOUCH - very sensitive ---------
done
#-------- END ----------------------
test_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then
    echo -e "\n\nTEST END TIME: $test_time" 2>&1 | tee -a $report
    echo -e "\n\nlog was saved to: $report"
fi
