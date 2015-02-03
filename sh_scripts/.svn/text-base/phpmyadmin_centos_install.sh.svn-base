#!/bin/sh

    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh

echo phpmyadmin upgrade to latest version

PSWS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`

install_sources() {
cd /usr/src
rm -rf phpMyAdmin-3.5.8-english.tar.gz
rm -rf phpMyAdmin-3.5.8-english
wget "$KOLMISOFT_URL"/packets/phpMyAdmin-3.5.8-english.tar.gz
tar zxvf phpMyAdmin-3.5.8-english.tar.gz

mv phpMyAdmin-3.5.8-english phpmyadmin
mv /usr/src/phpmyadmin /var/www/html/phpmyadmin
mv /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php
}

additional_repos() {

_centos_version
    echo $centos_version
    if [ "$centos_version" == "5" ]; then
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
        rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-5.rpm
    else    # centos 6
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
        rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
    fi
}

php_dependencies_update() {
 _centos_version
    if [ "$centos_version" == "5" ]; then
        yum -y --nogpgcheck --enablerepo=remi,remi-test install php-mbstring php-mysql php-mbstring php-mcrypt
    else    # centos 6
        yum -y --nogpgcheck --releasever=6 --enablerepo=remi,remi-test install php-mysql php-mbstring php-mcrypt
    fi
  }

 htaccess_install() {
# gen password for htaccess
if [ ! -f /var/www/html/moradmin/.htpasswd ]; then     
    htpasswd -b -m -c /var/www/html/moradmin/.htpasswd admin $PSWS
    rm -rf /root/phpMyAdminPassword
    touch /root/phpMyAdminPassword
    echo "Your Login and Password from stats system is: admin $PSWS" >/root/phpMyAdminPassword
fi
if [ ! -f /var/www/html/moradmin/.htaccess ]; then
    touch /var/www/html/moradmin/.htaccess
    echo "AuthUserFile /var/www/html/moradmin/.htpasswd
          AuthName \"Restricted access, password located in /root/phpMyAdminPassword file\"
          AuthType Basic
          Require valid-user" > /var/www/html/moradmin/.htaccess
fi
}

 install_sources
 additional_repos
 php_dependencies_update
rm -rf /var/www/html/moradmin
mv /var/www/html/phpmyadmin /var/www/html/moradmin
htaccess_install
/etc/init.d/httpd restart