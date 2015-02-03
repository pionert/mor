#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    This script updates default passanger configuration

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

need_to_restart_httpd="0"

#----- FUNCTIONS ------------
check_if_passenger_configuration_update_is_needed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks if passanger configuration needs an update
    #
    # Returns:
    #   1   - passenger configuration needs an update
    #   0   - OK, passenger configuration update is not needed

    if [ `grep "PassengerMaxPoolSize\|PassengerPoolIdleTime" /etc/httpd/conf.d/passenger.conf | wc -l` -lt 2 ]; then
        return 1  
    else
        return 0
    fi

}

update_passenger_configuration()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function updates passanger configuration /etc/httpd/conf.d/passenger.conf 
    #
    echo -e "PassengerMaxPoolSize 30\nPassengerPoolIdleTime 10" >> /etc/httpd/conf.d/passenger.conf

    need_to_restart_httpd="1"

}

mor_conf()
{
    if [ -f /etc/httpd/conf.d/mor.conf ]; then
        if [ `grep "RackEnv" /etc/httpd/conf.d/mor.conf | wc -l` == "0" ]; then
            report "Adding 'RackEnv production' variable to /etc/httpd/conf.d/mor.conf" 4
    echo "
    <VirtualHost *:80>
        DocumentRoot /var/www/html
        <Directory /var/www/html>
            Allow from all
        </Directory>
        RailsBaseURI /billing
        <Directory /var/www/html/billing>
            Options -MultiViews
       </Directory>
       RackEnv production
       PassengerDefaultUser apache
       PassengerDefaultGroup apache
    </VirtualHost>
    " > /etc/httpd/conf.d/mor.conf

        need_to_restart_httpd="1"
        fi


    fi
    
}
#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

gui_exists
if [ "$?" != "0" ]; then
    exit 0;
fi

if [ ! -f /etc/httpd/conf.d/passenger.conf ]; then
    exit 0  # passenger does not exist
fi

check_if_passenger_configuration_update_is_needed
if [ "$?" != "0" ]; then
    update_passenger_configuration

    check_if_passenger_configuration_update_is_needed
    if [ "$?" == "0" ]; then
        report "Passenger configuration updated: /etc/httpd/conf.d/passenger.conf " 4
    else
        report "Failed to update Passenger configuration: /etc/httpd/conf.d/passenger.conf " 1
    fi
else
    report "Passenger configuration is ok" 0
fi

#-------

mor_conf

if [ "$need_to_restart_httpd" == "1" ]; then
    /etc/init.d/httpd restart &> /dev/null
    need_to_restart_httpd="0"
fi
