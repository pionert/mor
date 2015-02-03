#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#----------------------------
localhost_accessibility_test()
{
    wget --no-check-certificate -O /tmp/login http://127.0.0.1/billing/callc/login &> /tmp/wget_out
    IS_ACCESSIBLE=`cat /tmp/login | grep "login_psw\|login_username"` &> /dev/null
    rm -rf /tmp/login /tmp/wget_out
    if [ "$IS_ACCESSIBLE" != "" ]; then
        return 0;
    else
        return 1;
    fi
}
gui_accessibility_test_through_external_ip()
{
    DEFAULT_IP=`grep Web_URL /home/mor/config/environment.rb | awk -F"/|\"" '{print $4}'`
    MOR_Web_URL=`grep Web_URL /home/mor/config/environment.rb |  awk -F'\"' '{print $2}'`

    wget --no-check-certificate -O /tmp/login $MOR_Web_URL/billing/callc/login &> /tmp/wget_out
    IS_ACCESSIBLE=`cat /tmp/login | grep "login_psw\|login_username"` &> /dev/null
    rm -rf /tmp/login /tmp/wget_out
    if [ "$IS_ACCESSIBLE" != "" ]; then
        return 0;
    else
        return 1;
    fi
}
#================= MAIN ====================

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

#-- APACHE CHECK--
apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 1;
fi

localhost_accessibility_test
if [ "$?" == "0" ]; then
    report "http://127.0.0.1/billing/callc/login accessibility (your GUI with standart page is reachable for the server itself)" 0
    exit 0
else
    gui_accessibility_test_through_external_ip
    if [ "$?" == "0" ]; then
        report "$MOR_Web_URL/billing/callc/login accessibility (your GUI with standart page is reachable for the server itself)" 0
        exit 0
    else
        report "$MOR_Web_URL/billing/callc/login and http://127.0.0.1/billing/callc/login accessibility not working, will try to fix, hold on" 3

	# let's try to fix
	source "/usr/local/rvm/scripts/rvm" &> /dev/null
	rvm use 2.1.2 &> /dev/null
	cd /home/mor
	bundle update &> /dev/null
	/etc/init.d/httpd restart &> /dev/null

	# let's test again
        gui_accessibility_test_through_external_ip
        if [ "$?" == "0" ]; then
            report "$MOR_Web_URL/billing/callc/login accessibility (your GUI with standart page is reachable for the server itself)" 0
            exit 0
        else
            report "$MOR_Web_URL/billing/callc/login and http://127.0.0.1/billing/callc/login accessibility" 1
            exit 1
        fi

    fi
fi
