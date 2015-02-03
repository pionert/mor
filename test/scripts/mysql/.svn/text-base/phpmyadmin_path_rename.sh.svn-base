#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script moves /var/www/html/phpmyadmin directory to /var/www/html/moradmin in order not to confuse users attacked by automated bots.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------


if [ -d /var/www/html/phpmyadmin ] ; then
    mv  /var/www/html/phpmyadmin /var/www/html/moradmin
    report "/var/www/html/phpmyadmin moved to /var/www/html/moradmin in order to disable stupid bot attacks" 4
fi
 
 
if [ -f /var/www/html/moradmin/.htaccess ] && [ `grep moradmin /var/www/html/moradmin/.htaccess | wc -l` == "0" ]; then
   echo -e 'AuthUserFile /var/www/html/moradmin/.htpasswd\nAuthName "Restriced access"\nAuthType Basic\nRequire valid-user' >  /var/www/html/moradmin/.htaccess 
fi


if [ -d /var/www/html/moradmin ]; then
    if [ ! -f /var/www/html/moradmin/.htaccess ] || [ ! -f /var/www/html/moradmin/.htpasswd ]; then
        report "/var/www/html/moradmin/.htaccess or /var/www/html/moradmin/.htpasswd is missing. That might be a security hole!"   3
    fi
fi