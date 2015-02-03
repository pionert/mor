#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks and informs if SSL is enabled in server

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#-----------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 1;
fi

#-----------MAIN

ssl_enabled
if [ "$SSL_STATUS" == "on" ]; then  #ssl enabled
    report "SSL enabled, if hourly_actions, monthly_actions tests are indicating problems this might be the reason - set 'SSLEngine off' in /etc/httpd/conf.d/ssl.conf and run tests again" 3
else
    report "SSL is not enabled" 0
fi
