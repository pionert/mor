#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  Checks MOR core version and enabled addons.

# Addons checked:
    # CC_Active     -   Calling Cards
    # AD_Active     -   Auto-Dialer addon
    # RS_Active     -   Reseller Addon
    # SMS_Active    -   SMS Addon
    # REC_Active    -   Recordings Addon
    # PG_Active     -   Payment Gateway Addon
    # CS_Active     -   Call Shop Addon
    # MA_Active     -   Monitorings Addon
    # MNP           -   Monitorings Addon

. /usr/src/mor/test/framework/bash_functions.sh


export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

#=========MAIN ========



#===== TEST-FIX.sh====
/usr/src/mor/test/test-fix.sh -compact      # skips "OK" messages
#================

asterisk_is_running
if [ "$?" == "0" ]; then
    asterisk -rx "mor show status" | grep "Version\|Active" >> /tmp/.mor_system_features_report
fi

#==== IP ====
gui_exists
  GUI_STATUS="$?"
apache_is_running
  APACHE_STATUS="$?"
if [ "$GUI_STATUS" == "0" ] &&  [ "$APACHE_STATUS" == "0" ]; then
    DEFAULT_IP=`grep Web_URL /home/mor/config/environment.rb | awk -F"/|\"" '{print $4}'`
    RESOLVED_IP=`resolveip $DEFAULT_IP 2> /dev/null | grep "IP address" | awk '{print $NF}'` &>/dev/null
    if [ "$RESOLVED_IP" != "" ] && [ "$RESOLVED_IP" != "127.0.0.1" ]; then
        DEFAULT_IP="$RESOLVED_IP"
    fi
else
   default_interface_ip
fi
echo  "SERVER IP: $DEFAULT_IP                  Go to server: http://support.kolmisoft.com/servers/search_server_ip?server_ip=$DEFAULT_IP" >> /tmp/.mor_system_features_report
#====/IP ====

asterisk_is_running
if [ "$?" == "0" ]; then
    mnp_enabled
    if [ "$MNP_ENABLED" == "0" ]; then
        echo "MNP_Active = 1" >>  /tmp/.mor_system_features_report
    fi
fi

gui_exists
GUI_STATUS="$?"

apache_is_running
APACHE_STATUS="$?"

if [ "$GUI_STATUS" == "0" ] && [ "$APACHE_STATUS" == "0" ]; then   #if MOR GUI installed
    #==== Addons=====
    ADDON_LIST=(CC_Active AD_Active RS_Active SMS_Active REC_Active PG_Active CS_Active MA_Active SKP_Active RSPRO_Active CALLB_Active PROVB_Active)
    for element in $(seq 0 $((${#ADDON_LIST[@]} - 1)))
    do
        grep ${ADDON_LIST[$element]} /home/mor/config/environment.rb >> /tmp/.mor_system_features_report
    done
else
    report "Skipping Addon check: httpd not running or GUI not present" 3
fi #/home/mor

if [ -f /tmp/.mor_system_features_report ]; then
    cat /tmp/.mor_system_features_report
    rm -rf /tmp/.mor_system_features_report
else
    echo "Failed to generate information report";
fi

if [ -f /usr/lib/asterisk/modules/app_mor.so ]; then
    stat /usr/lib/asterisk/modules/app_mor.so | grep -o "Inode: [0-9]*\|Modify:[ a-zA-Z0-9:-]*" | (read a; read b; echo -ne "Core: $a\t\t $b\n" )
fi


ifconfig | grep HWaddr | awk '{print $1"\t"$5}'

dmidecode 2> /dev/null  | grep Serial | grep -v "Not Specified\|None\|Port\|SerNum\|To Be Filled\|System Serial Number\|Chassis Serial Number\|services\|Unknown\|filled\|O.E.M\|OEM" | sed 's/ //g' | sed 's/\t//g' | grep "[0-9]"
