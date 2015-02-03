#! /bin/bash
logrotate_cfg(){
if [ -r /etc/logrotate.conf ]; then

   if [ -r /etc/logrotate.conf.mor_backup ];
    then
         echo "========================================================================================";
         echo "/etc/logrotate.conf configuration is already updated by MOR, if you would like to update it once more - manually rename the /etc/logrotate.conf.mor_backup file to something else and run this script once more";
         echo "========================================================================================";
  else
   cp /etc/logrotate.conf /etc/logrotate.conf.mor_backup;

    echo "/home/mor/log/production.log  {
           daily
           compress
           rotate 7
           create
           copytruncate
    }" >> /etc/logrotate.conf


   if [ -r /etc/redhat-release ]; then
     echo "/var/log/httpd/error.log {
           daily
           compress
           rotate 7
           create
       }
      /var/log/httpd/access.log {
           daily
           compress
           rotate 7
           create
       }" >> /etc/logrotate.conf
   else
       #its debian
       echo "/var/log/apache2/error.log {
           daily
           compress
           rotate 7
           create
       }
      /var/log/apache2/access.log {
           daily
           compress
           rotate 7
           create
       }" >> /etc/logrotate.conf
   fi;
   echo "Logrotate installed";
    fi;
else echo "/etc/logrotate.conf is not readable or doesn't exist";
fi
}
