#! /bin/sh

# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script checks /home/mor/config/environment.rb and reports if variable ENV['TZ'] = 'GMT' is set. The time might be displayed incorrectly in MOR GUI because of this setting
#
# Returns:
#   0 - setting was not found
#   1 - setting was found   #might indicate a problem

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#--------MAIN -------------
apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

if [ "$?" == "0" ]; then
    check_if_setting_match /home/mor/config/environment.rb "ENV\['TZ']" "ENV['TZ']='GMT'"
    if [ "$?" == "0" ]; then
        report "ENV['TZ']='GMT' setting was found in /home/mor/config/environment.rb. If you experience problems with time in MOR GUI please try to disable this setting. IF TIME IS OK - DO NOT TOUCH THIS SETTING!" 3
        exit 3
      #  echo "System clock:"
      #  date
      #  echo "Hardware clock:"
      #  hwclock
    fi
fi
