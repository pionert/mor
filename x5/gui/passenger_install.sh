#! /bin/bash

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012-2013
# About:    This script:
#               1. makes a backup of current Apache config: /etc/httpd/conf/httpd.conf
#               2. Install passenger gem

RUBY_VERSION="2.1.2"
GEMSET=""
PASSENGER_VERSION="4.0.48"

. /usr/src/mor/x5/framework/bash_functions.sh

source "/etc/profile.d/rvm.sh"


passenger_gem()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function ensures that ruby passenger gem is installed

    local passenger_gem=`rvm $RUBY_VERSION@$GEMSET do gem list | grep passenger | wc -l`
    if [ "$passenger_gem" -ge "1" ] && [ -f /etc/httpd/conf.d/m2.conf ] && [ -f /etc/httpd/conf.d/passenger.conf ] && [ -f `grep mod_passenger.so /etc/httpd/conf.d/passenger.conf  | awk '{print $NF}'` ] && [ `grep "@$GEMSET" /etc/httpd/conf.d/passenger.conf  | wc -l` != "0" ]; then
        report "Passenger gem is installed, v$PASSENGER_VERSION" 0
    else
        yum install -y curl-devel

        rvm $RUBY_VERSION@$GEMSET do gem install passenger -v=$PASSENGER_VERSION --no-ri --no-rdoc

        chmod 777 -R /tmp
        chmod o+t -R /tmp

        rvm $RUBY_VERSION@$GEMSET do passenger-install-apache2-module -a
        rvm $RUBY_VERSION@$GEMSET do passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf

        passenger_module=`grep mod_passenger.so /etc/httpd/conf.d/passenger.conf  | awk '{print $NF}'`
        if [ ! -f "$passenger_module" ]; then
            report "Failed to compile mod_passenger.so" 1
        fi

        local passenger_gem=`rvm $RUBY_VERSION@$GEMSET do gem list | grep passenger | wc -l`
        if [ "$passenger_gem" -ge "1" ]; then
            report "Passenger gem is installed" 4
            RESTART_REQUIRED=1
        else
            report "Failed to install Ruby passenger" 1
        fi
    fi
}

check_if_name_virtual_host_option_enabled()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks if NameVirtualHost *:80 option is enabled in /etc/httpd/conf/httpd.conf

    local NameVirtualHost=`awk -F"#" '{print $1}' /etc/httpd/conf/httpd.conf | grep NameVirtualHost | wc -l`
    if [ "$NameVirtualHost" == "1" ]; then
        report "NameVirtualHost *:80 option in /etc/httpd/conf/httpd.conf found" 0
    else
        report "NameVirtualHost *:80 option in /etc/httpd/conf/httpd.conf not found, fixing" 3
        replace_line /etc/httpd/conf/httpd.conf '#NameVirtualHost' 'NameVirtualHost *:80'
        local NameVirtualHost=`awk -F"#" '{print $1}' /etc/httpd/conf/httpd.conf | grep NameVirtualHost | wc -l`
        if [ "$NameVirtualHost" == "1" ]; then
            report "NameVirtualHost *:80 option in /etc/httpd/conf/httpd.conf found" 4
            RESTART_REQUIRED=1
        else
            report "NameVirtualHost *:80 option in /etc/httpd/conf/httpd.conf NOT found. Please fix manually by adding NameVirtualHost *:80 option to /etc/httpd/conf/httpd.conf" 1
        fi
    fi
}

migrate_apache_config()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function migrates currect Apache configuration to compatible one with passenger

    source "/usr/local/rvm/scripts/rvm"

    oldCfg=`grep -F '^/billing/public' /etc/httpd/conf/httpd.conf | wc -l`
    if [ "$oldCfg" == "1" ]; then
        # creating a backup of existing Apache configuration
        mkdir -p /usr/local/m2/backups/httpd_cfg
        _mor_time
        cp /etc/httpd/conf/httpd.conf /usr/local/m2/backups/httpd_cfg/httpd.conf_before_passenger_"$mor_time"
        if [ -f /usr/local/m2/backups/httpd_cfg/httpd.conf_before_passenger_"$mor_time" ]; then
            report "Created a backup of current httpd conf to /usr/local/m2/backups/httpd_cfg/httpd.conf_before_passenger_$mor_time" 3
        fi

        # remove existing M2 configuration from /etc/httpd/conf/httpd.conf
            # Black magic to delete old configuration from /etc/httpd/conf/httpd.conf
            report "Removing old M2 configuration in /etc/httpd/conf/httpd.conf" 3
            sed '/RewriteCond %{REQUEST_URI} !\^\/billing\/public/,/<\/Directory>/d' /etc/httpd/conf/httpd.conf > /tmp/.httpd_cfg
            mv /tmp/.httpd_cfg /etc/httpd/conf/httpd.conf
            oldCfg=`grep -F '^/billing/public' /etc/httpd/conf/httpd.conf | wc -l`
            if [ "$oldCfg" == "1" ]; then
                report "Migration of /etc/httpd/conf/httpd.conf was successful" 4
            else
                report "Migration of /etc/httpd/conf/httpd.conf Failed" 1
            fi
    fi

    # Generate new configuration
    check_if_name_virtual_host_option_enabled
    if [ ! -f /etc/httpd/conf.d/passenger.conf ]; then
        report "/etc/httpd/conf.d/passenger.conf not found, generating one" 3
        rvm $RUBY_VERSION@$GEMSET do passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
        local cfg_lines=`wc -l /etc/httpd/conf.d/passenger.conf | awk '{print $1}'`
        if [ "$cfg_lines" == "3" ]; then
            report "/etc/httpd/conf.d/passenger.conf generated" 4
            RESTART_REQUIRED=1
        else
            report "Failed to generate /etc/httpd/conf.d/passenger.conf" 1
        fi
    fi

    if [ ! -s /etc/httpd/conf.d/m2.conf ]
    then    # If file is empty or does not exist
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
        " > /etc/httpd/conf.d/m2.conf
    else 
           # If we have RailsEnv production line, replace it with RackEnv production
           if  grep --quiet 'RailsEnv production' /etc/httpd/conf.d/m2.conf
           then
               sed -i.bak 's/RailsEnv production/RackEnv production/g' /etc/httpd/conf.d/m2.conf
           fi
    fi
}

check_if_passenger_configuration_not_empty()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    This function checks if passenger configuration is correct. If not - configuration is regenerated

    if [ -f /etc/httpd/conf.d/passenger.conf ]; then
        if [ `cat /etc/httpd/conf.d/passenger.conf | wc -l` == "5" ]; then
            report "Passenger configuration is OK" 0
        else
            rvm $RUBY_VERSION@$GEMSET do passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf
            if [ `cat /etc/httpd/conf.d/passenger.conf | wc -l` == "5" ]; then
                report "Passenger configuration is OK" 4
                RESTART_REQUIRED=1
            else
                report "Failed to generate passenger configuration. Please use this command to do this manually: passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf" 1
                exit 1
            fi
        fi
    fi

    if [ `grep "PassengerMaxPoolSize\|PassengerPoolIdleTime" /etc/httpd/conf.d/passenger.conf | wc -l` -lt 2 ]; then
    	# magic settings for performace tuning
    	# http://www.alfajango.com/blog/performance-tuning-for-phusion-passenger-an-introduction/
    	echo -e "PassengerMaxPoolSize 30\nPassengerPoolIdleTime 10" >> /etc/httpd/conf.d/passenger.conf
    fi

}

#===== Main ==================
RESTART_REQUIRED=0

passenger_gem
check_if_name_virtual_host_option_enabled
migrate_apache_config

check_if_passenger_configuration_not_empty

if [ "$RESTART_REQUIRED" == "1" ]; then
    /etc/init.d/httpd restart
fi
