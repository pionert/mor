#! /bin/sh
# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script checks if /etc/httpd/conf.d/mod_fcgid_include.conf matches default configuration provided by Kolmisoft, if not - it is fixed to match current default configuration

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#----------------------------
_mor_time()
{
	mor_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
}
fcgid_config_test()
{
    if [ -r /etc/redhat-release  ]; then
        MOR_SETTINGS_LIST=("LoadModule fcgid_module modules/mod_fcgid.so" "<IfModule mod_fcgid.c>" "IdleTimeout 600" "BusyTimeout 6000" "ProcessLifeTime 3600" "MaxProcessCount 16" "DefaultMinClassProcessCount 3" "DefaultMaxClassProcessCount 30" "IPCConnectTimeout 8" "IPCCommTimeout 6000" "</IfModule>")

        for element in $(seq 0 $((${#MOR_SETTINGS_LIST[@]} - 1)))   #will go throw the config and check against every setting mentioned in variable MOR_SETTINGS_LIST
        do
            grep "${MOR_SETTINGS_LIST[$element]}" /etc/httpd/conf.d/mod_fcgid_include.conf &> /dev/null
            if [ "$?" != "0" ]; then
                return 1
            fi
        done
    else
        report "Your OS is not supported by fcgid.sh script"
        exit 0;
    fi
}
#================= MAIN ====================
apache_is_running
if [ "$?" != "0" ]; then
    exit 1;
fi

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

mor_gui_current_version
mor_version_mapper $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
    exit 0
fi

fcgid_config_test

if [ "$?" == "0" ]; then
    report "fcgid_config" 0
    exit 0
else
    mkdir -p /usr/local/mor/backups/cfg
    cp /etc/httpd/conf.d/mod_fcgid_include.conf /usr/local/mor/backups/cfg/mod_fcgid_include.conf$mor_time

    echo "LoadModule fcgid_module modules/mod_fcgid.so
<IfModule mod_fcgid.c>
    IdleTimeout 600
    BusyTimeout 6000
    ProcessLifeTime 3600
    MaxProcessCount 16
    DefaultMinClassProcessCount 3
    DefaultMaxClassProcessCount 30
    IPCConnectTimeout 8
    IPCCommTimeout 6000
</IfModule>" > /etc/httpd/conf.d/mod_fcgid_include.conf

    fcgid_config_test
    if [ "$?" != "0" ]; then
        report "fcgid_config" 1
        exit 1
    else
        report "fcgid_config" 4
        /etc/init.d/httpd restart &> /dev/null
    fi
fi
