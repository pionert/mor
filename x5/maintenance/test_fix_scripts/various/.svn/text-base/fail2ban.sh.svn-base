#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

#----------------------------
check_iptables_for_asterisk_chain()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This function checks if fail2ban chain exists in iptables rules
#
#   Returns:
#       0   -   OK  fail2ban ssh chain in iptables exists
#       1   -   Failed fail2ban ssh chain in iptables does not exist

    local asteriskChain=`/etc/init.d/fail2ban status 2> /dev/null | grep -o "asterisk-iptables\|fail2ban-SIP"`
    if [ "$asteriskChain" == "asterisk-iptables" ] || [ "$asteriskChain" == "fail2ban-SIP" ]; then
        return 0
    else
        return 1
    fi
}
fail2ban_asterisk_installed()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This function checks if fail2ban is installed. If not - fixes that.

# Returns:
    # 0 - OK
    # 1 - failed to fix
    # 4 - fixed

    check_iptables_for_asterisk_chain
    if [ "$?" == "1" ]; then
        /usr/src/mor/sh_scripts/fail2ban_install.sh
    fi

    if [ -f "/etc/fail2ban/filter.d/asterisk.conf" ]  && [ -f "/etc/fail2ban/jail.conf" ]  && [ -f "/etc/fail2ban/fail2ban.conf" ]  && [ -f  "/etc/init.d/fail2ban" ]; then
        fail2ban_started
        if [ "$?" == "0" ]; then
            #report "Fail2Ban is installed and running" 0
            return 0
        else
            #report "Fail2Ban is not running" 1
            /etc/init.d/fail2ban start

            fail2ban_started    #testing again if fail2ban started successfully
            if [ "$?" == "0" ]; then
                #report "Fail2Ban is installed and running" 0
                return 4 #fixed
            else
                return 1 #failed to fix
            fi
        fi
    else
        /usr/src/mor/sh_scripts/fail2ban_install.sh
        fail2ban_started
        if [ "$?" == "0" ]; then
            return 0    # OK
        else
            return 1    # FAILED
        fi
    fi
}
#================= MAIN ====================
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi
#-------

fail2ban_asterisk_installed
if [ "$?" == "0" ]; then
    report "Fail2Ban is installed and running" 0
    exit 0
elif [ "$?" == "4" ]; then
    report "Fail2Ban" 4
    exit 4
else
    report "Fail2Ban" 1
    exit 1
fi
