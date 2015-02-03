#!/bin/sh

. /usr/src/mor/x5/framework/framework.conf
. /usr/src/mor/x5/framework/mor_install_functions.sh
. /usr/src/mor/x5/framework/bash_functions.sh

echo phpmyadmin upgrade to latest version

PSWS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
NAME="mordbadmin"

VER="4.2.6"

install_sources() {
cd /usr/src
rm -rf phpMyAdmin-$VER-english.tar.gz
rm -rf phpMyAdmin-$VER-english
wget "$KOLMISOFT_URL"/packets/phpMyAdmin-$VER-english.tar.gz
tar zxvf phpMyAdmin-$VER-english.tar.gz

mv phpMyAdmin-$VER-english phpmyadmin
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
        #yum -y --nogpgcheck --releasever=6 --enablerepo=remi,remi-test install php-mysql php-mbstring php-mcrypt
        yum -y --skip-broken --nogpgcheck --releasever=6 --enablerepo=remi,remi-test install php-mysql php-mbstring php-mcrypt #skip-broken because of this remi conflicts
    fi
  }

 htaccess_install() {
# gen password for htaccess
if [ ! -f /var/www/html/$NAME/.htpasswd ]; then     
    htpasswd -b -m -c /var/www/html/$NAME/.htpasswd admin $PSWS
    rm -rf /root/phpMyAdminPassword
    touch /root/phpMyAdminPassword
    echo "Your Login and Password from stats system is: admin $PSWS" >/root/phpMyAdminPassword
fi
if [ ! -f /var/www/html/$NAME/.htaccess ]; then
    touch /var/www/html/$NAME/.htaccess
    echo "AuthUserFile /var/www/html/$NAME/.htpasswd
          AuthName \"Restricted access, password located in /root/phpMyAdminPassword file\"
          AuthType Basic
          Require valid-user" > /var/www/html/$NAME/.htaccess
fi
}

 install_sources
 additional_repos
 php_dependencies_update
rm -rf /var/www/html/$NAME
mv /var/www/html/phpmyadmin /var/www/html/$NAME
htaccess_install
# enable htaccess through AllowOverride
cat /etc/httpd/conf/httpd.conf | sed '{:start {s/AllowOverride None.*$/AllowOverride All/;t end;n;T start}};{:end n; b end}' | sed '{:start {s/AllowOverride None.*$/AllowOverride All/;t end;n;T start}};{:end n; b end}' > /tmp/mor_httpd_conf && cat /tmp/mor_httpd_conf > /etc/httpd/conf/httpd.conf && rm -rf /tmp/mor_httpd_conf

/etc/init.d/httpd restart

#cleanup
rm -fr /usr/src/phpMyAdmin-$VER-english.tar.gz
