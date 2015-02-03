#!/bin/sh

echo ""
echo "======== Ruby Cairo upgrade ========"
echo ""

cd /usr/src
wget http://cairographics.org/releases/rcairo-1.6.2.tar.gz
tar xzvf rcairo-1.6.2.tar.gz
cd rcairo-1.6.2
ruby extconf.rb
make
make install


if [ -r /etc/redhat-release ]; then 
    /etc/init.d/httpd restart
else
    /etc/init.d/apache2 restart 
fi; 


echo ""
echo "done."
echo ""


echo "Press ENTER to exit"
read