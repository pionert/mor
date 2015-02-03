#! /bin/bash

redh_cent_aft_inst(){
if [ -r /etc/httpd/conf/httpd.conf_backup_made_by_mor ]; 
   then
      echo "==============================================";
      echo "After install configuration is already updated";
      echo "==============================================";
   else
      cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_backup_made_by_mor
      if [ -r /etc/httpd/conf/httpd.conf_backup_made_by_mor ];
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
         echo "Now you can reach MOR GUI: http://<your_server_ip>/billing/   
   username: admin
   psw: admin";
      else echo "/etc/httpd/conf/httpd.conf backup creation unsuccessful";
      fi
fi

}
redh_cent_aft_inst;
