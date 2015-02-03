#! /bin/bash

. /usr/src/mor/x6/framework/bash_functions.sh


if [ -f '/usr/local/mor/mor_retrieve_peers' ]; then
    report "mor_retrieve_peers present" 0
else
    cd /usr/src/mor/x6/asterisk/ami
    ./install.sh &> /dev/null

    if [ -f '/usr/local/mor/mor_retrieve_peers' ]; then
	report "mor_retrieve_peers installed" 4
    else
	report "mor_retrieve_peers AMI script not present, failed to install" 0
    fi
fi
