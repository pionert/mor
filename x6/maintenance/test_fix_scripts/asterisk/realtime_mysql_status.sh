#! /bin/sh

. /usr/src/mor/x6/framework/bash_functions.sh

#-------------------

realtime_mysql_status()
{
   _MYSQL_STAT=`asterisk -vvvvrx 'realtime mysql status' | grep "onnected to"`
   if [ -n "$_MYSQL_STAT" ];
      then
         return 0;
      else
         return 1;
   fi
}
#-------------------

asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi

realtime_mysql_status
if [ "$?" == "0" ]; then
    report "Asterisk and MySQL connectivity ok (realtime mysql status)" 0
    exit 0
else
    report "Asterisk and MySQL connectivity problem (realtime mysql status)" 1
    exit 1
fi
