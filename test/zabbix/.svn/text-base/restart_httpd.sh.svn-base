#! /bin/sh

#   echo "*/1 * * * * root /bin/sh -l /usr/src/mor/test/zabbix/restart_httpd.sh &> /dev/null" > /etc/cron.d/httpd_restart



mor_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;

if [ `service httpd status | grep running | wc -l` == 0 ]; then
    sleep 120
    if [ `service httpd status | grep running | wc -l` == 0 ]; then
        killall -9 httpd
        service httpd restart
        echo "[ $mor_time ] httpd was restarted by script " >> /var/log/scripted_httpd_restart
    fi    
fi    
