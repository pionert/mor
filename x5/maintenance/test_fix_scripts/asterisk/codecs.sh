#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

#----------------------------
codecs_status()
{
   _g729_STATUS=`asterisk -vvvvrx 'core show translation' 2> /dev/null | grep "g729" | (read; awk '{print $3}')`;
   _g723_STATUS=`asterisk -vvvvrx 'core show translation' 2> /dev/null | grep "g723" | (read; awk '{print $3}')`;

   if [ "$_g729_STATUS" != "-" ] && [ "$_g723_STATUS" != "-" ]; then
        return 0;
    else
        return 1;
   fi
}

#----------------------------

asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi

codecs_status
if [ "$?" == "0" ]; then
    report "Asterisk codecs G723/G729" 0
    exit 0
else
    /usr/src/mor/sh_scripts/codecs_install.sh
    codecs_status
    if [ "$?" == "0" ]; then
        report "Asterisk codecs G723/G729" 4  #report that fixed
        exit 4
    else
        report "Asterisk codecs G723/G729" 1
        exit 1
    fi

fi
