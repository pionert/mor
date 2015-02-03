#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    Script adds or removes /var/www/html/billing symlink depending on setting in /etc/mor/gui.conf.
#           /var/www/html/billing is removed only if it is symlink.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ] && [ -L /var/www/html/billing ]; then

    unlink /var/www/html/billing
    report "Symlink /var/www/html/billing was removed" 4
    
elif [ "$GUI_PRESENT" == "1" ] && [ ! -L /var/www/html/billing ]; then
    if [ -f /var/www/html/billing ] || [ -d /var/www/html/billing ]; then
        report "/var/www/html/billing is not a Symlink" 1
        exit 1;
    fi
    
    ln -s /home/mor/public /var/www/html/billing
    
    if [ -L /var/www/html/billing ]; then
        report "Symlink /var/www/html/billing was created" 4
    else
        report "Symlink /var/www/html/billing was not created" 1
    fi

else
    report "Symlink /var/www/html/billing is ok" 0
fi

