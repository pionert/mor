#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

#-------------------
selinux_check_if_disabled()
{
    SEL=`sestatus | grep "disabled"`

    if [ -n "$SEL" ];
    then
        return 0;
    else
        return 1;
    fi
}
#-------------------
selinux_disable()
{
    setenforce 0
    echo -e "SELINUX=disabled\nSELINUXTYPE=targeted" > /etc/selinux/config
    echo 0 > /selinux/enforce
}
#-------------------
selinux_test_and_fix()
{
    if [ ! -f "/etc/redhat-release" ]; then
        echo "Test is written for CentOS/RedHat, please get one of those distributions";
        exit 1;
    fi

    selinux_check_if_disabled
    if [ "$?" == "0" ]; then
        report "SElinux disabled" 0
        exit 0
    else
        selinux_disable
        selinux_check_if_disabled
        if [ "$?" == "0" ]; then
            report "SElinux" 4
            exit 4
        else
            report "SElinux" 1
            exit 1
        fi
    fi
}
#------------ MAIN -----------------
selinux_installed
if [ "$?" == "0" ]; then
    selinux_test_and_fix
fi
