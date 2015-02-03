#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    Prepares config files on additional Asterisk server.

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

mor_conf="/etc/asterisk/mor.conf"
res_mysql_conf="/etc/asterisk/res_mysql.conf"
res_config_mysql_conf="/etc/asterisk/res_config_mysql.conf"
agi_conf="/var/lib/asterisk/agi-bin/mor.conf"
manager_conf="/etc/asterisk/manager.conf"
mnp_conf="/usr/local/mor/mor_mnp.conf"

#----- FUNCTIONS ------------

replace_value()                                                                                            
{                                                                                                          
# arguments:                                                                                               
# 1 - file                                                                                                 
# 2 - parameter                                                                                            
# 3 - value                                                                                                
#                                                                                                          

sed -c -i "s/\($2 *= *\).*/\1$3/" $1                                                                       
}

#--------MAIN -------------

#get values
echo "What is Database IP address?"
read db_ip;
echo "What is GUI IP address?"
read gui_ip;
echo "What is this server ID?"
read server_id;

#mor.conf
replace_value "$mor_conf" "hostname" "$db_ip"
replace_value "$mor_conf" "server_id" "$server_id"

#res_mysql.conf
replace_value "$res_mysql_conf" "dbhost" "$db_ip"

#res_config_mysql.conf

if [ -f $res_config_mysql_conf ]; then
    replace_value "$res_config_mysql_conf" "dbhost" "$db_ip"
else
    report "$res_config_mysql_conf not found" 3
fi

#agi-bin/mor.conf
replace_value "$agi_conf" "host" "$db_ip"
replace_value "$agi_conf" "server_id" "$server_id"

#mor_mnp.conf
if [ -f "mnp_conf" ]; then
    replace_value "mnp_conf" "host" "$db_ip"
    replace_value "mnp_conf" "server_id" "$server_id"
fi

#manager.conf
grep $gui_ip $manager_conf &>/dev/null
if [ "$?" != 0 ]; then
    echo "permit=$gui_ip/255.255.255.255" >> $manager_conf
else
    report "Following line already exist on $manager_conf so no changes were made" 3
    grep $gui_ip $manager_conf
fi
