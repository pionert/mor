#! /bin/sh

# Author:   Mindaugas Mardosas
# Year:     2012
# About:    This script is a Kolmisoft test cluster local nodes controller


curl http://brain2/dashboard/nodes | grep "id=\"ip_" | awk -F"\">" '{print $3}' | awk -F"<\/" '{print $1}' | while read SERVER_IP; do
    echo "Sent cmd to $SERVER_IP"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$SERVER_IP "n -remove;" &
done
