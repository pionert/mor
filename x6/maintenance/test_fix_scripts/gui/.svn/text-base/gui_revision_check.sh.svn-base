#! /bin/sh
#   Author: Nerijus Sapola
#   Year:   2012
#   About:  This script checks if the system has the newest stable revision of GUI

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi


GUI_REVISION_IN_SYSTEM=`svn info /home/mor | sed -n '9p' | sed 's/ //g' | awk -F":" '{print $NF}'`

mor_gui_current_version

#echo $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS

if [ -f "/usr/src/mor/upgrade/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS/stable_revision" ]; then
    rm -rf /usr/src/mor/upgrade/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS/stable_revision &> /dev/null
    svn update /usr/src/mor/upgrade/$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS/stable_revision &> /dev/null
    get_last_stable_mor_revision $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS
    
    if [ "$GUI_REVISION_IN_SYSTEM" -lt "$LAST_STABLE_GUI" ]; then
        report "GUI is outdated. Latest stable revision is $LAST_STABLE_GUI, revision on server is $GUI_REVISION_IN_SYSTEM" 1
    else
        report "GUI is up to date." 0
    fi
fi
