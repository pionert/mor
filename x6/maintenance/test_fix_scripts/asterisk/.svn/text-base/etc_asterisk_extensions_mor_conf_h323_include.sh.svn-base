#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:
#
#       This script checks that:
#
    #1. /etc/asterisk/extensions_mor_h323.conf must be included into extensions_mor.conf
    #2. /etc/asterisk/extensions_mor.conf must be included in extensions.conf
    #3. /etc/asterisk/asterisk.conf must have uncommented line: execincludes=yes
    #4. /etc/asterisk/h323.conf must have a line at the end: #exec /usr/local/mor/mor_ast_h323
#
. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
mor_ast_h323_exec_directive()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    This function checks if config /etc/asterisk/h323.conf  has '#exec /usr/local/mor/mor_ast_h323 line present'

    Directive=`grep "#exec" /etc/asterisk/h323.conf | awk -F";" '{print $1}' | grep '/usr/local/mor/mor_ast_h323' | awk '{print $2}'`

    if [ "$Directive" == "/usr/local/mor/mor_ast_h323" ]; then
        report "/etc/asterisk/h323.conf: #exec /usr/local/mor/mor_ast_h323" 0
    else
        echo '#exec /usr/local/mor/mor_ast_h323' >> /etc/asterisk/h323.conf
        Directive=`grep "#exec" /etc/asterisk/h323.conf | awk -F";" '{print $1}' | grep '/usr/local/mor/mor_ast_h323' | awk '{print $2}'`

        if [ "$Directive" == "/usr/local/mor/mor_ast_h323" ]; then
            report "/etc/asterisk/h323.conf: #exec /usr/local/mor/mor_ast_h323" 4
        else
            report "/etc/asterisk/h323.conf: #exec /usr/local/mor/mor_ast_h323" 1
        fi
    fi
}
#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi


separator "Checking various Asterisk includes, exec's"

asterisk_include_directive /etc/asterisk/extensions_mor.conf "extensions_mor_h323.conf"
    report "/etc/asterisk/extensions_mor.conf: #include extensions_mor_h323.conf" "$?"

asterisk_include_directive /etc/asterisk/extensions.conf "extensions_mor.conf"
    report "/etc/asterisk/extensions.conf: #include extensions_mor.conf" "$?"

check_if_setting_match_fix /etc/asterisk/asterisk.conf "execincludes" "execincludes=yes"
    report "/etc/asterisk/asterisk.conf: execincludes=yes" "$?"

# check if #exec /usr/local/mor/mor_ast_h323 exists in /etc/asterisk/h323.conf
#------------------------
mor_ast_h323_exec_directive
