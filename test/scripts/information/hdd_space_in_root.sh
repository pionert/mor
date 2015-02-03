#! /bin/sh

#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2012
#   About:  This script checks for available disk space in / dir. If free space is less than 10 GB script asks user a confirmation to ignore and continue if FIRST_INSTALL parameter is passed to this script

#   Arguments:
#       $1  -   "FIRST_INSTALL"

#   Examples:
#       ./hdd_space_in_root.sh FIRST_INSTALL    #   Asks for confirmation
#       ./hdd_space_in_root.sh                  #   Just reports status {OK, FAILED}, no confirmation

FIRST_INSTALL="$1" #taking parameters

. /usr/src/mor/test/framework/bash_functions.sh

#----- FUNCTIONS ------------
hdd_space_in_dir()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This functions gets total free space in K
    #
    #   Arguments:
    #       $1  -   dir to check free space
    #       $2  -   space in K
    #   Example:
    #   hdd_space_in_dir /  "10485760"      #10485760 - 10 GB

    DEBUG=0     #   0 - off, 1 - on


    FREE_SPACE=`df -P / | (read; awk '{print $4}')` &> /dev/null
    if [ "$DEBUG" == "1" ]; then echo "FREE SPACE: $FREE_SPACE"; fi
    if [ "$FREE_SPACE" -lt "$2" ]; then
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 1"; fi
        return 1;   #FAILED there is less space than specified in the second parameter
    else
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 0"; fi
        return 0;   #OK - there is more space when specified in 2nd parameter
    fi
}

#--------MAIN -------------
if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
    hdd_space_in_dir / "4718592"       #check if less than 4.5 GB
    if [ "$?" == "1" ]; then    #failed
        echo "There is less space than 4.5GB in / dir, it is very important to have more DISK SPACE than that. If you REALLY know what you are doing - please type 'CONTINUE!' and press ENTER"

        read INPUT;
        if [ "$INPUT" != "CONTINUE" ]; then
            echo "Go and fix DISK space problem, after that you can try to INSTALL AGAIN";
            exit 1;
        else
            echo "You have been warned!"
        fi
        echo
    fi
else        
    hdd_space_in_dir / "1048576"       #check if less than 1 GB
    if [ "$?" == "1" ]; then    #failed
        echo
        df -h
        echo
        report "HDD DISK SPACE IN / dir is less than 10 GB !!! Please add another disk, check your partition table or delete uneccessary files, or you will get in trouble!" 1
        exit 1
    else
        report "HDD DISK SPACE IN / dir" 0
        exit 0
    fi
fi

