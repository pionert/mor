#! /bin/sh

# this script should be executed on server TO which will be connecting (e.g. APP in MOR system)

echo
echo


# move old pub file (backup)
cd /root
mv id_rsa.pub id_rsa.pb.old


# enter IP of GUI server and download pub key from it
ip=$1
goodfile="/root/id_rsa.pub"
until [ -a "$goodfile" ]; do
    echo "Please enter ip or hostname of GUI server"
    read ip
    cd /root
    wget http://$ip/id_rsa.pub
    if [ -a "/root/id_rsa.pub" ]; then echo "File downloaded"; fi
done 

cd /root

# check for authorize_keys file
if [ -a "/root/.ssh/authorized_keys" ]; then 
    echo "authorized_keys file exists"; 
else
    mkdir -p /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys 
    chmod 700 /root/.ssh
    echo "authorized_keys file created";     
fi

# include pub key into authorize_keys file

cat /root/id_rsa.pub >> /root/.ssh/authorized_keys 

rm -rf /root/id_rsa.pub

echo "Done. Go to GUI server to activate this APP server. Press ENTER. "

read