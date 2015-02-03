#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    Script creates cronjob which is needed to run Monitorings addon. It should be launched on MA server.

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

var_p="mor"
var_u="mor"
var_n="mor"

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ -f /etc/cron.d/mor_monitorings ]; then
    report "/etc/cron.d/mor_monitorings already exist. Please update it manually or remove it and run the script again." 3
    exit 0;
fi

echo "What is IP of GUI server?"
read gui_ip
echo "What is MOR API key?"
read api_key
get_answer "Do you want to change default database connection settings which are -p mor -umor -nmor?" "n"
if [ "$answer" == "y" ]; then
    echo "What is database name?"
    read var_n
    echo "What is database username?"
    read var_u
    echo "What is database username password?"
    read var_p
fi
echo "*/12 * * * * root /usr/local/mor/mor_ruby /home/mor/lib/scripts/monitoring_script.rb -ahttp://$gui_ip/billing/api/ma_activate -p $var_p -u$var_u -n$var_n -k$api_key" > /etc/cron.d/mor_monitorings
report "Following string was added to /etc/cron.d/mor_monitorings:" 4
echo "*/12 * * * * root /usr/local/mor/mor_ruby /home/mor/lib/scripts/monitoring_script.rb -ahttp://$gui_ip/billing/api/ma_activate -p $var_p -u$var_u -n$var_n -k$api_key"
report "Do not forget to enabled MA on GUI server" 3
service crond restart
