#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script checks current server core count and sets recommended value if setting previously was not used. If the setting is uncommented - script does not touch it.

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh


LOAD_PER_CORE=1  # For example if we have 2 cores - allowed max load will be 2 x 2 = 4
#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
read_mor_asterisk_settings

if [ "$ASTERISK_PRESENT" == "1" ]; then
    LOAD_VALUE=`awk -F";" '{print $1}' /etc/asterisk/asterisk.conf | grep maxload | awk -F"=" '{print $2}' | sed 's/ //g'`
    cpu_count # getting CPU count for current server    

    CALCULATED_VALUE=`echo "$LOAD_PER_CORE*$NUMBER_OF_CPUS" | bc`

#    if [ "$LOAD_VALUE" == "" ]; then
    if [ "$LOAD_VALUE" != "$CALCULATED_VALUE" ]; then

#        sed -i "s/;maxload.*;/maxload = $CALCULATED_VALUE  ;/g" /etc/asterisk/asterisk.conf
        
        replace_line /etc/asterisk/asterisk.conf "maxload =" "maxload = $CALCULATED_VALUE"
        replace_line /etc/asterisk/asterisk.conf ";maxload =" "maxload = $CALCULATED_VALUE" # in case it was commented out

        
        report "Asterisk maxload value set to $CALCULATED_VALUE" 4
        report "Asterisk restart is needed" 2
    else
        if [ "$LOAD_VALUE" != "$CALCULATED_VALUE" ]; then
            report "maxload setting in /etc/asterisk/asterisk.conf $LOAD_VALUE does not match the recommended value according to this hardware: maxload = $CALCULATED_VALUE" 2
        else
            report "maxload = $CALCULATED_VALUE setting OK in /etc/asterisk/asterisk.conf" 0
        fi
    fi
fi