#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script tests if h323 module is loaded

. /usr/src/mor/test/framework/bash_functions.sh

#----------------------------
h323_status()
{
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This function tests if h323 module is loaded

#   Returns:
#   0 - OK, module is loaded
#   1 - Failed, module is not loaded
#

   _h323_STAT=`asterisk -vvvvrx 'module show like h323' | grep "1 modules loaded"`
   if [ -n "$_h323_STAT" ];
      then
         return 0;
      else
         return 1;
   fi
}

#================= MAIN ====================
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi

h323_status
if [ "$?" == "0" ]; then
    report "H323 module: asterisk -vvvvrx 'module show like h323" 0
    exit 0
else
    report "H323 module: asterisk -vvvvrx 'module show like h323" 1
    exit 1
fi
