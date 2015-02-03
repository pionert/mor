#! /bin/sh
#   Author: Nerijus
#   Year:   2014
#   About:  This script checks necessary Asterisk modules are loaded

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

fax2email_status_ast18() # function for Asterisk 1.8
{
   _F2E_STAT=`asterisk -vvvvrx 'module show like fax' | grep "res_fax.so\|res_fax_spandsp.so" | wc -l`
   if [ "$_F2E_STAT" == "2" ];
      then
         return 0;
      else
         return 1;
   fi
}

#================= MAIN ====================
read_mor_asterisk_settings
if [ "$ASTERISK_PRESENT" == 0 ]; then
    exit 0;
fi

asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    report "Asterisk is not running while it suppose to" 1
    exit 1
fi

#FAX2EMAIL modules
fax2email_status_ast18
if [ "$?" == "0" ]; then
    report "fax2email: asterisk -vvvvrx 'module show like fax' 2 loaded modules were found" 0
else
    asterisk -nrx "module unload res_fax.so"
    asterisk -nrx "module unload res_fax_spandsp.so"
    
    asterisk -nrx "module load res_fax.so"
    asterisk -nrx "module load res_fax_spandsp.so"

    fax2email_status_ast18
    if [ "$?" == "0" ]; then
        report "fax2email: asterisk -vvvvrx 'module show like fax' 2 loaded modules were found" 4
    else
        report "fax2email:  asterisk -vvvvrx 'module show like fax' 2 loaded modules not found " 1
    fi
fi

#Timing modules
timing_modules_loaded=`asterisk -vvvvrx 'module show like res_tim' | grep "modules loaded" | awk '{print $1}'`
if [ "$timing_modules_loaded" -gt "0" ] && [ "$timing_modules_loaded" -lt "10" ]; then
    report "Timing modules were found loaded" 0
else
    report "Timing modules are not loaded or failed to check. Run asterisk -vvvvrx 'module show like res_tim' to check" 1
fi

grep noload /etc/asterisk/modules.conf | grep res_timing_pthread.so &>/dev/null
noload_pthread="$?"
grep noload /etc/asterisk/modules.conf | grep res_timing_timerfd.so &>/dev/null
noload_timerfd="$?"

if [ "$noload_pthread" == "0" ] && [ "$noload_timerfd" == "0" ]; then
    report "Both timining modules (res_timing_pthread.so and res_timing_timerfd.so) are in noload list" 1
elif [ "$noload_pthread" == "0" ] && [ ! -f /usr/lib/asterisk/modules/res_timing_timerfd.so ]; then
    report "Module res_timing_pthread.so is in noload list and res_timing_timerfd.so is not installed" 1
elif [ "$noload_timerfd" == "0" ] && [ ! -f /usr/lib/asterisk/modules/res_timing_pthread.so ]; then
    report "Module res_timing_pthread.so is in noload list and res_timing_timerfd.so is not installed" 1
else
    report "Timing modules loading is configured correctly" 0
fi

#H323 module
h323_modules_loaded=`asterisk -vvvvrx 'module show like h323' | grep "modules loaded" | awk '{print $1}'`
if [ "$h323_modules_loaded" == "1" ]; then
        report "H323 module is loaded" 0
    else
        report "H323 module is not loaded. Run asterisk -vvvvrx 'module show like h323' to check" 1
fi
