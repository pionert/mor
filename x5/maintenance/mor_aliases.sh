#! /bin/sh
 
alias usrc='svn update /usr/src/mor';   #update mor sources
alias astv='asterisk -rx "mor show status" | grep Version';
alias guiv="svn info /home/mor | grep URL | awk -F"/" '{print \$NF}'";  #show current MOR version
alias minf='/usr/src/mor/x5/info.sh'; 
alias astc='asterisk -vvvvvvvvvvvvvvvvvvvvvvvvvvvvvR';
alias pcrack='/usr/src/mor/sh_scripts/support_access.sh';
alias fcrack='/usr/src/mor/sh_scripts/magento_support_access.sh';
alias mstatus='asterisk -rx "mor show status"';
alias cds="cd /usr/src/mor"
alias menv="/usr/bin/mcedit /home/mor/config/environment.rb"    # open with mcedit
alias venv="/bin/vi /home/mor/config/environment.rb"    # open with vi
alias cdtest="cd /usr/src/mor/x5/test_fix_scripts"
alias mysqlc="/usr/bin/mysql -u mor -pmor mor" # MYSQL Console
alias zabi="/usr/src/mor/test/beta-scripts/zabbix_agent_install.sh; /usr/src/mor/test/scripts/various/zabbix_installed.sh"  # ZABix Install
alias mipt="/etc/init.d/iptables status" # Mor IPTables status
alias malt="/usr/bin/tail -f /var/log/httpd/error_log /var/log/httpd/access_log"    # Mor Apache Log Tail
alias mcrash="/usr/bin/tail -n 200 /tmp/mor_crash.log"
alias ssp="/usr/sbin/asterisk -rx 'sip show peers'"   # Sip Show Peers
alias genpas='. /usr/src/mor/x5/framework/bash_functions.sh; generate_random_password 12; echo $GENERATED_PASSWD'
alias mlog="tail -f /var/log/httpd/* /home/mor/log/* /tmp/mor_crash.log"   # Show all GUI logs realtime
alias mdump="/usr/src/mor/sh_scripts/db_dump.sh"

