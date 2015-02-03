#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This scripts reports if default Asterisk settings are found in /etc/asterisk/sip.conf
#
#   # This config file was taken as correct one: http://trac.kolmisoft.com/trac/attachment/ticket/2596/sip.conf
#
#   allowtransfer=no
#   alwaysauthreject=yes
#   videosupport=yes
#   rtptimeout=60
#   rtpholdtimeout=300
#   t38pt_udptl=yes
#   t38pt_rtp=no
#   t38pt_tcp=no
#   rtcachefriends=yes
#   rtsavesysname=yes
#   rtupdate=yes
#   ignoreregexpire=yes

# IF YOU HAVE TO CHECK OTHER SETTING, ADD if it missing, CHANGE if it is different than defined - just add that setting with a value WITHOUT SPACES to the "MOR_SETTINGS_LIST" array

#

. /usr/src/mor/x5/framework/bash_functions.sh

#------
check_fix_cfg()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks takes a list of options and checks the configuration file.
    #
    #   Arguments:
    #       $1   -   a path to configuration file
    #       $SETTINGS_LIST   -   a global variable with an array of configs to check
    #   Return:
    #       0   -   All settings were already OK
    #       1   -   Failed to change one of more settings
    #       Global variable $ONE_OF_THE_OPTIONS_WERE_CHANGED - {0 - none settings were changed,  1 - one or more settings were changed}
    #
    #   Usage Examples:
    #       MOR_SETTINGS_LIST==("allowtransfer=no" "alwaysauthreject=yes" "videosupport=yes" "rtptimeout=60" "rtpholdtimeout=300" "t38pt_udptl=yes" "t38pt_rtp=no" "t38pt_tcp=no" "rtcachefriends=yes" "rtsavesysname=yes" "rtupdate=yes"  "ignoreregexpire=yes")
    #       check_fix_cfg   /etc/asterisk/sip.conf
    #
    # -----local variables -----
    local CONFIG_PATH="$1"
    #---------------------------
    
    ONE_OF_THE_OPTIONS_WERE_CHANGED=0   #0 - none options were changed. 1 - some options were changed

    for element in $(seq 0 $((${#MOR_SETTINGS_LIST[@]} - 1)))   #will go throw the config and check against every setting mentioned in variable MOR_SETTINGS_LIST
    do
        local variable_name=`echo ${MOR_SETTINGS_LIST[$element]} | awk -F"=" '{print $1}'`
        check_if_setting_match $CONFIG_PATH  "$variable_name" "${MOR_SETTINGS_LIST[$element]}"
        STATUS="$?";
        if [ "$STATUS" == "0" ]; then
            report "${MOR_SETTINGS_LIST[$element]}" 0
            continue;
        elif [ "$STATUS" == "1" ]; then             #failed, setting did not matched
            CHECK_IGNORE_SETTING=`echo ${MOR_SETTINGS_LIST[$element]} | awk -F"=" '{print $1}'`;
            if [ -f "/etc/asterisk/.mor_cfg_exceptions/$CHECK_IGNORE_SETTING" ]; then                          # if a file is found with setting, for example 
                report "Exception found for: $CONFIG_PATH ${MOR_SETTINGS_LIST[$element]} leaved the setting as is" 3
            else
                CURRENT_VALUE=`grep $variable_name $CONFIG_PATH | awk -F";" '{ print $1}' $1 | awk -F"#|;" '{ print $1}' | grep "$variable_name" |  sed 's/ //g' |  sed 's/\t//g'`;
                replace_line $CONFIG_PATH "$variable_name" "${MOR_SETTINGS_LIST[$element]}"
                check_if_setting_match $CONFIG_PATH  "$variable_name" "${MOR_SETTINGS_LIST[$element]}"
                STATUS="$?";
                if [ "$STATUS" == "0" ]; then
                    report "$CONFIG_PATH ${MOR_SETTINGS_LIST[$element]} (was $CURRENT_VALUE)" 4
                    ONE_OF_THE_OPTIONS_WERE_CHANGED=1;
                else
                    report "$CONFIG_PATH ${MOR_SETTINGS_LIST[$element]}" 1
                fi
            fi
        elif [ "$STATUS" == "2" ]; then             #setting was not found at all, adding
            echo "${MOR_SETTINGS_LIST[$element]}" >> $CONFIG_PATH
            check_if_setting_match $CONFIG_PATH  "$variable_name" "${MOR_SETTINGS_LIST[$element]}"
            STATUS="$?";
            if [ "$STATUS" == "0" ]; then
                report "$CONFIG_PATH ${MOR_SETTINGS_LIST[$element]} (line was missing)" 4
                ONE_OF_THE_OPTIONS_WERE_CHANGED=1;
            else
                report "$CONFIG_PATH ${MOR_SETTINGS_LIST[$element]}" 1
            fi
        elif [ "$STATUS" == "3" ]; then             #config file was not found
            report "Config: $CONFIG_PATH not found" 1
            break;
        else
            NUMBER_OF_MATCHES=`grep ${MOR_SETTINGS_LIST[$element]} $CONFIG_PATH | wc -l`
            if [ "$NUMBER_OF_MATCHES" -gt "1" ]; then
                report "There are $NUMBER_OF_MATCHES same settings added" 1
            else
                report "Unexpected error $CONFIG_PATH ${MOR_SETTINGS_LIST[$element]}" 1
            fi
        fi
    done

    if [ "$ONE_OF_THE_OPTIONS_WERE_CHANGED" == "1" ]; then
        return 1;
    fi
}

#================= MAIN ====================
asterisk_is_running

if [ "$?" != "0" ]; then
    exit 0
fi

separator "Checking /etc/asterisk/sip.conf"
mkdir -p /etc/asterisk/.mor_cfg_exceptions
MOR_SETTINGS_LIST=("allowtransfer=no" "alwaysauthreject=yes" "videosupport=yes" "rtptimeout=60" "rtpholdtimeout=300" "t38pt_udptl=yes" "t38pt_rtp=no" "t38pt_tcp=no" "rtcachefriends=yes" "rtsavesysname=yes" "rtupdate=yes"  "ignoreregexpire=yes")
check_fix_cfg "/etc/asterisk/sip.conf" "allowtransfer=no alwaysauthreject=yes videosupport=yes rtptimeout=60 rtpholdtimeout=300 t38pt_udptl=yes t38pt_rtp=no t38pt_tcp=no rtcachefriends=yes rtsavesysname=yes rtupdate=yes  ignoreregexpire=yes"

if [ "$ONE_OF_THE_OPTIONS_WERE_CHANGED" == "1" ]; then
    report "You MUST RESTART an Asterisk for the changes in /etc/asterisk/sip.conf to take effect!" 6
fi


