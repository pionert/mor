#!/bin/sh


svn co http://svn.kolmisoft.com/mor/gui/branches/0.6 /home/mor

if [ -r /etc/redhat-release ]; then
    /etc/init.d/httpd restart
else
    /etc/init.d/apache2 restart
fi;
