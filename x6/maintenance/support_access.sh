#! /bin/bash
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2010-2013
# About:    Support GUI access script

. /usr/src/mor/x6/framework/bash_functions.sh

control_c() {
    echo ""
    echo "Don't do this!"
    echo "pcrack NOT terminated and still running"
}
trap control_c SIGINT

wait_user2() {   echo -e "\nPress enter to continue\n\n"; read; echo -e "\n\n"; }

wait_sleep()
{
    for (( sleep_time=15; sleep_time>0; sleep_time-- ))
    do
        echo "You have $sleep_time seconds to login..."
        sleep 1
    done
}

mor_admin_tmp_pass_change()
{
        # if arg 1 is passed - the script executes that command or other script (the gui login/pass then will be admin/admin)

        if [ -f "/root/mor_gui_admin_pass_hash" ]; then echo -e "\E[31m/root/mor_gui_admin_pass_hash found, please correct your mistakes manually, I won't overwrite user's pass hash backup\E[37m]"; return 1; fi
        mysql_connect_data_v2 > /dev/null
        if [ $? == 1 ]; then
                echo "Failed to get database data, exiting..";
                return 1;
        fi
        #==================================
        current_pass=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select password from users where id='0';" | sed -n '2,2 p'`                    #backing up the current user password hash
        current_username=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select username from users where id = '0';" | sed -n '2,2 p'`
        echo "$current_username">> /root/mor_gui_admin_username;
        echo "$current_pass" >> /root/mor_gui_admin_pass_hash;
                if [ $? != 0 ];
                then
                        echo "Failed to get the current admin username or pass";
                        return 1;
                fi
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "update users set username = 'admin' where id = 0;"
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "update users set password = 'd033e22ae348aeb5660fc2140aec35850c4da997' where id = 0;"        #setting the default pass

        if [ $? != 0 ]
        then   
           echo "Failed to set default username orpass";
           return 1;
        fi

        if [ "$1" == "WAIT" ] || [ "$1" == "wait" ]
        then
            wait_user2
        else
            wait_sleep
        fi


        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "update users set username = '$current_username' where id = 0;"
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "update users set password = '$current_pass' where id = 0;"   #restoring user's original pass
        if [ $? != 0 ]; then
            echo -e "Failed to restore the original username or pass, you can find the original user pass hash in:\n /root/mor_gui_admin_username and /root/mor_gui_admin_pass_hash"
            return 1;
        fi

        echo "Original username and pass has been restored"
        echo "Cleaned the mess..";
        rm -rf /root/mor_gui_admin_username
        rm -rf /root/mor_gui_admin_pass_hash
        return 0
}

mor_admin_tmp_pass_change "$1"
