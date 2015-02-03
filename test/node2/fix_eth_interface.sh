#! /bin/sh
# Author: Mindaugas Mardosas
# Year:   2012
# About:  This script fixes netork issues after node cloning
#
#         echo "sh -x /usr/src/mor/test/node2/fix_eth_interface.sh"  >> /etc/rc.local

if [ `ifconfig -a | grep eth0 | wc -l` != "1" ]; then
    rm -rf /etc/udev/rules.d/70-persistent-net.rules
    mv /etc/sysconfig/network-scripts/ifcfg-eth0 /root/ifcfg-eth0
    reboot
fi

if [ ! -f "/etc/sysconfig/network-scripts/ifcfg-eth0" ] && [ -f "/root/ifcfg-eth0" ]; then
    . /usr/src/mor/test/framework/bash_functions.sh
    eth_MAC_addr=`ifconfig -a |grep eth0 | head -n 1 | awk '{print $NF}'`
    replace_line "/root/ifcfg-eth0" "HWADDR" "HWADDR=\"$eth_MAC_addr\""
    replace_line "/root/ifcfg-eth0" "NM_CONTROLLED" "NM_CONTROLLED=\"no\""
    if [ `grep -F "PEERDNS=no" /root/ifcfg-eth0 | wc -l` == "0" ]; then
        echo "PEERDNS=no" >> /root/ifcfg-eth0
    fi
    mv /root/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0
    /etc/init.d/network restart
fi

echo -e "nameserver 4.2.2.2\nnameserver 8.8.8.8" > /etc/resolv.conf    #fix DNS settings
cp -fr /usr/src/mor/test/node2/hosts /etc/hosts
