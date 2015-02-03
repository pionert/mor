#! /bin/sh


# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script checks if /etc/httpd/conf/httpd.conf and /etc/httpd/conf.d/mod_fcgid_include.conf has IPCCommTimeout variable

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#----------------------------
IPCCommTimeout()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    Script checks if /etc/httpd/conf/httpd.conf has IPCCommTimeout variable
    
    #  Returns:
    #   1   -   value was found! Check if it does not interface

    if [ -f /etc/httpd/conf.d/mod_fcgid_include.conf ]; then    # this one overrides default httpd.conf so if found in  this one - no need to check httpd.conf
        IPCCommTimeoutV=`awk -F"#" '{print $1}' /etc/httpd/conf.d/mod_fcgid_include.conf |  grep 'IPCCommTimeout' | sed 's/ //g'`
        CFG_FILE="/etc/httpd/conf.d/mod_fcgid_include.conf"
    else
        IPCCommTimeoutV=`awk -F"#" '{print $1}' /etc/httpd/conf/httpd.conf |  grep 'IPCCommTimeout' | sed 's/ //g'`
        CFG_FILE="/etc/httpd/conf/httpd.conf"
    fi 

    if [ "$IPCCommTimeoutV" == "IPCCommTimeout6000" ]; then
        return 0
    else
        return 1
    fi
}
#================= MAIN ====================
read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

IPCCommTimeout
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    report "IPCCommTimeout in $CFG_FILE is OK" 0
else
    IPCVALUE=`echo $IPCCommTimeoutV | sed 's/IPCCommTimeout//'`
    report "IPCCommTimeout in $CFG_FILE  does not match default: IPCCommTimeout 6000. Found: $IPCVALUE. Setting this value too low may cause httpd to not complete the request on time and the user will be returned Error 500 page." 3
fi


