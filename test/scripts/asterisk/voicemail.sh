#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2010
# About:    This script checks if Timezone defined in /etc/sysconfig/clock config matches the one defined in /etc/asterisk/voicemail.conf. If not - fixes. The correct one is treated: /etc/sysconfig/clock

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

getTimeZone()
{
    #   Author:   Mindaugas Mardosas
    #   Company:  Kolmisoft
    #   Year:     2011
    #   About:    This function retrieves a current system timezone from /etc/sysconfig/clock config
    #
    #   Returns:
    #       0   -   OK, timezone retrieved successfully
    #       1   -   An error occoured
    #
    #
    #   MOR_TIME_ZONE this global variable will have a system timezone assigned
    #
    #   Example usage:
    #       [root@localhost sysconfig]# getTimeZone
    #       [root@localhost sysconfig]# echo $MOR_TIME_ZONE
    #       Europe/Vilnius
    #

    if [ ! -f /etc/sysconfig/clock ]; then
        echo "Error: /etc/sysconfig/clock does not exist, exiting"
        return 1;
    fi

    MOR_TIME_ZONE=`awk -F";" '{print $1}' /etc/sysconfig/clock  | awk -F"#" '{print $1}' | grep ZONE | sed 's/\t//g' | sed 's/ //g' | sed ':a;N;$!ba;s/\n//g' | sed 's/"//g' | awk -F"=" '{print $2}'` #sed ':a;N;$!ba;s/\n//g' replaces new line characters
    if [ "$MOR_TIME_ZONE" != "" ]; then
        return 0
    else
        return 1
    fi
}

checkIfZoneInfoMatch()
{
    #   Author:   Mindaugas Mardosas
    #   Company:  Kolmisoft
    #   Year:     2011
    #   About:    This function checks if Timezone defined in /etc/sysconfig/clock config matches the one defined in /etc/asterisk/voicemail.conf
    #   Some details:   Asterisk takes the first UNCOMMENTED defined zone after section [zonemessages], so if the first one uncommented zone will not match - we will just insert a new one to be the first one after [zonemessages]

    #   Returns:
    #       0   -   OK
    #       1   -   Failed, Zones do not match
    #       2   -   /etc/asterisk/voicemail.conf or /etc/sysconfig/clock not found
    #       4   -   Fixed

    if [ ! -f /etc/asterisk/voicemail.conf ] || [ ! -f /etc/sysconfig/clock ]; then
        return 2
    fi

    getTimeZone
    zoneCfgInAsteriskVoicemail=`awk -F";" '{print $1}' /etc/asterisk/voicemail.conf | grep "[a-z,A-Z]" | grep -A 1 '\[zonemessages\]' | (read; cat) | grep -o $MOR_TIME_ZONE`
    if [ "$zoneCfgInAsteriskVoicemail" == "$MOR_TIME_ZONE" ]; then
        return 0
    else
        newZoneToInsert="european=$MOR_TIME_ZONE|'vm-received' a d b 'digits/at' HM"
        _mor_time

        cp /etc/asterisk/voicemail.conf /etc/asterisk/voicemail.conf_backup_$mor_time

        local TEMP_FILE=`mktemp`
        awk "{print} /\[zonemessages\]/{print \"$newZoneToInsert\"}" /etc/asterisk/voicemail.conf >> $TEMP_FILE
        mv	$TEMP_FILE /etc/asterisk/voicemail.conf

        zoneCfgInAsterisVoicemail=`awk -F";" '{print $1}' /etc/asterisk/voicemail.conf | grep "[a-z,A-Z]" | grep -A 1 '\[zonemessages\]' | (read; cat) | grep -o $MOR_TIME_ZONE`
        if [ "$zoneCfgInAsterisVoicemail" == "$MOR_TIME_ZONE" ]; then
            return 4    #fixed
        else
            return 1
        fi
    fi
}

#--------MAIN -------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

checkIfZoneInfoMatch
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    report "Found $zoneCfgInAsteriskVoicemail timezone in /etc/asterisk/voicemail.conf, it matched timezone defined in /etc/sysconfig/clock" 0
elif [ "$STATUS" == "4" ]; then
    report "Fixed $MOR_TIME_ZONE timezone in /etc/asterisk/voicemail.conf to match the one defined in /etc/sysconfig/clock. For more info visit: http://wiki.kolmisoft.com/index.php/Voicemail_is_sent_with_wrong_time" 4
elif [ "$STATUS" == "1" ]; then
    report "Failed to fix $zoneCfgInAsteriskVoicemail timezone in /etc/asterisk/voicemail.conf to match the one defined in /etc/sysconfig/clock. For more info visit: http://wiki.kolmisoft.com/index.php/Voicemail_is_sent_with_wrong_time" 1
fi

