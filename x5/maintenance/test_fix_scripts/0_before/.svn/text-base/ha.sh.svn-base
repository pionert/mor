#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks and fixes various known problems with Linux HA

source /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_for_bad_repo_ip()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script detects old office IP in one of the repos files and updates it to use a hostname.

    grep -F "193.138.191.205" /etc/yum.repos.d/server\:ha-clustering.repo &> /dev/null
    if [ "$?" == "0" ]; then
        echo -ne "[server_ha-clustering]\nname=High Availability/Clustering server technologies (CentOS_5)\ntype=rpm-md\nbaseurl=http://www.kolmisoft.com/packets/heartbeat/\ngpgcheck=0\ngpgkey=http://www.kolmisoft.com/packets/heartbeat/repodata/repomd.xml.key\nenabled=1" >/etc/yum.repos.d/server:ha-clustering.repo         #copied from /usr/src/mor/sh_scripts

        grep -F "193.138.191.205" /etc/yum.repos.d/server\:ha-clustering.repo &> /dev/null
        if [ "$?" != "0" ]; then        
            report "/etc/yum.repos.d/server:ha-clustering.repo updated with hostname" 4
            yum clean all &> /dev/null # cleaning up yum cache
        else
            report "/etc/yum.repos.d/server:ha-clustering.repo updated with hostname" 1            
        fi
    fi
}
#--------MAIN -------------

heartbeat_is_running
STATUS="$?"
if [ "$STATUS" == "0" ] || [ "$STATUS" == "2" ]; then
    check_for_bad_repo_ip
fi
