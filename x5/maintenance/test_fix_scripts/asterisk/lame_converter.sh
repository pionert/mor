#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

#----------------------------
lame_test()
{
   _lame=`which lame  2> /dev/null`
    if [ $? == 0 ];   then
        return 0;
	else
        return 1;
    fi
}
#----------------------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

lame_test
if [ "$?" == "0" ]; then
    report "Lame converter" 0
    exit 0
else
    report "Lame converter" 1
    exit 1
fi
