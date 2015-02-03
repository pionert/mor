#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script ensures that /var/www/html/phpsysinfo has the same logins and passwords as phpmyadmin directory

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ -d "/var/www/html/phpsysinfo" ]; then

    if [ -d "/var/www/html/moradmin" ] && [ -f "/var/www/html/moradmin/.htaccess" ] && [ -f "/var/www/html/moradmin/.htpasswd" ]; then
        cp -fr /var/www/html/moradmin/.htaccess /var/www/html/phpsysinfo/
        cp -fr /var/www/html/moradmin/.htpasswd /var/www/html/phpsysinfo/
    elif [ -d "/var/www/html/phpmyadmin" ]  && [ -f "/var/www/html/phpmyadmin/.htaccess" ] && [ -f "/var/www/html/phpmyadmin/.htpasswd" ]; then
        cp -fr /var/www/html/phpmyadmin/.htaccess /var/www/html/phpsysinfo/
        cp -fr /var/www/html/phpmyadmin/.htpasswd /var/www/html/phpsysinfo/
    fi    
fi

