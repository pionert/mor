#! /bin/sh


. /usr/src/mor/x5/framework/bash_functions.sh

#----------------------------
check_config_line_and_execute_cmd2()  #copied from mor install functions and modified to not fix the problem, jus diagnose it
{	#----------------------------
	#function checks file for a specific line and executes a cmd if a line does not exist
	#arg1=path to file
	#arg2=string to check
	#arg3=what to write in report
	#arg4=cmd to execute
	#-----------------------------

cat "$1" | grep "^$2" &> /dev/null
	if [ $? == 1 ]; then
		#$4  #executing cmd
		cat "$1" | grep "^$2" &> /dev/null
		if [ $? == 1 ]; then
            report "$3. Modified line or incorrect db name value is set for this variable in /etc/asterisk/extconfig.conf" 1
            #report_to_stdout 1 "$3"
        else
             report "$3"  5
            #report_to_stdout 5 "$3"
		fi
	fi

	if [ $? == 0 ]; then
        report "$3" 0
		#report_to_stdout 0 "$3"
	fi
}

check_asterisk_extcfg()
{
    #   Arguments:
    #       $1 - database name

    local DATABASE_NAME="$1"


    separator "Checking /etc/asterisk/extconfig.conf"

	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "iaxusers = mysql,$DATABASE_NAME,devices" "Checking iaxusers" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "iaxpeers = mysql,$DATABASE_NAME,devices" "Checking iaxpeers" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "sipusers = mysql,$DATABASE_NAME,devices" "Checking sipusers" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "sippeers = mysql,$DATABASE_NAME,devices" "Checking sippeers" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "realtime_ext => mysql,$DATABASE_NAME,extlines" "Checking realtime_ext" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "voicemail => mysql,$DATABASE_NAME,voicemail_boxes" "Checking voicemail" "cp /usr/src/mor/asterisk-conf/extconfig.conf /etc/asterisk/extconfig.conf"
}

check_asterisk_extcfg_ast18()
{
    separator "Checking /etc/asterisk/extconfig.conf for Asterisk 1.8"

	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "iaxusers => mysql,general,devices" "Checking iaxusers" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "iaxpeers => mysql,general,devices" "Checking iaxpeers" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "sipusers => mysql,general,devices" "Checking sipusers" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "sippeers => mysql,general,devices" "Checking sippeers" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "extensions => mysql,general,extlines" "Checking extensions" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
	check_config_line_and_execute_cmd2 "/etc/asterisk/extconfig.conf" "voicemail => mysql,general,voicemail_boxes" "Checking voicemail" "cp /usr/src/mor/asterisk-conf/ast_1.8/extconfig.conf /etc/asterisk/extconfig.conf"
}
#================= MAIN ====================
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

asterisk_current_version
if [ "$ASTERISK_BRANCH" == "1.8" ]; then
    check_asterisk_extcfg_ast18
else
    mysql_connect_data_v2
    check_asterisk_extcfg "$DB_NAME"
fi
