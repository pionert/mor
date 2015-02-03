#! /bin/bash
DEBUG=0
mor_crontab_record_exist(){
       
    #args: 1: string to check in crontab whether exist or not
   
    #return status:
    #   0 - success, the record was found
    #   1 - failure, the record was not found
    #   2 - critical failure
       
    LINES_MATCHING=`crontab -l | grep $1 | wc -l`
    if [ "$LINES_MATCHING" == "1" ]; then 
                if [ "$DEBUG" == "1" ]; then echo "lines matching: $LINES_MATCHING" ; fi
                return 0;                               #OK, only one line matched, we are sure that we won't delete user's custom records
    else
                if [ "$LINES_MATCHING" == "0" ]; then   #none lines matched
                if [ "$?" == "0" ]; then                #if status=0, when previous command was successfull and there is definetly no such record in crontab
                                if [ "$DEBUG" == "1" ]; then echo "lines matching: $LINES_MATCHING" ; fi                               
                                return 1;                                       #no such record was found in crontab
                fi       
                        if [ "$DEBUG" == "1" ]; then echo "lines matching: $LINES_MATCHING" ; fi   
                echo -e "\n\nThere was a failure in mor_crontab_record_exist function, please check crontab manually\n\n";
                return 2       
                fi
    fi
}
#==================
mor_crontab_clean(){
       
    #args:      1. a string to check whether record exists in crontab, and if yes - remove it
    #return status:
    #           0       - OK, record was successfully deleted
    #           1       - OK, record is already deleted
    #           2       - Critical failure
       
   
   mor_crontab_record_exist "$1";
        STATUS="$?";
       
        if [ "$STATUS" == "2" ]; then 
                echo "Critical error occured when trying to delete old MOR crontab entries";
                return 2;
        elif [ "$STATUS" == "1" ]; then
                echo "Record $1 does not exist in crontab, crontab is already clean";
                return 1;   
   elif [ "$STATUS" == "0" ]; then     
               
                rm -rf $HOME/.crontab  # cleaning the mess
                crontab -u $USER -l | grep -v $1 >> $HOME/.crontab
                crontab $HOME/.crontab
                rm -rf $HOME/.crontab  # cleaning the mess
                mor_crontab_record_exist "$1";
                if [ "$?" == "1" ]; then
                        echo "Crontab entry $1 was successfully deleted";
                else
                        echo "Error encountered when cleaning the crontab";
                fi   
    fi
}
#====================
mor_crontab_clean "/etc/logrotate.conf"
mor_crontab_clean "/home/mor_ad/mor_ad_cron"
mor_crontab_clean "/usr/local/mor/test_environment/mor_test_run.sh"
mor_crontab_clean "http://127.0.0.1/billing/callc/hourly_actions"
mor_crontab_clean "http://127.0.0.1/billing/callc/daily_actions"
mor_crontab_clean "/var/log/ntpdate.log"
