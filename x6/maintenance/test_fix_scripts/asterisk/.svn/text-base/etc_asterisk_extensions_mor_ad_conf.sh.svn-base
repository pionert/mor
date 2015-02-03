#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  Script checks /etc/asterisk/extensions_mor_ad.conf for these settings if Asterisk 1.4.18.1< is detected:
#
#   ;Asterisk 1.4.24.1+ support
#   exten => h,1,Set(MOR_DIALSTATUS=${DIALSTATUS})
#   exten => h,n,Set(MOR_RDURATION=${CDR(rduration)})
#   exten => h,n,Set(MOR_RBILLSEC=${CDR(rbillsec)})
#   exten => h,n,Set(MOR_CLID=${CALLERID(all)})
#   exten => h,n,Set(MOR_CHANNEL=${CDR(channel)})
#   exten => h,n,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})
#
#   If all settings are OK the script reports only one time:
#
#    OK             /etc/asterisk/extensions_mor_ad.conf
#
#   If some settings are missing - each setting will be reported
#
#
#   If there are any problem with this script - with problem  report please attach a full test-fix log, and this config file: /etc/asterisk/extensions_mor_ad.conf


. /usr/src/mor/x6/framework/bash_functions.sh

#----------------------------

check_extensions_mor_ad_conf()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  Script checks /etc/asterisk/extensions_mor_ad.conf for these settings if Asterisk 1.4.18.1< is detected:
    #
    asterisk_current_version
    if [ "$?" != "1" ]; then
        which_version_is_bigger "$ASTERISK_VERSION" "1.4.18.1"
        if [ "$?" == "1" ]; then    #first passed parameter was bigger --> we have a newer asterisk version as we wanted.
            #separator "Checking /etc/asterisk/extensions_mor_ad.conf"
            ALL_OK=0    #RESETTING
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf ";Asterisk 1.4.24.1+ support" 2
            report ';Asterisk 1.4.24.1+ support' "$?" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,1,Set(MOR_DIALSTATUS=${DIALSTATUS})' 2
            report 'exten => h,1,Set(MOR_DIALSTATUS=${DIALSTATUS})' "$?" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,n,Set(MOR_RDURATION=${CDR(rduration)})' 2
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,2,Set(MOR_RDURATION=${CDR(rduration)})' 2
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_RDURATION=${CDR(rduration)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,n,Set(MOR_RBILLSEC=${CDR(rbillsec)})' 2
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,3,Set(MOR_RBILLSEC=${CDR(rbillsec)})' 2
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_RBILLSEC=${CDR(rbillsec)})' "$STATUS" FAILED
            #---

            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,n,Set(MOR_CLID=${CALLERID(all)})' 2
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,4,Set(MOR_CLID=${CALLERID(all)})' 2
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_CLID=${CALLERID(all)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,n,Set(MOR_CHANNEL=${CDR(channel)})' 2
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,5,Set(MOR_CHANNEL=${CDR(channel)})' 2
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_CHANNEL=${CDR(channel)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,n,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 2
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,6,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 2
                    STATUS="$?"
                fi
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor_ad.conf 'exten => h,7,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 2
                    STATUS="$?"
                fi
                report 'exten => h,n,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' "$STATUS" FAILED

            if [ "$ALL_OK" == "0" ]; then
                report "/etc/asterisk/extensions_mor_ad.conf" 0
                exit 0
            fi

        fi
    fi
}
#================= MAIN ====================
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi

check_extensions_mor_ad_conf
