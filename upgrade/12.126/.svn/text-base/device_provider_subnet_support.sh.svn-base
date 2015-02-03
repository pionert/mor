#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script adds device/provider network subnet support

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

check_if_subnet_support_already_added_to_cfg()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks if update is needed to be applied
    
    if [ `awk -F ";" '{print $1}' /etc/asterisk/sip.conf |  grep '/usr/local/mor/mor_ast_device_subnet' | wc -l` == 0 ]; then
        return 1  # Update is neeeded   
    else
        return 0  # update is not needed
    fi
}

check_or_compile_mor_ast_device_subnet()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function ensures that /usr/local/mor/mor_ast_device_subnet gets compiled.
    #
    # Returns:
    #   0   -   OK, required C program already exists
    #   1   -   Failed to compile 
    #   4   -   OK, file was compiled successfully now by this function
    
    if [ ! -f "/usr/local/mor/mor_ast_device_subnet" ]; then
        cd /usr/src/mor/scripts
        ./install.sh
        if [ -f "/usr/local/mor/mor_ast_device_subnet" ]; then
            report "Compiled /usr/local/mor/mor_ast_device_subnet" 4
            return 4
        else
            report "Failed to compile /usr/local/mor/mor_ast_device_subnet. Try to compile and move it manually: cd /usr/src/mor/scripts; ./install.sh" 1
            exit 1  # don't go any further in order Asterisk would not try to load non existig C script
        fi
    fi  
}

#=============== MAIN ===============

read_mor_asterisk_settings
if [ "$ASTERISK_PRESENT" == "0" ]; then
    exit 0
fi

check_or_compile_mor_ast_device_subnet
check_if_subnet_support_already_added_to_cfg
if [ "$?" == "1" ]; then  
    echo "#exec /usr/local/mor/mor_ast_device_subnet" >>  /etc/asterisk/sip.conf
    check_if_subnet_support_already_added_to_cfg
    if [ "$?" == "1" ]; then  
        report "Failed to update /etc/asterisk/sip.conf configuration with option: #exec /usr/local/mor/mor_ast_device_subnet, add it manually" 1
    else
        report "/etc/asterisk/sip.conf updated to suppport device/provider subnetting" 0
        # reloading extensiong       
        report "Reloading Asterisk extensions" 3
        asterisk -rx "dialplan reload"        
    fi
fi