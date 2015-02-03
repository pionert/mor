#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script upgrades invoices. For more info visit ticket: http://trac.kolmisoft.com/trac/ticket/6675

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

 [[ -s "/usr/loca/rvm/scripts/rvm" ]] && . "/usr/loca/rvm/.rvm/scripts/rvm"
#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "1" ]; then  # is gui present in this system?
    mor_gui_current_version
    mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"

    if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
        # check if system has invoices
        mysql_connect_data_v2 > /dev/null

        if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT count(*) FROM invoices;" | wc -l` != "0" ]; then
            report "Launching invoice check-repair script" 3
            if [ `/usr/local/mor/mor_ruby /home/mor/lib/scripts/invoice_tax_fix.rb -n$DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -s$DB_HOST | grep OK | wc -l` == "1" ]; then
                report "Invoices OK"   0
            else
                report "Failed to fix invoices. Please try to run this command manually: /usr/local/mor/mor_ruby /home/mor/lib/scripts/invoice_tax_fix.rb -n$DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -s$DB_HOST" 1
            fi
        fi
    fi
fi