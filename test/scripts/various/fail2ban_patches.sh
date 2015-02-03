#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if fail2ban is guarding sshd. If not - fixes that.

. /usr/src/mor/test/framework/bash_functions.sh

#====== How to test changes ==============

# How to test Fail2Ban after each improvement:
#   1. Apply updates
#   2. Go to /etc/fail2ban/jail.conf
#   3. Find the line ignoreip = 192.168.0.1/16 10.0.0.0/8 127.0.0.1/8 172.16.0.0/12 213.197.141.162  192.168.0.55 127.0.0.1
#   4. Comment out that line with # sign at the beginning of the line
#   5. Restart Fail2Ban: service fail2ban restart
#   6. Test if Fail2Ban blocks you after 3 times entering incorrect SSH password    # it should block you after 3 attempts for 10 minutes
#   7. Test if Fail2Ban blocks you after entering GUI pages like: http://server_ip/billing or http://server_ip


#=========================================


#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_ssh_filterd_updated_for_centos56and6()
{
    if [ -f  /etc/fail2ban/filter.d/sshd.conf ]; then
        REGEXP_EXIST=`grep -F 'ssh\d*)?.*$' /etc/fail2ban/filter.d/sshd.conf | wc -l`
        if [ "$REGEXP_EXIST" == "0" ]; then
            report "Fail2Ban reinstall needed. This update will includes one more regexp for SSH packets checking. Attempting to reinstall automatically" 1
            rm -rf /etc/fail2ban/filter.d/sshd.conf
            STATUS=1    #force reinstall            
            return 1
            
        else
            return 0
        fi
    fi
}
w00tfix()
{
    # This is a bugfix for fail2ban regexep
    woot_present=`grep -F 'w00tw00t.at.blackhats.romanian' /etc/fail2ban/filter.d/apache-phpmyadmin.conf | wc -l`
    if [ "$woot_present" == "1" ]; then
        STATUS=1
        return 1
    fi
}
disable_apache_phpmyadmin()
{
    if [ ! -f /etc/fail2ban/exceptions/phpmyadmin ]; then
        phpmyadmin_jail_enabled=`grep -A 1 -F "[apache-phpmyadmin]" /etc/fail2ban/jail.conf | grep enabled | grep true | wc -l`
        if [ "$phpmyadmin_jail_enabled" == "1" ]; then
            STATUS=1
            return 1
        fi
    fi
}
apache_phpmyadmin()
{
    if [ ! -f "/etc/fail2ban/filter.d/apache-phpmyadmin.conf" ]; then
        report "Fail2Ban reinstall needed. This update will includes one more regexp for phpmyadmin and other web services scanning bots. Attempting to reinstall automatically" 1
        STATUS=1    #force reinstall            
        return 1
    else
	return 0
    fi
}
check_iptables_for_ssh_chain()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This function checks if fail2ban chain exists in iptables rules
#
#   Returns:
#       0   -   OK  fail2ban ssh chain in iptables exists
#       1   -   Failed fail2ban ssh chain in iptables does not exist

    local sshChain=`/etc/init.d/fail2ban status | grep -o ssh-iptables | wc -l`
    if [ "$sshChain" != "0" ]; then
        return 0
    else
        return 1
    fi
}

check_if_ssh_logs_failures_to_messages()
{
    local logged=`grep "sshd" /var/log/messages | grep "Failed password" | wc -l`
    local ssh_iptables_messages_log=`grep '\[ssh-iptables2\]' /etc/fail2ban/jail.conf | wc -l`
    if [ "$logged" != "0" ] && [ "$ssh_iptables_messages_log" == "0" ]; then
        report "sshd is logging failed login attempts to /var/log/messages instead of /var/log/secure, attempting to fix this" 3
        echo -ne "\n[ssh-iptables2]\nenabled  = true\nfilter   = sshd\naction   = iptables[name=SSH, port=ssh, protocol=tcp]\nlogpath  = /var/log/messages\nmaxretry = 1\nbantime = 600\n" >> /etc/fail2ban/jail.conf
        /etc/init.d/fail2ban restart   
    fi
}

#--------MAIN -------------
fail2ban_installed
STATUS="$?"


if [ "$STATUS" == "0" ]; then
    check_iptables_for_ssh_chain
    STATUS="$?"
    #=== Patch needed? You can include it here to force fail2ban to upgrade==
    check_if_ssh_filterd_updated_for_centos56and6   #will overwrite with STATUS=1 if a patch is needed
    apache_phpmyadmin
    check_if_ssh_logs_failures_to_messages
    w00tfix
    disable_apache_phpmyadmin
    #===================

    if [ "$STATUS" == "0" ]; then
        report "Fail2Ban-ssh" 0
    else
        #====== updating jail.conf config====
            #==== Includes=====================================
            . /usr/src/mor/sh_scripts/install_configs.sh
            . /usr/src/mor/sh_scripts/mor_install_functions.sh
            #====end of Includes===========================

        rm -rf /usr/src/fail2ban-0.8.4.tar.gz /usr/src/fail2ban-0.8.4

        download_packet "fail2ban-0.8.4.tar.gz"
        cd /usr/src
        tar xvfz fail2ban-0.8.4.tar.gz &> /dev/null
        unalias cp &> /dev/null #unaliasing any existing aliases for cp so that they would not interfere with install script
        # === "patch" by overwriting needed files ===
        cp /usr/src/fail2ban-0.8.4/config/filter.d/apache-phpmyadmin.conf /etc/fail2ban/filter.d/apache-phpmyadmin.conf
        cp /usr/src/fail2ban-0.8.4/config/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/apache-badbots.conf
        cp /usr/src/fail2ban-0.8.4/config/jail.conf /etc/fail2ban/jail.conf
        # ====

        fail2banAddressesToIgnore
        


	STATUS=0 #resetting

        check_iptables_for_ssh_chain
        if [ "$?" != "0" ]; then
            STATUS=1
        fi
        apache_phpmyadmin
        if [ "$?" != "0" ]; then
            STATUS=1
        fi

        if [ "$STATUS" == "0" ]; then
            report "Fail2Ban" 4
        else
            report "Fail2Ban" 1
        fi
        #====================================
    fi

else
    /usr/src/mor/sh_scripts/fail2ban_install.sh

    fail2ban_started
    fail2banStatus="$?"

    check_iptables_for_ssh_chain
    fail2BanSSHstatus="$?"

    if [ "$fail2banStatus" == "0" ] && [ "$fail2BanSSHstatus" == "0" ]; then
        report "Fail2Ban-SSH" 4
    else
        report "Fail2Ban-SSH" 1
    fi
fi

patch_fail2ban_v0_8_4()
{
    if fail2ban-server -V | grep -q '0.8.4'
    then
    
        if grep -q '_cmd_lock.acquire' /usr/share/fail2ban/server/action.py
        then
            report "fail2ban version 0.8.4 detected" 0
            report "Patches were already applied previously" 0
        else   
            report "fail2ban version 0.8.4 detected" 0
            report "Applying patches" 0
            patch /usr/share/fail2ban/server/action.py < /usr/src/mor/test/files/patches/action_executeCmd_locking.diff
        
            #regenertate pyc.file
            python -m compileall /usr/share/fail2ban/server/  
        fi
           
    else
        report "fail2ban version  is not 0.8.4 or fail2ban is not running. NO patches will be applied" 0
    fi
        
    

}

#----- Update configurations ----

cp -fr /usr/src/mor/test/files/fail2ban/filter.d/asterisk.conf   /etc/fail2ban/filter.d/asterisk.conf
cp -fr /usr/src/mor/test/files/fail2ban/filter.d/sshd.conf   /etc/fail2ban/filter.d/sshd.conf
cp -fr /usr/src/mor/test/files/fail2ban/filter.d/asterisk_cli.conf /etc/fail2ban/filter.d/asterisk_cli.conf
cp -fr /usr/src/mor/test/files/fail2ban/filter.d/asterisk_manager.conf /etc/fail2ban/filter.d/asterisk_manager.conf
cp -fr /usr/src/mor/test/files/fail2ban/filter.d/mor.conf /etc/fail2ban/filter.d/mor.conf
cp -fr /usr/src/mor/test/files/fail2ban/filter.d/mor_ddos.conf   /etc/fail2ban/filter.d/mor_ddos.conf
cp -fr /usr/src/mor/test/files/fail2ban/jail.conf /etc/fail2ban/jail.conf

/etc/init.d/fail2ban restart


patch_fail2ban_v0_8_4

# and restart  again
# We do not need to restart but it doesnt  hurt too much either

/etc/init.d/fail2ban restart
