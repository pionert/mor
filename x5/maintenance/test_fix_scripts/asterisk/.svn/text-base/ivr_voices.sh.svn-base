#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This scripts checks if IVR voices folder exists  when the system has asterisk installed

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------


asterisk_is_running
if [ "$?" == "0" ] && [ ! -d "/home/mor/public/ivr_voices/en" ]; then
    report "Asterisk is running, folder /home/mor/public/ivr_voices/en is not found. Launching script /usr/src/mor/sh_scripts/install_mor9_sounds.sh to fix this" 3
    mkdir -p /home/mor/public/ivr_voices
    /usr/src/mor/sh_scripts/install_mor9_sounds.sh > /dev/null
    if [ -d "/home/mor/public/ivr_voices/en" ]; then
        report "IVR Voices in /home/mor/public/ivr_voices" 4
    else
        report "IVR Voices in /home/mor/public/ivr_voices" 1
    fi
else
    report "IVR Voices checked" 0
fi

