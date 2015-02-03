#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2009
#   About:  This script checks if /home/mor_ad/mor_ad_cron.log has such log entry at the end: Successfully connected to database
. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#----------------------------
check_if_ad_enabled()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  Checks if AD tests are needed
    #
    #   Important notes:
    #       This function runs only on Asterisk servers
    
    mor_core_version "EXIT_IF_NO_CORE"
    if [ "$MOR_CORE_BRANCH" -ge "13" ] ; then
        mysql_connect_data_v2      > /dev/null
        TMP_FILE=`/bin/mktemp`
        if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select value FROM conflines WHERE name='AD_Active' LIMIT 1;" | (read; cat) | grep 1 | wc -l` != "1" ]; then
            report "Auto Dialer is not enabled" 3
            exit 1
        fi
    fi
}
enable_autodialer_debug_if_disabled()
{
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About: when autodialer debug is not enabled - the test will not give correct results.

    debug_status=`awk -F"#" '{print $1}' /var/lib/asterisk/agi-bin/mor.conf | sed 's/ //g' | grep 'debug'`
    if [ "$debug_status" != "debug=1" ]; then
        sed '/debug/d' /var/lib/asterisk/agi-bin/mor.conf > /tmp/mor.conf$$;
        echo "debug = 1" >>  /tmp/mor.conf$$;
        mv /tmp/mor.conf$$ /var/lib/asterisk/agi-bin/mor.conf
        asterisk -rx "extensions reload"
        debug_status=`awk -F"#" '{print $1}' /var/lib/asterisk/agi-bin/mor.conf | sed 's/ //g' | grep 'debug'`
        if [ "$debug_status" == "debug=1" ]; then
            report "Enabled autodialer debug; Run the test again after a few minutes in order to test correctly if autodialer is working" 3
            return 2    # reenabled
        else
            report "Failed to enable autodialer debug. Do that manually, set debug = 1 in /var/lib/asterisk/agi-bin/mor.conf and run this command: \n\nasterisk -rx 'reload'\nn" 1
            return 1
        fi
    fi
}

autodialer_tst()
{
    if [ -r "/var/log/mor/mor_ad_cron.log" ]; then
        LAST=`sed -n '/Start of MOR Auto-Dialer Cron script/x; ${x;p;}' /var/log/mor/mor_ad_cron.log | awk '{print $1 " "  $2}'` &> /dev/null
        tail -n 90 /var/log/mor/mor_ad_cron.log | grep -A 3 "$LAST"  | grep "Successfully connected to database." &> /dev/null  # tail in front - workaround for some bug when grep only returns "Binary file /var/log/mor/mor_ad_cron.log matches"
        if [ $? == 0 ];  then
            return 0
        else
            return 1;
        fi
    else
        return 1;
    fi

}
#---------------main -------------


read_mor_asterisk_settings
if [ "$ASTERISK_PRESENT" == "0" ]; then
    exit 0;
fi

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

check_if_ad_enabled

enable_autodialer_debug_if_disabled
if [ "$?" == "0" ]; then
    autodialer_tst
    if [ "$?" == "0" ]; then
        report "Autodialer and database connectivity" 0
        exit 0
    else
        report "Autodialer and database connectivity" 1
        exit 1
    fi
fi



