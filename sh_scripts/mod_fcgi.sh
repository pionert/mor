#! /bin/sh

# Author: Nerijus Sapola
# Company: Kolmisoft
# Year: 2011 
# About: script updates mod_fcgid to 2.3.6 version and updates /etc/httpd/conf.d/mod_fcgid_include.conf with optimized values.
 
. /usr/src/mor/test/framework/bash_functions.sh
 
#------VARIABLES-------------
 
#----- FUNCTIONS ------------

sharemempath_exist()
{
    grep 'SharememPath' /etc/httpd/conf.d/mod_fcgid_include.conf &>/dev/null
    if [ "$?" != "0" ]; then
        return 1; # sharemempath not exist on mod_fcgid_include.conf
    else
        return 0; # sharemempath already exist on mod_fcgid_include.conf
    fi
}

update_to_fcgid_2_3_6()
{
    if [ -f "/usr/src/mor/test/files/httpd/fcgid/mod_fcgid_include.conf" ]; then
        echo ok
    else
        report "/usr/src/mor/test/files/httpd/fcgid/mod_fcgid_include.conf not found. Please update MOR sources." 1;
        exit 1;
    fi

    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bfrfcgidupdate
    if [ "$?" != "0" ]; then
        report "Cannot copy http.conf. Check permissions" 1;
        exit 1;
    fi

    rm -f /usr/src/mod_fcgid-2.3.6.tar.gz

    cd /usr/src/ 
    wget http://www.kolmisoft.com/packets/mod_fcgid-2.3.6.tar.gz
    if [ "$?" != "0" ]; then
        report "Cannot download mod_fcgid-2.3.6.tar.gz" 1;
        exit 1;
    fi
    tar xvfz mod_fcgid-2.3.6.tar.gz
    cd mod_fcgid-2.3.6 
    ./configure.apxs 
    make 
    make install

    rm -f /etc/httpd/conf/httpd.conf
    cp /etc/httpd/conf/httpd.conf_bfrfcgidupdate /etc/httpd/conf/httpd.conf

    mv /etc/httpd/conf.d/mod_fcgid_include.conf /etc/httpd/conf.d/mod_fcgid_include.conf_bfrfcgidupdate
    cp /usr/src/mor/test/files/httpd/fcgid/mod_fcgid_include.conf /etc/httpd/conf.d/mod_fcgid_include.conf

    /etc/init.d/httpd restart
    chmod 777 /var/log/httpd/fcgid_shm
    
    sharemempath_exist
    if [ "$?" = "0" ]; then
        report "FCGID Updated" 4
    else
        report "FCGID Update" 1
    fi
}
#--------MAIN -------------

sharemempath_exist
if [ "$?" = "1" ]; then
    report "Updating fcgid" 3;
    update_to_fcgid_2_3_6;
fi
