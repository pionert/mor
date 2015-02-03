#!/bin/sh
#==== Includes=====================================
   cd /usr/src/mor
   . "$(pwd)"/sh_scripts/install_configs.sh
#====end of Includes===========================



touch $HOME/.crontab_tmp        #making temporary crontab_file
crontab -u $USER -l >> $HOME/.crontab_tmp #moving old crons


NTPD=`cat $HOME/.crontab_tmp | grep -i "daily_actions"`;
if [ "$NTPD" == "" ]; then 

    touch $HOME/.crontab  #making new crontab_file
    cat  $HOME/.crontab_tmp >> $HOME/.crontab #moving old crons
    echo "0 0 * * * wget -o /dev/null -O /dev/null http://127.0.0.1/billing/callc/daily_actions" >> $HOME/.crontab
    echo  >> $HOME/.crontab
    crontab $HOME/.crontab


    rm -rf $HOME/.crontab  # cleaning the mess

fi


rm -rf $HOME/.crontab_tmp  # cleaning the mess
