#!/bin/bash

fix_apache_config(){
if [ -r /etc/httpd/conf/httpd.conf_kolmisoft_backup ]; 
   then
      echo "==============================================";
      echo "Apache config is already fixed";
      echo "==============================================";
   else
      cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_kolmisoft_backup
      if [ -r /etc/httpd/conf/httpd.conf_kolmisoft_backup ];
      then
         echo >> /etc/httpd/conf/httpd.conf 
         echo "RewriteCond %{REQUEST_URI} !^/billing/public
RewriteRule ^/billing(/.*)?$   /billing/public$1
<Directory /var/www/billing/public/>
    Options ExecCGI FollowSymLinks
    AllowOverride All
    Allow from all
    Order allow,deny
</Directory> " >> /etc/httpd/conf/httpd.conf
         cat /etc/httpd/conf/httpd.conf | sed '{:start {s/AllowOverride None.*$/AllowOverride All/;t end;n;T start}};{:end n; b end}' | sed '{:start {s/AllowOverride None.*$/AllowOverride All/;t end;n;T start}};{:end n; b end}' > /tmp/mor_httpd_conf && cat /tmp/mor_httpd_conf > /etc/httpd/conf/httpd.conf && rm -rf /tmp/mor_httpd_conf
         /etc/init.d/httpd restart
         echo "====================================================";
         echo "Now you can reach GUI: http://<your_server_ip>/billing/   
   username: admin
   psw: admin1";
      else echo "/etc/httpd/conf/httpd.conf backup creation unsuccessful";
      fi
fi

}


yum -y install httpd httpd-devel php php-gd php-mysql anacron php-mcrypt php-mbstring apr-util-devel
chmod 555 /var/log/httpd
chmod -R 666 /var/log/httpd
chkconfig --level 345 httpd on

# fix_apache_config; passenger later deletes this config

# for ruby backups to save ram
cd /usr/src/mor/x6/gui
./xsendfile_install.sh

