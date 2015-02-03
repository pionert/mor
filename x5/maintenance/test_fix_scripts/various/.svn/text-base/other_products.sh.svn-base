#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks for other products in the system which can break MOR installation

. /usr/src/mor/x5/framework/bash_functions.sh

FIRST_INSTALL="$1"

#------VARIABLES-------------

#----- FUNCTIONS ------------
plesk()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script checks if Plesk ( http://www.parallels.com/products/plesk/) is installed
    
    if [ -d "/usr/local/psa" ]; then
        if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
            report "Plesk (/usr/local/psa) detected in server. Cannot continue with this CentOS installation; Please provide a CLEAN CentOS installation. More information can be found here: http://wiki.kolmisoft.com/index.php/Centos_installation" 1
            read;
            exit 1;
        else
            report "Plesk (/usr/local/psa) detected in server. http://www.parallels.com/products/plesk/" 2
        fi
    else
	report "Plesk not detected" 0
    fi
}

#--------MAIN -------------

# Asterisk based products 
asterisk_exist
if [ "$?" == "0" ]; then
    grep Elastix /etc/motd &> /dev/null
    if [ "$?" == "0" ]; then
        report "MOR is not compatible with Elastix, please reinstall the server" 1
        if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
            read;   # for install.sh - to force engineer to look at the problem
        fi
        exit 1;
    fi
fi

# === Other products ====

plesk
