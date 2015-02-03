#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script checks if Play HGC Audio is set to 1. If so - report "FAILED"
#
#   Parameters
. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

asterisk_is_running
if [ "$?" == "0" ]; then

    # checking if asterisk restart is needed
    hgc_audio=`asterisk -rx "mor show status" | grep "Play" | awk '{print $4}'`
    if [ "$hgc_audio" == "1" ]; then
        check_if_setting_match /etc/asterisk/mor.conf "play_hgc_audio" "play_hgc_audio=0"
        if [ "$?" == "0" ]; then
            report "You must restart Asterisk in order play_hgc_audio = 0 changes in /etc/asterisk/mor.conf to take effect" 1;
        fi
    elif [ "$hgc_audio" == "0" ]; then
        report 'asterisk -rx "mor show status" : Play HGC Audio: 0' 0
    fi
    # /checking if asterisk restart is needed

    # checking /etc/asterisk/mor.conf
    check_if_setting_match /etc/asterisk/mor.conf "play_hgc_audio" "play_hgc_audio=0"
    STATUS="$?";
    if [ "$STATUS" == "1" ]; then    # when the setting is set to something else (most probably to 1 in this situation)
        replace_line /etc/asterisk/mor.conf "play_hgc_audio" "play_hgc_audio = 0"

        #---- checking again if setting was really changed
        check_if_setting_match /etc/asterisk/mor.conf "play_hgc_audio" "play_hgc_audio=0"
        STATUS="$?";
        if [ "$STATUS" == "0" ]; then   #OK, setting was successfully changed
            report "play_hgc_audio = 0 in /etc/asterisk/mor.conf" 4
            report "Please RESTART Asterisk for the changes to take effect: play_hgc_audio = 0" 6
        else                            #FAILED to change the setting
            report "Failed to change play_hgc_audio=1 => 0 in /etc/asterisk/mor.conf, report a bug" 1
        fi
    elif [ "$STATUS" == "2" ]; then     #setting is not found at all!
        echo "play_hgc_audio = 0" >>  /etc/asterisk/mor.conf        #adding the setting, because it was not found
        #---- checking again if setting was really added
        check_if_setting_match /etc/asterisk/mor.conf "play_hgc_audio" "play_hgc_audio=0"
        STATUS="$?";
        if [ "$STATUS" == "0" ]; then   #OK, setting was successfully added
            report "play_hgc_audio = 0 in /etc/asterisk/mor.conf" 4
            report "Please RESTART Asterisk for the changes to take effect: play_hgc_audio = 0" 6
        else                            #FAILED to change the setting
            report "Failed to change play_hgc_audio=1 => 0 in /etc/asterisk/mor.conf, report a bug" 1
        fi
    elif [ "$STATUS" == "0" ]; then     #setting was found
            report "play_hgc_audio = 0 in /etc/asterisk/mor.conf" 0
    fi
fi
