#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if server hardware parameters, OS and DNS are OK to install MOR. Parameters being checked:
 
#

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------


#----- FUNCTIONS ------------
isCentos()
{
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if a system is running CentOS

    local _centos=`cat /etc/redhat-release | grep -o CentOS`
    if [ "$_centos" == "CentOS" ]; then
        return 0;
    else
        return 1;
    fi
}
#----------------------------
totalRAM()
{
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if a system has enough RAM

    local totalRAM=`free -m | (read; cat) | head -n 1 | awk '{print $2}'`;
    if [ "$totalRAM" -lt "2048" ]; then
        return 1;
    else
        return 0;
    fi
}

report()
{
    # Author: Mindaugas Mardosas
    # This function is used for displaying output with color status.
    # Usage:
    #    report "some text" [0-5]
    #
    # The function returns the same parameter it received.
    #
    # This function accepts these arguments:
    #   $1 - text to display
    #   $2 - send status manually
    #   $2 or $3 - "FAILED" #causes not to print [OK] blabblabla. In other words if the functions has to report OK - it will print nothing
    #
    # Internal variable that can be used outside:
    #   ALL_OK  - this variable can be used to track if all tests from that group went ok. Read more about this variable usage in Example 5
    # returns/accepts these codes:
    #
    #   0 - ok
    #   1 - failed
    #   2 - warning
    #   3 - notice
    #   4 - fixed
    #   5 - overwritten
    #   6 - RED BLINKING TEXT
    #   7 - echo text to screen. Text with this status will not be printed when -compact or -c settings will be used when running the testing framework
    #
    # Usage examples:
    #    Example 1:
    #               report "some output" 1         #would report "FAILED" and return 1
    #
    #               would produce similar output and return 1:
    #               FAILED         some output
    #
    #    Example 2:
    #               report "some output" 0         #would report "OK" and return 0
    #
    #               would produce similar output and return 0:
    #               OK             some output
    #
    #    Example 3 (command combine):
    #        Here is a simple command that returns 1 that states failure and 0 when a match is found (success):
    #           [root@localhost ~]# grep erdtfyguhjiok /etc/passwd #grep will not find anything and return 1
    #           [root@localhost ~]# echo $?
    #           1
    #           [root@localhost ~]#
    #        When using such simple commands or functions which return 0 on OK and 1 on failure you can leave the second parameter not filled:
    #            grep erdtfyguhjiok /etc/passwd
    #            report "Grep command status"
    #
    #            would produce similar output and this time return 1:
    #            FAILED         Grep command status
    #
    #    Example 4:
    #               report "some output" 0 FAILED
    #
    #               would produce no output at all and return 0:
    #
    #    Example 5:
    #               Now we will use ALL_OK variable to display some summary result about 3 tests:
    #                   ALL_OK=0    #resetting the variable
    #                   report "some output" 0 FAILED
    #                   report "some output" 0 FAILED
    #                   report "some output" 0 FAILED
    #
    #                   if [ "$ALL_OK" == "0" ]; then
    #                       echo "All 3 tests passed successfully"
    #                   else
    #                       echo "One or more tests failed"
    #                   fi
    #
    #------------------
    if [ "$2" != "" ]; then
        result=$2;
    else                    # 2nd parameter is not available - use last command status
        result=$?;
    fi

    #------------------
    if [ -f "/tmp/.mor_global_test-fix_framework_variables" ]; then #including global test-fix framework variables if any of them are available
        source /tmp/.mor_global_test-fix_framework_variables
    fi


    if [ "$result" == "0" ]; then
        if [ "$3" == "FAILED" ]  ; then return 0; fi  #causes not to print [OK] blabblabla


        if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then                     #if compact option was passed - this message will not be printed
            echo -e "\E[32m OK \E[32m\033[0m\\t\t$1";
        fi

        return 0;
    else
        ALL_OK=1    #some checks failed

        if [ "$result" == "1" ]; then
            echo -e "\E[31m FAILED \E[31m\033[0m\\t$1";
            return 1;
        elif [ "$result" == "2" ]; then
            echo -e "\E[33m WARNING! \E[33m\033[0m\\t$1";
            return 2;
        elif [ "$result" == "3" ]; then
            echo -e "\E[33m NOTICE \E[36m\033[0m\\t$1";
            return 3;
        elif [ "$result" == "4" ]; then
            echo -e "\E[34m FIXED \E[34m\033[0m\\t\t$1";
            return 4;
        elif [ "$result" == "5" ]; then
            echo -e "\E[34m Overwritten \E[34m\033[0m\\t$1";
            return 5;
        elif [ "$result" == "6" ]; then
            if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then                 #if compact option was passed - this message will not be printed
                echo -e "\n\n\n\E[5m\E[31m$1\E[31m\033[0m\E[25m\\n\n";
            fi
            return 6;
        elif [ "$result" == "7" ]; then
            if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then                 #if compact option was passed - this message will not be printed
                echo -e "$1";
            fi
            return 7;
        fi
    fi
}

hdd_space_in_dir()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This functions gets total space in K
    #
    #   Arguments:
    #       $1  -   dir to check free space
    #       $2  -   space in K
    #   Example:
    #   hdd_space_in_dir /  "10485760"      #10485760 - 10 GB

    local firstParam="$1"
    local secondParam="$2"

    DEBUG=0     #   0 - off, 1 - on

    FREE_SPACE=`df -P $firstParam | (read; awk '{print $4}')` &> /dev/null
    if [ "$DEBUG" == "1" ]; then echo "FREE SPACE: $FREE_SPACE"; fi
    if [ "$FREE_SPACE" -lt "$secondParam" ]; then
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 1"; fi
        return 1;   #FAILED there is less space than specified in the second parameter
    else
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 0"; fi
        return 0;   #OK - there is more space when specified in 2nd parameter
    fi
}


dns_settings()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This functions gets total space in K
    #

    local IP=`resolveip -s svn.kolmisoft.com`
    if [ "$IP" == "213.197.141.162" ]; then
        return 0
    else
        return 1
    fi
}
#--------MAIN -------------


#---------OS-----------------
isCentos
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    report "CentOS Operating System" 0
else
    report "CentOS Operating System, get CentOS here: http://www.centos.org/" 1
fi

#-------- DNS----------------
dns_settings
if [ "$?" == "0" ]; then    #failed
    report "DNS settings in /etc/resolv.conf" 0
else
    report "DNS settings in /etc/resolv.conf" 1
fi
#---------RAM-----------------

totalRAM
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    report "RAM memory" 0
else
    report "You should install at least 2 GB of RAM for your server" 1
fi
#-------- HDD ------------------

hdd_space_in_dir / "10485760"       #check if less than 10 GB
if [ "$?" == "1" ]; then    #failed
    report "There is not enough free space in / partition, ensure that / partition would have 10 GB or more of free space" 1
    echo
    df -h
else
    report "HDD Allocation for /" 0
    exit 0
fi



