#! /bin/sh

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
gui_bottom_check()
{
    apache_is_running
    if [ "$?" != "0" ]; then    #apache is not running so the test will not succeed
        exit 0
    fi

    rm -rf /tmp/.laikinas
    mkdir -p /tmp/.laikinas
    cd /tmp/.laikinas
    wget --no-check-certificate -O login -c http://127.0.0.1/billing &> /dev/null

    MOR_VERSION_NUMBER_IN_BOTTOM=`grep -A 6 "left-element" login | grep -o "MOR.*" | awk '{print $2}'`
    mor_gui_current_version
    if [ "$MOR_VERSION_NUMBER_IN_BOTTOM" == "" ]; then
        report "User has modified GUI bottom himself" 3
        return 0;
    elif [ "$MOR_VERSION_NUMBER_IN_BOTTOM" == "0.8" ]; then
        if [ "$MOR_VERSION_YOU_ARE_TESTING" == "9" ]; then      # 0.8 and 9 does not match
            report "GUI bottom has to be changed to 'MOR 9'" 1
            return 1
        fi
    elif [ "$MOR_VERSION_NUMBER_IN_BOTTOM" == "9" ]; then       # 9=9
        report "GUI bottom version number OK" 0
        return 0
    fi
}
#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

gui_bottom_check

report "GUI bottom version number: $MOR_VERSION_NUMBER_IN_BOTTOM" 3