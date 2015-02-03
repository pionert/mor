#! /bin/sh

# Author:   Mindaugas Mardosas
# Year:     2012
# About:    Wake-up script for brain2

HTTP_STATUS=`service httpd status | grep "dead\|stopped" | wc -l`

if  [ "$HTTP_STATUS" != "0" ]; then
    /etc/init.d/httpd stop
    killall -9 httpd
    for i in `ipcs -s | awk '/apache/ {print $2}'`; do (ipcrm -s $i); done   # killing evil apache semaphores
    service httpd start
fi