#! /bin/sh
#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2012
#   About:  This script checks if there are loaded 3 Asterisk fax modules: app_rxfax.so  app_txfax.so app_nv_faxdetect.so

. /usr/src/mor/test/framework/bash_functions.sh

#----------------------------
fax2email_status()
{
   _F2E_STAT=`asterisk -vvvvrx 'module show like fax' | grep "app_nv_faxdetect.so\|app_txfax.so\|app_rxfax.so" | wc -l`
   if [ "$_F2E_STAT" == "3" ];
      then
         return 0;
      else
         return 1;
   fi
}

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
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi


#-------
asterisk_current_version
if [ "$ASTERISK_BRANCH" == "1.8" ]; then
    fax2email_status_ast18
    if [ "$?" == "0" ]; then
        report "fax2email: asterisk -vvvvrx 'module show like fax' 2 loaded modules were found" 0
        exit 0
    else
        asterisk -nrx "module unload res_fax.so"
        asterisk -nrx "module unload res_fax_spandsp.so"
    
        asterisk -nrx "module load res_fax.so"
        asterisk -nrx "module load res_fax_spandsp.so"

        fax2email_status_ast18
        if [ "$?" == "0" ]; then
            report "fax2email: asterisk -vvvvrx 'module show like fax' 2 loaded modules were found" 4
            exit 4
        else
            report "fax2email:  asterisk -vvvvrx 'module show like fax' 2 loaded modules not found " 1
            exit 1
        fi
    fi
else
    fax2email_status
    if [ "$?" == "0" ]; then
        report "fax2email: asterisk -vvvvrx 'module show like fax' 3 loaded modules were found" 0
        exit 0
    else
        asterisk -nrx "module unload app_txfax.so"
        asterisk -nrx "module unload app_rxfax.so"
        asterisk -nrx "module unload app_nv_faxdetect.so"
    
        asterisk -nrx "module load app_txfax.so"
        asterisk -nrx "module load app_rxfax.so"
        asterisk -nrx "module load app_nv_faxdetect.so"
        fax2email_status
        if [ "$?" == "0" ]; then
            report "fax2email: asterisk -vvvvrx 'module show like fax' 3 loaded modules were found" 4
            exit 4
        else
            report "fax2email:  asterisk -vvvvrx 'module show like fax' 3 loaded modules not found " 1
            exit 1
        fi
    fi
fi