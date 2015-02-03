#! /bin/sh
# Author:   Mindaugas Mardosas
# Year:     2012
# About:    This script starts virtual machines after unexpected physical test machine restart
#
# Setup:
#    Add this line: 'su - -c "/bin/sh -x /usr/src/mor/test/cluster1/hp.sh >> /tmp/vm_startup" root'  to /etc/rc.local  BEFORE starting gnome. /etc/rc.local file should look like this after all:
#
#   touch /var/lock/subsys/local
#   su - -c "/bin/sh -x /usr/src/mor/test/cluster1/hp.sh >> /tmp/vm_startup" root
#   su - -c "/bin/bash startx" root
#
# Known issues:
#   When you move virtual machine from one machine to another - you have to upgrade it or the script will fail to start it:
#       1. Shutdown the machine
#       2. vmrun upgradevm /path/to/machine.vmx
#

VM_LIST=( '/ssd/VM_12.126/12.126_linked_5/12.126_linked_5.vmx' '/ssd/VM_12.126/12.126_linked_3/12.126_linked_3.vmx' '/ssd/10_2/10_2.vmx' '/ssd/VM_12.126/12.126_linked_FOR_MK/12.126_MK.vmx' '/ssd/9_2/9_2.vmx' '/ssd/11_II/11_2.vmx' '/ssd/VM_12.126/12.126_linked_4/12.126_linked_4.vmx')
for element in $(seq 0 $((${#VM_LIST[@]} - 1)))
do
    
    su - -c "/usr/bin/vmrun -T ws start ${VM_LIST[$element]} nogui >> /tmp/vm_startup" root
    echo "Starting ${VM_LIST[$element]}" >> /tmp/vm_startup
done


