#!/bin/bash
# Modified by Marius Guobys 2012
# Because heartbeat can now be reached from epel repos and old one does not work
PSW=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/test/framework/bash_functions.sh



install_additional_repositories()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This script installs epel and remi repositories in order to install mysql 5.5
    _centos_version
    echo $centos_version
    if [ "$centos_version" == "5" ]; then
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
       else    # centos 6
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
     fi
}

install_additional_repositories


yum -y install heartbeat pacemaker iptraf

# authkeys
echo "auth 2
2 sha1 $PSW" >/etc/ha.d/authkeys
chmod 600 /etc/ha.d/authkeys # 600 or no start

# ha.cf
echo "logfile /var/log/heartbeat.log
logfacility local0
keepalive 2
deadtime 10
initdead 60
ucast eth0 1.1.1.1 # This directive will cause us to send packets to 1.1.1.1 over interface eth0. REPLACE 1.1.1.1 with other node IP.
udpport 694
auto_failback on
node node01
node node02" >/etc/ha.d/ha.cf

# haresources
echo "node01 IPaddr2::192.168.0.14 # just for testing, remember this ip can't be used in your network!!!
node01 192.168.0.14 asterisk # just for testing, remember this ip can't be used in your network!!!" >/etc/ha.d/haresources

checkhosts=`cat /etc/hosts | grep "192.168.0.131 node01 #change to correct IP"`
if [ "$checkhosts" = "" ]; then # /etc/hosts has no nodes
echo "192.168.0.131 node01 #change to correct IP
192.168.0.132 node02 #change to correct IP here aswell" >>/etc/hosts
fi
echo "Installation completed."
