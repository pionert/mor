#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  Script checks /etc/asterisk/extensions_mor.conf for these settings:
#
#       exten => _X.,1,Wait(1) 
#       exten => _X.,2,Playback(mor_login_fail|noanswer) 
#       exten => _X.,3,Playtones(congestion) 
#       exten => _X.,4,Congestion 
#
#   if these settings are found - they are changed to one line:
#
#       exten => _X.,1,Goto(mor_local,${EXTEN},1)
#
#   Returns:
#       0   -   the settings were already OK
#       1   -   failed to fix
#       4   -   fixed

. /usr/src/mor/x5/framework/bash_functions.sh

#-------------Functions---------------

check_if_old_options_are_present()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  function checks /etc/asterisk/extensions_mor.conf for these settings:
    #
    #   Returns:
    #       0   -   OK, config is up to date
    #       1   -   Failed, config is not up to date
                
    sed '/^$/d' /etc/asterisk/extensions_mor.conf | grep -A 4 "please_login" | sed 's/ |\t//g' | grep "exten => _X.,4,Congestion" &> /dev/null
    if [ "$?" == "0" ]; then
        return 1; #old pattern found
    else
        local repeats=`grep  please_login /etc/asterisk/extensions_mor.conf | wc -l`
        if [ "$repeats" != "1" ]; then
            report "/etc/asterisk/extensions_mor.conf has duplicate [please_login] entry" 1;
            exit 1;
        fi
        return 0; #old pattern not found - OK
    fi
}
#------------------------------------
check_if_new_option_present()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  function checks /etc/asterisk/extensions_mor.conf has an option:
    #       exten => _X.,1,Goto(mor_local,${EXTEN},1)
        
    #
    #   Returns:
    #       0   -   OK, new option is present
    #       1   -   Failed, new option is not present

    local _OPTION=`sed 's/ //g' /etc/asterisk/extensions_mor.conf | grep -A 1 please_login | (read; cat)`
    if [ "$_OPTION" == "exten=>_X.,1,Goto(mor_local,\${EXTEN},1)" ]; then
        return 0;
    else
        return 1;
    fi

}
#-------------------------------------
fix_extension_option()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  function fixes /etc/asterisk/extensions_mor.conf to have this setting:
    #       exten => _X.,1,Goto(mor_local,${EXTEN},1
    #

    mkdir -p  /usr/local/mor/backups/asterisk/etc
    _mor_time;

    #backup
    cp  /etc/asterisk/extensions_mor.conf /usr/local/mor/backups/asterisk/etc/extensions_mor.conf_$mor_time

    # Prepare new configuration
        #remove wrong configuration
        sed "/\[please_login\]/,/exten => _X.,4,Congestion/d" /etc/asterisk/extensions_mor.conf  > /tmp/extensions_mor.conf$$

        #add correct configuration
        sed '/s,1,AGI(mor_answer_mark)/a\\n[please_login\]\nexten => _X.,1,Goto(mor_local,${EXTEN},1)' /tmp/extensions_mor.conf$$ >  /tmp/extensions_mor.conf_2
        
        #test the new configuration if the required modification exists only 1 time
        local repeats=`grep  please_login /tmp/extensions_mor.conf_2 | wc -l`
        if [ "$repeats" != "1" ]; then
            report "Failed to create a new configuration, /etc/asterisk/extensions_mor.conf left as is" 1;
            exit 1
        fi
            
        mv /tmp/extensions_mor.conf_2 /etc/asterisk/extensions_mor.conf
        asterisk -vvvrx 'extensions reload' &> /dev/null

    #clean up
    rm -rf /tmp/extensions_mor.conf_2 /tmp/extensions_mor.conf$$
}
#====== MAIN ======

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi



check_if_old_options_are_present
if [ "$?" == "0" ]; then
    check_if_new_option_present
    if [ "$?" == "0" ]; then
        report "[please_login] /etc/asterisk/extensions_mor.conf" 0
        exit 0
    fi
else
    fix_extension_option
    check_if_old_options_are_present
    if [ "$?" == "0" ]; then
        check_if_new_option_present
        if [ "$?" == "0" ]; then
            report "[please_login] /etc/asterisk/extensions_mor.conf" 4
        else
            report "[please_login] /etc/asterisk/extensions_mor.conf" 1
        fi
    else
        report "[please_login] /etc/asterisk/extensions_mor.conf" 1
    fi
fi
#------------





