#! /bin/sh

# activates APP server so ssh would not ask yes/no to include it in hosts file
# this script should be started on GUI server


# LOGIN AS APACHE!!! su apache before executing this script


echo
echo
echo "Please enter ip or hostname of APP server"
read ip


ssh -o StrictHostKeyChecking=no root@$ip -f "exit"
echo "SSH is ready, now test it by doing 'ssh root@$ip'" 

read
