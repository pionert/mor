#!/bin/bash

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/mor_install_functions.sh


if [ -f /usr/lib/asterisk/modules/app_mor.so ]; then

    report "Core present, will not install 10cc version" 3

else

    report "Core not present, installing 10cc version" 3

    cp -fr /usr/src/mor/x6/core/mor.conf /etc/asterisk

    cd /usr/lib/asterisk/modules/

    processor_type
    if [ "$_64BIT" == "1" ]; then
	# TODO 64 newest from the server
	cp -fr /usr/src/mor/x6/core/app_mor.so_64 /usr/lib/asterisk/modules/app_mor.so
    else
	# downloads 32 bit newest stable core from the server
	wget http://demo.kolmisoft.com/billing/core/app_mor.so
    fi

    chmod 777 /usr/lib/asterisk/modules/app_mor.so

    asterisk -vvrx "module load app_mor.so"

    # TODO need to check if for sure
    report "Core 10cc version installed" 0

fi
