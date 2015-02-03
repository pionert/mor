#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  Script checks /etc/asterisk/extensions_mor.conf for these settings if Asterisk 1.4.18.1< is detected:
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
#    OK             /etc/asterisk/extensions_mor.conf
#
#   If some settings are missing - each setting will be reported
#
#
#   If there are any problem with this script - with problem  report please attach a full test-fix log, and this config file: /etc/asterisk/extensions_mor.conf


. /usr/src/mor/x5/framework/bash_functions.sh

#----------------------------

check_extensions_mor_conf()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  Script checks /etc/asterisk/extensions_mor.conf for these settings if Asterisk 1.4.18.1< is detected:
    #
    asterisk_current_version
    if [ "$?" != "1" ]; then
        which_version_is_bigger "$ASTERISK_VERSION" "1.4.18.1"
        if [ "$?" == "1" ]; then    #first passed parameter was bigger --> we have a newer asterisk version as we wanted.
            #separator "Checking /etc/asterisk/extensions_mor.conf"
            ALL_OK=0    #RESETTING
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf ";Asterisk 1.4.24.1+ support" 1
            report ';Asterisk 1.4.24.1+ support' "$?" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,1,Set(MOR_DIALSTATUS=${DIALSTATUS})' 1
            report 'exten => h,1,Set(MOR_DIALSTATUS=${DIALSTATUS})' "$?" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,n,Set(MOR_RDURATION=${CDR(rduration)})' 1
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,2,Set(MOR_RDURATION=${CDR(rduration)})' 1
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_RDURATION=${CDR(rduration)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,n,Set(MOR_RBILLSEC=${CDR(rbillsec)})' 1
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,3,Set(MOR_RBILLSEC=${CDR(rbillsec)})' 1
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_RBILLSEC=${CDR(rbillsec)})' "$STATUS" FAILED
            #---

            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,n,Set(MOR_CLID=${CALLERID(all)})' 1
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,4,Set(MOR_CLID=${CALLERID(all)})' 1
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_CLID=${CALLERID(all)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,n,Set(MOR_CHANNEL=${CDR(channel)})' 1
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,5,Set(MOR_CHANNEL=${CDR(channel)})' 1
                    STATUS="$?"
                fi
                report 'exten => h,n,Set(MOR_CHANNEL=${CDR(channel)})' "$STATUS" FAILED
            #---
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,n,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 1
                STATUS="$?"
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,6,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 1
                    STATUS="$?"
                fi
                if [ "$STATUS" != "0" ]; then
                    check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf 'exten => h,7,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' 1
                    STATUS="$?"
                fi
                report 'exten => h,n,NoOp(HANGUP CAUSE: ${HANGUPCAUSE})' "$STATUS" FAILED

            if [ "$ALL_OK" == "0" ]; then
                report "/etc/asterisk/extensions_mor.conf" 0
                exit 0
            fi

        fi
    fi
}

macroMorAnswer()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This functions checks /etc/asterisk/extensions_mor.conf if it has these lines:
    #   [macro-mor_answer]
    #   exten => s,1,AGI(mor_answer_mark)
    #
    #   If not - these lines are added and status is reported as "Fixed"
    #


    check_if_setting_match /etc/asterisk/extensions_mor.conf "\[macro-mor_answer\]" "[macro-mor_answer]"
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then #header [macro-mor_answer] is found

        check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf "exten => s,1,AGI(mor_answer_mark)" 1
        STATUS2="$?"
        if [ "$STATUS2" == "0" ]; then
            report "/etc/asterisk/extensions_mor.conf: exten => s,1,AGI(mor_answer_mark)" 0
            return 0
        elif [ "$STATUS2" == "3" ]; then
            report "/etc/asterisk/extensions_mor.conf not found" 1
            return 1
        elif [ "$STATUS2" == "1" ]; then
            #taisome
            _mor_time
            cp /etc/asterisk/extensions_mor.conf /etc/asterisk/extensions_mor.conf_backup_$mor_time
            awk '{print} /\[macro-mor_answer\]/{print "\nexten => s,1,AGI(mor_answer_mark)"}' /etc/asterisk/extensions_mor.conf > /etc/asterisk/extensions_mor.conf_mv
            mv /etc/asterisk/extensions_mor.conf_mv /etc/asterisk/extensions_mor.conf

            #checking again if we really fixed
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf "exten => s,1,AGI(mor_answer_mark)" 1
            STATUS="$?"
            if [ "$STATUS" == "0" ]; then
                report "/etc/asterisk/extensions_mor.conf: exten => s,1,AGI(mor_answer_mark)" 4
                report "Asterisk restart is needed" 6
                return 4
            else
                report "/etc/asterisk/extensions_mor.conf: exten => s,1,AGI(mor_answer_mark)" 1
                return 1
            fi
        else
            echo
            report "Unexpected error during check in macro-mor-answer function" 1
            echo "STATUS: $STATUS"
            #exit 1
        fi
    elif [ "$STATUS" == "2" ]; then #header [macro-mor_answer] is not found
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf "exten => s,1,AGI(mor_answer_mark)" 1
            STATUS2="$?"
            if [ "$STATUS2" == "0" ]; then
                _mor_time
                cp /etc/asterisk/extensions_mor.conf /etc/asterisk/extensions_mor.conf_backup_$mor_time
                awk '{print} /switch => Realtime\/mor_voicemail@realtime_ext/{print "\n[macro-mor_answer]\n"}' /etc/asterisk/extensions_mor.conf > /etc/asterisk/extensions_mor.conf_mv
                mv /etc/asterisk/extensions_mor.conf_mv /etc/asterisk/extensions_mor.conf
            elif [ "$STATUS2" == "3" ]; then
                report "/etc/asterisk/extensions_mor.conf not found" 1
                return 1
            elif [ "$STATUS2" == "1" ]; then
                _mor_time
                cp /etc/asterisk/extensions_mor.conf /etc/asterisk/extensions_mor.conf_backup_$mor_time
                awk '{print} /switch => Realtime\/mor_voicemail@realtime_ext/{print "\n[macro-mor_answer]\nexten => s,1,AGI(mor_answer_mark)"}' /etc/asterisk/extensions_mor.conf > /etc/asterisk/extensions_mor.conf_mv
                mv /etc/asterisk/extensions_mor.conf_mv /etc/asterisk/extensions_mor.conf
            fi

            #checking again if we really fixed
            check_if_settings_match_exactly /etc/asterisk/extensions_mor.conf "exten => s,1,AGI(mor_answer_mark)" 1
            if [ "$?" == "0" ]; then
                report "/etc/asterisk/extensions_mor.conf: exten => s,1,AGI(mor_answer_mark)" 4
                report "Asterisk restart is needed" 6
            else
                report "/etc/asterisk/extensions_mor.conf: exten => s,1,AGI(mor_answer_mark)" 1
            fi
    fi
}
#================= MAIN ====================
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi

check_extensions_mor_conf

macroMorAnswer
