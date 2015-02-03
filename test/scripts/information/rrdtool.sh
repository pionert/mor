#! /bin/sh
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script that rrdtool is installed

. /usr/src/mor/test/framework/bash_functions.sh

check_and_install_rrdtool()
{
    if [  ! -f "/usr/bin/rrdtool" ]; then
        yum -y install rrdtool
        if [  ! -f "/usr/bin/rrdtool" ]; then
            report "Failed to install rrdtool" 1
        else
            report "rrdtool was installed in order elunia stats would work correctly" 4
        fi
    fi
}
check_and_install_rrdtool
