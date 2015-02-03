#! /bin/sh
# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script separates

# Arguments:
    # no arguments are accepted

. /usr/src/mor/test/framework/bash_functions.sh


gui_exists
if [ "$?" == "0" ]; then
    folder_separator   "GUI tests"
else
    report "MOR GUI is not present in the system" 3
fi
