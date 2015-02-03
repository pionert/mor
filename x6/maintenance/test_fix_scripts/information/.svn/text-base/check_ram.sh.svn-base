#! /bin/sh

#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2012
#   About:  Sript checks and reports it server has enough RAM memory. "FIRST_INSTALL" option allows to continue after confirmation only. Different amounts can be speficied to be checked on regular and "FIRST_INSTALL" mode.

#   Arguments:
#       $1  -   "FIRST_INSTALL"

#   Examples:
#       ./ram.sh FIRST_INSTALL    #   Asks for confirmation
#       ./ram.sh                  #   Just reports status {OK, FAILED}, no confirmation

AMOUNT="3900"
AMOUNT_FIRST_INSTALL="3900"
FIRST_INSTALL="$1" #taking parameters

. /usr/src/mor/x6/framework/bash_functions.sh

#----- FUNCTIONS ------------
total_ram()
{
    #   Author: Mindaugas Mardosas, Nerijus Sapola
    #   Year:   2012
    #   About:  This functions gets total free space in K
    #
    #   Arguments:
    #       $1  -   space in MB
    #   Example:
    #   total_ram /  "4096"      #4096 - 4 GB

    DEBUG=0     #   0 - off, 1 - on

    RAM_SPACE=`free -m | grep Mem: | awk '{print $2}'` &> /dev/null
    if [ "$DEBUG" == "1" ]; then echo "TOTAL RAM: $RAM_SPACE"; fi
    if [ "$RAM_SPACE" -lt "$1" ]; then
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 1"; fi
        return 1;   #FAILED there is less space than specified in parameter
    else
        if [ "$DEBUG" == "1" ]; then echo "RETURN: 0"; fi
        return 0;   #OK - there is more space when specified in parameter
    fi
}

#--------MAIN -------------
if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
    total_ram $AMOUNT_FIRST_INSTALL       #check if less than AMOUNT_FIRST_INSTALL
    if [ "$?" == "1" ]; then    #failed
        echo "There is less then $AMOUNT_FIRST_INSTALL MB of RAM. If you REALLY know what you are doing - please type 'CONTINUE!' and press ENTER"

        read INPUT;
        if [ "$INPUT" != "CONTINUE" ]; then
            echo "Please add more RAM to server, after that you can try to INSTALL AGAIN";
            exit 1;
        else
            echo "You have been warned!"
        fi
        echo
    fi
else
    total_ram $AMOUNT       #check if less than AMOUNT
    if [ "$?" == "1" ]; then    #failed
        report "Server has $RAM_SPACE MB of RAM" 3
        exit 1
    else
        report "RAM is ok" 0
        exit 0
    fi
fi
