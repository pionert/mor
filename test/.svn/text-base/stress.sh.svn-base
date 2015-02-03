#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This scripts puts stress on server to check it's hardware condition.
#           After running the script - you can exit from server as the process is forked.
#           
# Usage:
#   1 parameter - hours to torture
#   2 parameter - email or emails list (must be provided in "") to send notification when the server torture will end.

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------
HOURS_TO_TORTURE="$1"
EMAIL_TO_SEND_REPORT="$2"

if [ -z "$EMAIL_TO_SEND_REPORT" ] || [ -z "$HOURS_TO_TORTURE" ]; then
    echo -ne "\n1 parameter - email address where to send results\n2 parameter - how many hours the server has to be tortured\n\nUsage: $0 12h send@me.results \n\n"
    echo -ne "\n\t\th, m, s - hours, minutes, seconds\n\n"
    echo -ne "\n\nYou can also run the script manually"
    exit 1
fi

HOURS_TO_TORTURE=`echo "$HOURS_TO_TORTURE*60*60" | bc`


#----- FUNCTIONS ------------
check_if_strees_tool_installed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks if stress tool is available
    
    if [ ! -f /usr/local/bin/stress ]; then
        if [ ! -f /bin/mail ]; then
            report "Installing mailx for test reporting" 3
            yum -y install mailx
            if [ ! -f /bin/mail ]; then
                report "Failed to install mailx. Network/DNS problems?" 1
                exit 1
            fi
        fi
        
        yum -y install gcc make
        
        report "/usr/local/bin/stress not found, installing" 3
        cd /usr/src/
        wget -c http://www.kolmisoft.com/packets/src/stress-1.0.4.tar.gz
        report "Extracting" 3
        tar xzvf stress-1.0.4.tar.gz &> /dev/null
        cd stress-1.0.4
        report "Configuring" 3
        ./configure &> /dev/null
        report "Compiling"
        make &> /dev/null
        report "Installing" 3
        make install &> /dev/null
        rm -rf /usr/src/stress-1.0.4    #house cleaning
        
        if [ -f /usr/local/bin/stress ]; then
            report "/usr/local/bin/stress installed" 4
        else
            report "/usr/local/bin/stress not found, install failed" 1
            exit 1
        fi
    fi
}
system_get_cpu_count()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function gets system processors count
    
    s_processor_count=`grep processor /proc/cpuinfo | wc -l`
}
system_get_ram_amount()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function gets total system RAM amount
    
    s_ram_amount=`free -m | (read a; head -n 1 ) | awk '{print $2}'`
}


calculate_torture_parameters()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function calculates processors, RAM  amount for server torture
    
    system_get_cpu_count
    STRESS_CPU_COUNT=`echo "$s_processor_count*5" | bc`
    
    system_get_ram_amount
    STRESS_RAM_COUNT=`echo "$s_ram_amount/2" | bc`
    
    HDD_PROCESS_COUNT=`echo "$s_processor_count*12" | bc`
}




run_stress()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function runs the torture tests themselves
    

    default_interface_ip
    report "Launching torture test. Wait for results in email." 3
    results=`mktemp`
    stress --cpu $STRESS_CPU_COUNT --io 10 --vm 4 --vm-bytes "$STRESS_RAM_COUNT"M --timeout "$HOURS_TO_TORTURE" -d $HDD_PROCESS_COUNT &> $results
    
    # gathering details about hdd status
    sleep 5 # giving some time for server to breath fresh air in order kernel would not kill email to be sent
    
    echo -e "\n\n===== S.M.A.R.T After torture ==========\n\n" $results 
    /usr/src/mor/test/scripts/information/hdd_smart_status.sh >> $results       # there might be hdd errors which can be hidden by kernel - we have to retrieve them manually
    sleep 5 # giving some time for server to breath fresh air in order kernel would not kill email to be sent
    postfix_running
    if [ "$POSTFIX_STATUS" == "0" ]; then
        service postfix restart
    fi
    
    cat $results | nice -n -20 mail -s "Stress Test Report $(hostname): $DEFAULT_IP"  $EMAIL_TO_SEND_REPORT

    echo "$mor_time" > /usr/local/mor/stress_time
    cat $results >> /usr/local/mor/stress_time
    _mor_time
    mv $results /tmp/mor_stress_test_result_$mor_time       # the email report not allways get sent as kernel might kill the process itself on high load

    
}

#--------MAIN -------------

check_if_strees_tool_installed
calculate_torture_parameters
run_stress
 