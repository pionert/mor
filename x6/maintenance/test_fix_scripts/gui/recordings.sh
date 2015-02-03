#! /bin/sh
# Author:   Mindaugas Mardosas
# Purpose: Fixes an issue when /var/spool/asterisk/monitor or /home/mor/public/recordings symlink does not exist and recordings do not open in GUI. Also fix'es issue when calls are not recorded as described in: http://wiki.kolmisoft.com/index.php/Calls_are_not_recorded

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#=============== Main =================================

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

asterisk_is_running
ASTERISK_STATUS="$?"

if [ "$ASTERISK_STATUS" == "0" ]; then
    if [ ! -d /var/spool/asterisk/monitor ] || [ ! -h /home/mor/public/recordings ]; then
        mkdir -p /var/spool/asterisk/monitor
        chmod 777 /var/spool/asterisk/monitor
        ln -s /var/spool/asterisk/monitor /home/mor/public/recordings
        cp -u /usr/src/mor/scripts/mor_wav2mp3 /bin/

        if [ -d /var/spool/asterisk/monitor ] && [ -h /home/mor/public/recordings ]; then
            report "Recordings were fixed" 4
            exit 4
        else
            report "Failed to fix recordings" 1
            exit 1
        fi
    else
	report "Recording symlink is ok to /var/spool/asterisk/monitor" 0
    fi
fi
