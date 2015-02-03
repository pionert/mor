#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

asterisk -vvvrx 'realtime mysql status'
wait_user2

asterisk -vvvrx 'module show like app_mor.so'
wait_user2

asterisk -vvvrx 'module show like fax'
wait_user2

asterisk -vvvrx 'module show like h323'
wait_user2

asterisk -vvvrx 'show translation'
wait_user2
