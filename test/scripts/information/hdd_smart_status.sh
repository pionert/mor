#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks hdd smart status for errors
#
# Returns:
#   0   -   All is OK
#   1   -   one or more hard disks s.m.a.r.t reported errors
#
# Parameters:
#      
#   $1 - FIRST_INSTALL
#
. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------
FIRST_INSTALL="$1"
#----- FUNCTIONS ------------
check_for_simfs()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function detecs if simfs is present, which indicates that the host is running on openvz.
    #
    simfs_detected=`df -h | grep simfs | wc -l`
    return 0;
}
check_smart_hard_drives()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks hdd smart status for errors
    #
    # Returns:
    #   0   -   If all is OK
    #   1   -   If one or more hard drives are failing

    if [ ! -f /usr/sbin/smartctl ]; then
        report "Installing smartmontools" 3
        yum -y install smartmontools &> /dev/null
        if [ "$?" != "0" ]; then
            report "Failed to issue this command: yum -y install smartmontools" 1
            return 0
        fi
    fi

    /usr/sbin/smartctl --help &> /dev/null
    if [ "$?" != "0" ]; then  
        exit 0  # some virtualization technology detected which does not allow to use this command
    fi

    ls -1 /dev/sd* 2> /dev/null | grep -o "[a-z,/]*" | uniq | while read hdd_path; do 
        SMART_REPORTED_ERRORS_COUNT=`smartctl -l error $hdd_path | grep "Count:" | awk -F"(" '{print $1}'`
        if [ "$SMART_REPORTED_ERRORS_COUNT" != "" ]; then
            report "HDD S.M.A.R.T reported errors on $hdd_path" 1
            echo -e "\n\n\nMore information about this failing hard disk:\n\n\n/usr/sbin/smartctl -l error $hdd_path\n\n"
            /usr/sbin/smartctl -l error $hdd_path
            echo -e "\n\n\n /usr/sbin/smartctl -i $hdd_path\n\n\n "
            /usr/sbin/smartctl -i $hdd_path 
            echo -e "\n\n\n"
            report "\n\n\nCritical Error - your hard drive is faulty. Please check other hard drives using the commands above\n\n\n" 6
            return 1
        fi
    done
}
#--------MAIN -------------

check_for_simfs
if [ "$simfs_detected" == "1" ]; then
    exit 0; #test is not needed
fi

check_smart_hard_drives
if [ "$?" == "1" ] && [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
    echo -ne "Please press CTRL+C to cancel, or press ENTER to ignore this warning and continue (NOT RECOMMENDED)."
    read a;
    exit 1;
fi

