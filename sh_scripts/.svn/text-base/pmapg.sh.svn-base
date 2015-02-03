#!/bin/bash
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================
which_os #!!!
PSW=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`

if [ $OS = "CENTOS" ]; then
  echo "CENTOS Detected"
   blowfish_secret=`grep blowfish_secret /var/www/html/phpmyadmin/config.inc.php`
    if [ "$blowfish_secret" = "\$cfg['blowfish_secret'] = ''; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */" ]; then
    echo "Configuring /var/www/html/phpmyadmin/config.inc.php file..."
cat /var/www/html/phpmyadmin/config.inc.php | sed "{:start {s/blowfish_secret'] = '';.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" |
  sed "{:start {s/blowfish_secret'] = ''.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" >/var/www/html/phpmyadmin/config.inc.php
echo "Login and Password from phpMyAdmin system: admin $PSW" >/root/phpMyAdminPassword # leaving new password for root into /root/phpMyAdminPassword file
  echo "You password from PHPMyAdmin system is saved into /root/phpMyAdminPassword file..."
  sleep 2
  elif [ "$blowfish_secret" = "\$cfg['blowfish_secret'] = ''" ]; then
   echo "Configuring /var/www/html/phpmyadmin/config.inc.php file..."
   cat /var/www/html/phpmyadmin/config.inc.php | sed "{:start {s/blowfish_secret'] = '';.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" |
   sed "{:start {s/blowfish_secret'] = ''.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" >/var/www/html/phpmyadmin/config.inc.php
  echo "Login and Password from phpMyAdmin system: admin $PSW" >/root/phpMyAdminPassword # leaving new password for root into /root/phpMyAdminPassword file
  echo "You password from PHPMyAdmin system is saved into /root/phpMyAdminPassword file..."
 sleep 2
fi
if [ ! -f /var/www/html/phpmyadmin/.htpasswd ]; then
  touch /var/www/html/phpmyadmin/.htpasswd
   echo "creating file .htpasswd"
    htpasswd -b -m /var/www/html/phpmyadmin/.htpasswd admin $PSW
    echo "updating .htpasswd file"
else
 echo "Nothing to be done with .htpasswd file"
fi
if [ ! -f /var/www/html/phpmyadmin/.htaccess ]; then
 touch /var/www/html/phpmyadmin/.htaccess
 echo "AuthUserFile /var/www/html/phpmyadmin/.htpasswd
 AuthName \"Restriced access\"
 AuthType Basic
 Require valid-user" > /var/www/html/phpmyadmin/.htaccess
 echo ".htaccess configured"
else
 echo "Nothing to be done with .htaccess file"
fi

elif [ $OS = "DEBIAN" ]; then
 echo "Debian Detected"
   blowfish_secret=`grep blowfish_secret /var/lib/phpmyadmin/config.inc.php`
   if [ "$blowfish_secret" = "\$cfg['blowfish_secret'] = ''" ]; then
    echo "Configuring /var/lib/phpmyadmin/config.inc.php file..."
cat /var/lib/phpmyadmin/config.inc.php | sed "{:start {s/blowfish_secret'] = '';.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" |
  sed "{:start {s/blowfish_secret'] = ''.*$/blowfish_secret'] = '$PSW';/;t end;n;T start}};{:end n; b end}" >/var/lib/phpmyadmin/config.inc.php
echo "Login and Password from phpMyAdmin system: admin $PSW" >/root/phpMyAdminPassword # leaving new password for root into /root/phpMyAdminPassword file
  echo "You password from PHPMyAdmin system is saved into /root/phpMyAdminPassword file..."
  sleep 2
fi
if [ ! -f /var/www/phpmyadmin/.htpasswd ]; then
  touch /var/www/phpmyadmin/.htpasswd
   echo "creating file .htpasswd"
    htpasswd -b -m /var/www/phpmyadmin/.htpasswd admin $PSW
   echo "updating .htpasswd file"
else
 echo "Nothing to be done with .htpasswd file"
fi
if [ ! -f /var/www/phpmyadmin/.htaccess ]; then
 touch /var/www/phpmyadmin/.htaccess
 echo "AuthUserFile /var/www/phpmyadmin/.htpasswd
 AuthName \"Restriced access\"
 AuthType Basic
 Require valid-user" > /var/www/phpmyadmin/.htaccess

 echo ".htaccess configured"
else
 echo "Nothing to be done with .htaccess file"
fi
else
 echo "Cannot identify Operating System, installer will now exit."
  echo "Please open new support ticket if you see this error. Sorry for any inconvenience caused."
 exit;
fi
