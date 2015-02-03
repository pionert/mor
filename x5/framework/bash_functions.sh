#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2010
# About:    MOR Billing platform testing and fixing scripts Bash framework


if [ -f "/tmp/.mor_global_test-fix_framework_variables" ]; then #including global test-fix framework variables if any of them are available
    source /tmp/.mor_global_test-fix_framework_variables
fi


svn_update()
{

    #   About:  This method updates from SVN and also ensures that update will be successful, if not - attempts to cleanup the repo
    #
    #   Arguments:
    #       $1 - path to update via SVN
    #
    #   Example:
    #       svn_update /usr/src/mor

    local PATH_TO_UPDATE="$1"
    cd $PATH_TO_UPDATE
    svn update  --force --accept theirs-full $PATH_TO_UPDATE
    if [ "$?" != "0" ]; then
	report "SVN cleanup: $PATH_TO_UPDATE" 3
	svn cleanup

	# second check
        svn update  --force --accept theirs-full $PATH_TO_UPDATE
	if [ "$?" != "0" ]; then
	    report "SVN UPDATE FAILED" 6
	    exit
	fi
    fi

}


core_count(){
    CORE_COUNT=`grep -c ^processor /proc/cpuinfo`
}

#===================== OUTPUT ==================
separator()
{
    #Author:    Mindaugas Mardosas
    #Company:   Kolmisoft
    #Year:      2010
    #About:     This function is used to logically separate tests output. Please use only this function when you want to separate tests output to the screen.

    #This function accepts arguments:
        # 1 - "text to be displayed"

    #Usage example:
        #   separator "text to be displayed"
    if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then
        #echo -e "\E[97m\e[100m   ----- $1 -----   \E[37m\e[49m"
        report "$1" 7
    fi
}
folder_separator()
{
    #Author:    Mindaugas Mardosas
    #Company:   Kolmisoft
    #Year:      2010
    #About:     This function is used to logically separate tests by folder (remember, each folder must have tests for one component, for example: Asterisk, GUI, DB, etc.)

    #This function accepts arguments:
        # 1 - "text to be displayed"

    #Usage example:
        #   separator "text to be displayed"

    if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then
        #echo -e "\E[34m\n***** $1 *****\E[37m\n"
	report "------------ $1 -------------" 7
    fi
}

report()
{
    # Author: Mindaugas Mardosas
    # This function is used for displaying output with color status.
    # Usage:
    #    report "some text" [0-5]
    #
    # The function returns the same parameter it received.
    #
    # This function accepts these arguments:
    #   $1 - text to display
    #   $2 - send status manually
    #   $2 or $3 - "FAILED" #causes not to print [OK] blabblabla. In other words if the functions has to report OK - it will print nothing
    #
    # Internal variable that can be used outside:
    #   ALL_OK  - this variable can be used to track if all tests from that group went ok. Read more about this variable usage in Example 5
    # returns/accepts these codes:
    #
    #   0 - ok
    #   1 - failed
    #   2 - warning
    #   3 - notice
    #   4 - fixed
    #   5 - overwritten
    #   6 - RED TEXT
    #   7 - echo text to screen. Text with this status will not be printed when -compact or -c settings will be used when running the testing framework
    #
    # Usage examples:
    #    Example 1:
    #               report "some output" 1         #would report "FAILED" and return 1
    #
    #               would produce similar output and return 1:
    #               FAILED         some output
    #
    #    Example 2:
    #               report "some output" 0         #would report "OK" and return 0
    #
    #               would produce similar output and return 0:
    #               OK             some output
    #
    #    Example 3 (command combine):
    #        Here is a simple command that returns 1 that states failure and 0 when a match is found (success):
    #           [root@localhost ~]# grep erdtfyguhjiok /etc/passwd #grep will not find anything and return 1
    #           [root@localhost ~]# echo $?
    #           1
    #           [root@localhost ~]#
    #        When using such simple commands or functions which return 0 on OK and 1 on failure you can leave the second parameter not filled:
    #            grep erdtfyguhjiok /etc/passwd
    #            report "Grep command status"
    #
    #            would produce similar output and this time return 1:
    #            FAILED         Grep command status
    #
    #    Example 4:
    #               report "some output" 0 FAILED
    #
    #               would produce no output at all and return 0:
    #
    #    Example 5:
    #               Now we will use ALL_OK variable to display some summary result about 3 tests:
    #                   ALL_OK=0    #resetting the variable
    #                   report "some output" 0 FAILED
    #                   report "some output" 0 FAILED
    #                   report "some output" 0 FAILED
    #
    #                   if [ "$ALL_OK" == "0" ]; then
    #                       echo "All 3 tests passed successfully"
    #                   else
    #                       echo "One or more tests failed"
    #                   fi
    #
    #------------------
    if [ "$2" != "" ]; then
        result=$2;
    else                    # 2nd parameter is not available - use last command status
        result=$?;
    fi

    #------------------
    if [ -f "/tmp/.mor_global_test-fix_framework_variables" ]; then #including global test-fix framework variables if any of them are available
        source /tmp/.mor_global_test-fix_framework_variables
    fi


    if [ "$result" == "0" ]; then
        if [ "$3" == "FAILED" ]  ; then return 0; fi  #causes not to print [OK] blabblabla


        if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then                     #if compact option was passed - this message will not be printed
            echo -e "\E[32m OK \E[32m\033[0m\\t\t$1";
        fi

        return 0;
    else
        ALL_OK=1    #some checks failed

        if [ "$result" == "1" ]; then
            echo -e "\E[91m FAILED \E[31m\033[0m\\t$1";
            return 1;
        elif [ "$result" == "2" ]; then
            echo -e "\E[93m WARNING! \E[33m\033[0m\\t$1";
            return 2;
        elif [ "$result" == "3" ]; then
            echo -e "\E[34m NOTICE \E[36m\033[0m\\t$1";
            return 3;
        elif [ "$result" == "4" ]; then
            echo -e "\E[96m FIXED \E[34m\033[0m\\t\t$1";
            return 4;
        elif [ "$result" == "5" ]; then
            echo -e "\E[34m Overwritten \E[34m\033[0m\\t$1";
            return 5;
        elif [ "$result" == "6" ]; then
            #echo -e "\n\n\n\E[5m\E[31m$1\E[31m\033[0m\E[25m\\n\n";
            echo -e "\E[91m CRITICAL \\t$1\E[34m\033[0m";
            return 6;
        elif [ "$result" == "7" ]; then
            if [ "$COMPACT_OUTPUT" != "COMPACT" ]; then                 #if compact option was passed - this message will not be printed
                echo -e "\\t\\t$1";
            fi
            return 7;
        fi
    fi
}

generate_random_password()
{
    #   Author:   Mindaugas Mardosas
    #   Company:  Kolmisoft
    #   Year:     2011
    #   About:    This function creates a hardly guessable password
    #
    #   Arguments:
    #       $1  -   Desired password length
    #
    #   Returns:
    #       0   -   success
    #           Global variable $GENERATED_PASSWD on success
    #       1   -   failure
    #
    #   Example:
    #       generate_random_password 20
    #
    #       echo "$GENERATED_PASSWD"    #this variable will contain the generated password

    local PasswdLength="$1";
    if [ "$PasswdLength" != "" ]; then
        GENERATED_PASSWD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c$PasswdLength`;
    else
        return 1;
    fi
}
#----------
ssl_enabled()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function checks if ruby is intalled in the system

    #   Returns:
    #   0 - SSL enabled
    #   1 - SSL disabled
    #   2 - Apache module mod_ssl is not installed
    #
    #   SSL_STATUS  - {on, off}

    if [ ! -f /etc/httpd/conf.d/ssl.conf ]; then
        SSL_STATUS="off"
        return 2
    fi




    SSL_ENABLED=`awk -F"#" '{print $1}' /etc/httpd/conf.d/ssl.conf| grep SSLEngine | awk '{print $2}'`
    if [ "$SSL_ENABLED" == "on" ]; then
        SSL_STATUS="on"
        return 0
    fi

    if [ -f "/etc/httpd/conf/httpd.conf" ]; then
        SSL_ENABLED=`awk -F"#" '{print $1}' /etc/httpd/conf/httpd.conf | grep SSLEngine | awk '{print $2}'`
        if [ "$SSL_ENABLED" == "on" ]; then
            SSL_STATUS="on"
            return 0
        fi
    else
        SSL_STATUS="off"
        return 1
    fi
}

#----------
#=======================================

ruby_exist()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if ruby is intalled in the system

    #   Returns:
    #   0 - OK, ruby exists in system
    #   1 - FAILED, ruby does not exist in the system

    ruby --help &> /dev/null
    if [ "$?" == "0" ]; then
        return 0;
    else
        return 1;
    fi
}

_centos_version()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function returns CentOS version

    centos_version=`grep -o "[0-9]" /etc/redhat-release | head -n 1`

}
os_processor_type()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function returns CentOS version
    #
    #   Returns:
    #       0   -   i686
    #       1   -   x86_64

    _UNAME=`uname -a`;
    _IS_64_BIT=`echo "$_UNAME"  | grep x86_64`

    if [ -n "$_IS_64_BIT" ];  then
        _64BIT=1;
        return 1
    else
        _64BIT=0;
        return 0
    fi
}

#============== ASTERISK =============================
#------------------ checks ------------------
asterisk_exist()
{
    # Author: Mindaugas Mardosas
    # This function checks if asterisk exists in the system. It does so by analyzing if default asterisk executable path in MOR exists
    # Accepts parameteres: No
    # Returns:
        # 0 - OK, Asterisk is found in the system
        # 1 - FAILED, Asterisk was not found in the system


    if [ `/etc/init.d/asterisk status 2> /dev/null  | awk '{print $1}' | grep asterisk | wc -l` == "1" ] || [ -f "/usr/sbin/asterisk" ]; then
        return 0
    else
        return 1
    fi
}
#--------
asterisk_is_running()
{
    # Author: Mindaugas Mardosas
    # This function checks if asterisk is running in the system.
    #
    # Parameters:
    #   $1  -   'exit' - will result in script exit if asterisk does not exist or is not running
    #
    # Returns:
    #   0 - OK, Asterisk is running in the system
    #   1 - FAILED, Asterisk is not running in the system
    #   2 - Asterisk is not present in the system

    FIRST_PARAMETER="$1" #no code above this line is allowed

    #---Asterisk exist?
    asterisk_exist
    if [ "$?" == "1" ]; then
        if [ "$FIRST_PARAMETER" == "exit" ]; then
            exit 2;
        else
            return 2; # Asterisk is not present in the system
        fi
    fi

    #---Asterisk is running?
    /etc/init.d/asterisk status &> /dev/null
    RUNNING="$?"
    if [ "$RUNNING" == "0" ]; then
        return 0;
    else
        if [ "$FIRST_PARAMETER" == "exit" ]; then
            exit 1;
        else
            return 1; # Asterisk is not present in the system
        fi
    fi
}
#--------
asterisk_current_version()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks current Asterisk version and assigns version number to variable  $ASTERISK_VERSION
    #
    #   Returns:
    #       Global variable  $ASTERISK_VERSION which holds current Asterisk version if determining Asterisk version succeeded
    #       0 - OK
    #       1 - Failed to determine Asterisk version

    ASTERISK_VERSION="0"
    ASTERISK_BRANCH="0"

    asterisk_is_running
    if [ "$?" == "1" ]; then
        sleep 2; # giving asterisk addition 2 second to complete the starting procedure. This is needed for sh_scripts/asterisk_upgrade.sh script.
        asterisk_is_running
        if [ "$?" == "1" ]; then
            sleep 2;
        fi
    fi

    /usr/sbin/rasterisk -x "core show version" > /dev/null
    if [ "$?" != "0" ]; then
        echo "ERROR: IS ASTERISK STARTED?";
        return 1;
    fi

    ASTERISK_VERSION=`rasterisk -x "core show version" |grep Asterisk | awk '{print $2}'`
    if [ "$?" != "0" ]; then
        echo "Some problems occoured when determining asterisk version. Is asterisk started?";
        return 1;
    fi

    ASTERISK_BRANCH=`echo "$ASTERISK_VERSION" | awk -F"." '{print $1"."$2}'`
    if [ "$?" != "0" ]; then
        echo "Some problems occoured when determining asterisk branch. Is asterisk started?";
        return 1;
    fi
}

mor_core_version()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function gives you MOR core version in 2 variables: MOR_CORE_BRANCH and MOR_CORE_VERSION.
    # Example:
    #       MOR_CORE_BRANCH=10
    #       MOR_CORE_VERSION=10.0.2
    #
    #   Arguments:
    #       $1  -  "EXIT_IF_NO_CORE"
    #
    #   Returns:
    #       $MOR_CORE_VERSION - MOR core version
    #       $MOR_CORE_BRANCH -   MOR core branch
    #   Additional details:
    #       For performance reasons no seatbelts included - the function assumes, that you will use it in environment where asterisk is already running

    EXIT_IF_NO_CORE=$1

    if [ ! -f "/usr/lib/asterisk/modules/app_mor.so" ]; then
        report "MOR core is not present in the system" 6
        if [ "$EXIT_IF_NO_CORE" == "EXIT_IF_NO_CORE" ]; then
            echo "Core not found in the system" | tee -a $report
            exit 1;
        else
            return 1;
        fi
    fi

    MOR_SHOW_STATUS=`asterisk -rx "mor show status" | grep -o "No such command"`

    if  [ "$MOR_SHOW_STATUS" == "No such command" ]; then
        report "MOR core not present - Asterisk has to be restarted?" 6
        if [ "$EXIT_IF_NO_CORE" == "EXIT_IF_NO_CORE" ]; then
            exit 1
        fi
        return 1
    fi

    MOR_CORE_VERSION=`asterisk -rx "mor show status" | grep Version | awk '{print $2}'`
    MOR_CORE_BRANCH=`echo $MOR_CORE_VERSION | awk -F"." '{print $1}'`
}
#----------------- /checks ------------------

#============== HeartBeat======================================
heartbeat_is_installed()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if Linux HeartBeat (HA) is installed in the server
    #
    #   Returns:
    #       0   -   OK, HeartBeat is installed
    #       1   -   Failed, HeartBeat is not installed

    if [ -d "/etc/ha.d" ]; then
        return 0;   # OK, HeartBeat is installed
    else
        return 1;   # Failed, HeartBeat is not installed
    fi
}
heartbeat_is_running()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function checks if Linux HeartBeat (HA) is running in the server
    #
    #   Returns:
    #       0   -   OK, HeartBeat is installed and running
    #       1   -   Failed, HeartBeat is not installed
    #       2   -   HeartBeat is installed, but not running
    #       3   -   Error occoured when checking ha status


    heartbeat_is_installed
    if [ "$?" != "0" ]; then
        return 1;   #  HA not installed
    fi

    #-------is ha running?

    if  [ -f "/etc/init.d/heartbeat" ]; then
        STATUS=`/etc/init.d/heartbeat status | grep -o stopped` &> /dev/null
        if [ "$STATUS" == "stopped" ]; then
            return 2;
        else
            return 0;
        fi

    else
        return 3
    fi
}
#============== /HeartBeat======================================
#============== VARIOUS FUNCTIONS =============================
which_version_is_bigger()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function is a wrapper function for ruby script test/framework/which_version_is_bigger.rb
    #
    #   Arguments:
    #       $1  -   version I
    #       $2  -   version II

    local vers1="$1";
    local vers2="$2";

    #_--- Dependencies-----
        if [ ! -f /usr/bin/ruby ]; then
            yum -y install ruby

            if [ ! -f /usr/bin/ruby ]; then
                report "FAILED to install ruby, do it manually" 1
                exit 1;
            fi
        fi
        #----
        if [ ! -f /usr/src/mor/x5/framework/which_version_is_bigger.rb ]; then
            report "Dependency /usr/src/mor/x5/framework/which_version_is_bigger.rb is missing. Fix that" 1
            exit 1;
        fi
    #----------------------
    /usr/bin/ruby /usr/src/mor/x5/framework/which_version_is_bigger.rb "$vers1" "$vers2"
    return "$?"
}

#=  FILE EDITING TOOLS =
    replace_line()
    {
        #   Author: Mindaugas Mardosas
        #   Year:   2010
        #   About:  This function is a wrapper function for ruby script test/framework/change_first_found_param_in_file.rb
        #
        #   Arguments:
        #       $1  -   path to file
        #       $2  -   what to search
        #       $3  -   replace with


        FIRST_PARAM="$1"
        SECOND_PARAM="$2"
        THIRD_PARAM="$3"

        ruby_exist
        if [ "$?" != "0" ]; then
            report "Ruby not found. Exiting"
            exit 1;
        fi

        /usr/bin/ruby /usr/src/mor/x5/framework/change_first_found_param_in_file.rb "$FIRST_PARAM" "$SECOND_PARAM" "$THIRD_PARAM"
    }

#== <Asterisk #include directive> ==============
    asterisk_include_directive_exist_check()
    {
        #   Author: Mindaugas Mardosas
        #   Year:   2010
        #   About:  This function checks if an Asterisk include directive exists. Include directive in Asterisk config looks as following: #include some_config.conf This function works as following: takes each line in the given  config file and greps the ones that have a keyword #include. When check if second string in that line is a required include directive.

        #   This function excepts these arguments:
        #       $1  -   Asterisk config name
        #       $2  -   Include directive to check if it is present

        #   Returns:
        #       0   -   OK, include directive exists
        #       1   -   FAILED, include directive does not exist
        #

        local ARG1_local="$1"
        local ARG2_local="$2"

        INCLUDE_DIRECTIVE=`grep "#include" "$ARG1_local" | awk -F";" '{print $1}' | grep "$ARG2_local" |  awk '{ print $2}'`;
        if [ "$INCLUDE_DIRECTIVE" == "$ARG2_local" ]; then
            return 0;
        else
            return 1;
        fi
    }
    #-------

    asterisk_include_directive()
    {
        #   Author: Mindaugas Mardosas
        #   Year:   2010
        #   About:  This function adds or reports that an Asterisk #include directive does not exist in a specified config file

        #   This function excepts these arguments:
        #       $1  -   Asterisk config name
        #       $2  -   #include directive to add/report if not exist


        #   Returns:
        #       0   -   OK, include directive exists
        #       1   -   FAILED to include a directive or directive does not exist
        #       4   -   FIXED, successfully included Asterisk #include directive; 4 is used to be compatible with function report


        #   Other notes:
        #       This function depends on function: asterisk_include_directive_exist_check
        #       This function should leave a system with a stable config file at any circumstances. If any problems encountered - it is safe to run the script with this function again
        #       This function is compatible with function report, so you can write directly like this:
        #           asterisk_include_directive_fix_or_report "/etc/asterisk/extensions_mor.conf" "extensions_mor_h323.conf" FIX
        #           report "#include extensions_mor_h323.conf" "$?"         #so here in $? place can be automatically inserted values: 0, 1, 4


        #   Function usage examples:
        #       Example1:
        #           Scenario: there is a config file /etc/asterisk/extensions_mor.conf, we want to check if there is such line: #include extensions_mor_h323.conf, if not - you want to include it
        #
        #           asterisk_include_directive "/etc/asterisk/extensions_mor.conf" "extensions_mor_h323.conf"


        ARG1="$1"
        ARG2="$2"


        asterisk_include_directive_exist_check "$ARG1" "$ARG2"
        STATUS="$?";
        if [ "$STATUS" == "0" ]; then
            return 0;                           # OK
        else
            #--- to leave the system in UNIX atomically safe state workarounds with mv command now will be used ---
            TEMP_FILE=`/bin/mktemp`
            cp "$ARG1" "$TEMP_FILE";
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi
            echo "#include $ARG2" >> "$TEMP_FILE"
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi

            asterisk_include_directive_exist_check "$TEMP_FILE" "$ARG2"
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi
            mv "$TEMP_FILE" "$ARG1"
            rm -rf "$TEMP_FILE"         #cleaning the mess
            #------------------------------------------------------------------------------------------------------
            asterisk_include_directive_exist_check "$ARG1" "$ARG2"
            STATUS="$?"
            if [ "$STATUS" == "0" ]; then
                return 4;   #FIXED
            elif [ "$STATUS" == "1" ]; then
                return 1;   #FAILED
            fi
        fi
    }
    #== </Asterisk #include directive> ====
#== <Asterisk #exec directive> ==============
    asterisk_exec_directive_exist_check()
    {
        #   Author: Mindaugas Mardosas
        #   Year:   2010
        #   About:  This function checks if an Asterisk #exec directive exists. #exec directive in Asterisk config looks as following: #exec /usr/local/mor/mor_ast_skype This function works as following: takes each line in the given  config file and greps the ones that have a keyword #exec. When check if second string in that line is a required #exec directive.

        #   This function excepts these arguments:
        #       $1  -   Asterisk config name
        #       $2  -   #exec directive to check if it is present

        #   Returns:
        #       0   -   OK, #exec directive exists
        #       1   -   FAILED, #exec directive does not exist
        #

        local ARG1_local="$1"
        local ARG2_local="$2"

        EXEC_DIRECTIVE=`grep "#exec" "$ARG1_local" | awk -F";" '{print $1}' | grep "$ARG2_local" |  awk '{ print $2}'`;
        if [ "$EXEC_DIRECTIVE" == "$ARG2_local" ]; then
            return 0;
        else
            return 1;
        fi
    }
    #-------

    asterisk_exec_directive()
    {
        #   Author: Mindaugas Mardosas
        #   Year:   2010
        #   About:  This function adds or reports that an Asterisk #exec directive does not exist in a specified config file

        #   This function excepts these arguments:
        #       $1  -   Asterisk config name
        #       $2  -   #exec directive to add/report if not exist


        #   Returns:
        #       0   -   OK, #exec directive exists
        #       1   -   FAILED to include a directive or directive does not exist
        #       4   -   FIXED, successfully included Asterisk #exec directive; 4 is used to be compatible with function report


        #   Other notes:
        #       This function depends on function: asterisk_exec_directive_exist_check
        #       This function should leave a system with a stable config file at any circumstances. If any problems encountered - it is safe to run the script with this function again
        #       This function is compatible with function report, so you can write directly like this:
        #           asterisk_exec_directive "/etc/asterisk/chan_skype.conf" "/usr/local/mor/mor_ast_skype" FIX
        #           report "#exec /usr/local/mor/mor_ast_skype" "$?"         #so here in $? place can be automatically inserted values: 0, 1, 4


        ARG1="$1"
        ARG2="$2"


        asterisk_exec_directive_exist_check "$ARG1" "$ARG2"
        STATUS="$?";
        if [ "$STATUS" == "0" ]; then
            return 0;                           # OK
        else
            #--- to leave the system in UNIX atomically safe state workarounds with mv command now will be used ---
            TEMP_FILE=`/bin/mktemp`
            cp "$ARG1" "$TEMP_FILE";
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi
            echo "#exec $ARG2" >> "$TEMP_FILE"
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi

            asterisk_exec_directive_exist_check "$TEMP_FILE" "$ARG2"
                if [ "$?" != "0" ]; then
                    rm -rf "$TEMP_FILE"
                    return 1;
                fi
            mv "$TEMP_FILE" "$ARG1"
            rm -rf "$TEMP_FILE"         #cleaning the mess
            #------------------------------------------------------------------------------------------------------
            asterisk_exec_directive_exist_check "$ARG1" "$ARG2"
            STATUS="$?"
            if [ "$STATUS" == "0" ]; then
                return 4;   #FIXED
            elif [ "$STATUS" == "1" ]; then
                return 1;   #FAILED
            fi
        fi
    }
    #== </Asterisk #exec directive> ====

last_dir_file_in_path()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2010
    #   About:  This function extracts last dir/file from path and assigns that string to GLOBAL variable $LAST_STRING_IN_PATH
    #
    #   Arguments:
    #       $1  - Path. For example "/var/log/mor"
    #
    #   Other notes:
    #       There should be no spaces in the path
    #
    #   Usage examples:
    #       last_dir_file_in_path "/var/log/mor"    #the string "mor" will be assigned to variable $LAST_STRING_IN_PATH
    #

    DEBUG=0     #   { 0 - debug OFF, 1 - debug ON}

    LAST_STRING_IN_PATH=`echo "$1" | awk -F"/" '{ print $NF}'`
    if [ "$DEBUG" == "1" ]; then
        echo "$LAST_STRING_IN_PATH"
    fi
}
check_and_fix_permission()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks and sets correct permission if it is not present

    #   Arguments:
    #       $1 path to file or directory
    #       $2  permissions in format 0755
    #       $3 "report" - report to console
    #       $4 ignore - ignore if missing and do not report to console
    #   Other notes:
    #       This function is dependent on other function last_dir_file_in_path from bash_functions.sh

    local pathToFileOrDir="$1"
    local permission="$2"
    local reportToConsole="$3"
    local ignoreMissing="$4"

    if [ -f $pathToFileOrDir ] || [ -d $pathToFileOrDir ]; then
        local perm=`stat $pathToFileOrDir | grep -m 1 Access | awk  '{print $2}' | awk -F"(" '{print $2}' | awk -F"/" '{print $1}'`
        if [ "$perm" != "$permission" ]; then
            chmod $permission $pathToFileOrDir
            STATUS="$?"
            if [ "$STATUS" == "0" ]; then
                if [ "$reportToConsole" == "report" ]; then
                    report "FIXED permissions for $pathToFileOrDir" 4
                fi
                return 4
            else
                if [ "$reportToConsole" == "report" ]; then
                    report "Failed to fix permissions for $pathToFileOrDir" 1
                fi
                return 1
            fi
        else
	    if [ "$reportToConsole" == "report" ] && [ "$ignoreMissing" != "ignore" ]; then
        	report "$pathToFileOrDir permission is ok: $permission" 0
    	    fi
        fi
    else

        if [ "$reportToConsole" == "report" ] && [ "$ignoreMissing" != "ignore" ]; then
            report "$pathToFileOrDir was not found in the system" 2
        fi
        return 3
    fi
}
exit_if_failure()
{
    if [ "$?" != "0" ]; then
        echo "Encountered an error. Exiting while safe. Try to run again"
        exit 1;
    fi
}

#------Time/Timezones
_mor_time()
{
    #   Author:   Mindaugas Mardosas
    #   Company:  Kolmisoft
    #   Year:     2011-2013
    #   About:    This function retrieves a current system time and date in separate variables which can be reused later

	mor_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
    CURRENT_DATE=`date +%Y\.%-m\.%-d`;
}
#-----
getTimeZone()
{
    #   Author:   Mindaugas Mardosas
    #   Company:  Kolmisoft
    #   Year:     2011
    #   About:    This function retrieves a current system timezone from /etc/sysconfig/clock config
    #
    #   Returns:
    #       0   -   OK, timezone retrieved successfully
    #       1   -   An error occoured
    #
    #
    #   MOR_TIME_ZONE this global variable will have a system timezone assigned
    #
    #   Example usage:
    #       [root@localhost sysconfig]# getTimeZone
    #       [root@localhost sysconfig]# echo $MOR_TIME_ZONE
    #       Europe/Vilnius
    #

    if [ ! -f /etc/sysconfig/clock ]; then
        echo "Error: /etc/sysconfig/clock does not exist, exiting"
        return 1;
    fi

    MOR_TIME_ZONE=`grep ZONE /etc/sysconfig/clock  | awk -F"=|\"" '{print $3}'`
    if [ "$MOR_TIME_ZONE" != "" ]; then
        return 0
    else
        return 1
    fi
}


#----
check_if_settings_match_exactly()
{

    #Author: Mindaugas Mardosas

    #arguments
        #1 - where to look
        #2 - what to match
        #3 - how many times must to match to report OK
    #returns
        #0 - OK
        #1 - does not match
        #3 - file does not exist
    DEBUG=0     # 0 - DEBUG DISABLED, 1 - DEBUG ENABLED

    if [ ! -f "$1" ]; then
        return 3;
    fi


    if [ ! -z "$3" ]; then        # if the setting must match x times
        HOW_MANY_TIMES=`grep "$2" "$1" | wc -l`

        if [ "$DEBUG" == "1" ]; then
            echo "grep $2 $1 | wc -l"
            grep "$2" $1

            echo "\$3: |$3|, \$HOW_MANY_TIMES |$HOW_MANY_TIMES|"
        fi

        if [ "$HOW_MANY_TIMES" == "$3" ]; then
            if [ "$DEBUG" == "1" ]; then
                echo "check_if_settings_match_exactly returned 0"
            fi
            return 0
        else
            if [ "$DEBUG" == "1" ]; then
                echo "check_if_settings_match_exactly returned 1"
            fi
            return 1
        fi
    else
        grep "$2" "$1" > /dev/null
        if [ "$?" ==  "0" ]; then
            return 0;
        else
            return 1;
        fi
    fi
}
check_if_setting_match()
{
    #Author: Mindaugas Mardosas
    #This function searches for a given pattern in a given file.
    #How this function works: This function strips any comments found, deletes any spaces or tab above the required variable, so it works even if variable is written in both ways:
        # some_variable=1
        # or
        # some_variable = 1
        # it will treat it the same: some_variable=1

    #PARAMETERS:
        #1 path to file to search
        #2 variable name
        #3 what should match? WITHOUT SPACES!!!

    #RETURNS:
        # 0 success, requirecalltoken=no
        # 1 - failed, setting did not matched
        # 2 - failed, setting was not found at all
		# 3 - file not found

    #EXAMPLE:
        #check_if_setting_match /etc/asterisk/iax.conf "requirecalltoken" "requirecalltoken=no"


    #Additional notes: this function  is not suitable in situations, when you are checking include directives which begin with # sign. This functions assumes, that # is a comment and ignores everything after this sign

    if [ ! -f "$1" ]; then
        report "File $1 does not exist" 1
        return 3;
    fi

    SETTING=`awk -F";" '{ print $1}' $1 | awk -F"#|;" '{ print $1}' | grep "$2" |  sed 's/ //g' |  sed 's/\t//g'`

    if [ "$SETTING" == "$3" ]; then
        return 0;
    else
		if [ "$SETTING" == "" ]; then
			return 2;
		else
			return 1;
		fi
    fi
}
check_if_setting_match_fix()
{
    #Author:    Mindaugas Mardosas
    #Year:      2010
    #About:     This function searches for a given setting in a given file. If a setting is not found - it is added. If variable value is different - it is added
    #Internals: This function is based on check_if_setting_match() function and behaves accordingly to the return codes it provides

    #PARAMETERS:
        #1 path to file to search
        #2 variable name
        #3 what should match? WITHOUT SPACES!!!

    #RETURNS:
        # 0 success, requirecalltoken=no
        # 1 - failed, setting did not matched
        # 2 - failed, setting was not found at all
		# 3 - file not found

    #EXAMPLE:
        #check_if_setting_match_fix /etc/asterisk/iax.conf "requirecalltoken" "requirecalltoken=no"


    #Additional notes: this function  is not suitable in situations, when you are checking include directives which begin with # sign. This functions assumes, that # is a comment and ignores everything after this sign

    local PathToFile="$1"
    local VariableName="$2"
    local WhatShouldMatch="$3"

    if [ ! -f "$PathToFile" ]; then
        echo "File $PathToFile does not exist"
        return 3;
    fi

    check_if_setting_match $PathToFile "$VariableName" "$WhatShouldMatch"
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then
        return 0;
    elif [ "$STATUS" == "1" ]; then
        replace_line "$PathToFile" "$VariableName" "$WhatShouldMatch"
        check_if_setting_match $PathToFile "$VariableName" "$WhatShouldMatch"
        STATUS="$?"
        if [ "$STATUS" == "0" ]; then
            return 4;
        else
            return 1;
        fi
    elif [ "$STATUS" == "2" ]; then
        echo "$WhatShouldMatch" >> "$PathToFile"
        check_if_setting_match $PathToFile "$VariableName" "$WhatShouldMatch"
        STATUS="$?"
        if [ "$STATUS" == "0" ]; then
            return 4;
        else
            return 1;
        fi
    fi
}


check_if_variable_exists()
{
    #   Author:    Mindaugas Mardosas
    #   Year:      2010
    #   About:     This function searches if a given variable exists, it does so by dividing all line strings by #, ; (these marks comments) and by = sign, which assigns a value to variable. After this operation what is left - it is a viariable.


    #   RETURNS:
        # 0 - success, variable was found
        # 1 - failed, variable was not found
		# 3 - file not found

    #   Example:
    #       check_if_variable_exists /etc/asterisk/voicemail.conf "european"

    if [ ! -f "$1" ]; then
        echo "File $1 does not exist"
        return 3;
    fi

    SETTING=`awk -F"#|;|=" '{ print $1}' $1  | grep "$2" |  sed 's/ //g' |  sed 's/\t//g'`

    if [ -n "$SETTING" ]; then
        return 0;
    else
        return 1;
    fi
}

#==== GUI =====
gui_exists()
{
    # Author:   Mindaugas Mardosas
    # About:    This function detects if mor gui is installed in this server

    #   Returns:
        #   0 - GUI exists
        #   1 - GUI does not exist


    if [ -f /home/mor/config/environment.rb ]; then
	MOR_GUI_EXIST="0"
        return 0;
    else
	MOR_GUI_EXIST="1"
        return 1;
    fi
}
#----
mor_gui_current_version()
{
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This functions retrieves current MOR GUI version in system

#   Arguments
#       None
#   Returns:
#       Makes available global variable $MOR_VERSION_YOU_ARE_TESTING which holds MOR version currently installed in the system. Returns $MOR_MAPPED_VERSION_WEIGHT which contains MOR version in numerical value.
    gui_exists

    if [ ! -f  /usr/bin/svn ]; then
        yum -y install subversion
        if [ ! -f  /usr/bin/svn ]; then
            report "Failed to find/install subversion" 1
            exit 1
        fi
    fi
    
    if  grep http /home/mor/.svn/entries | grep "http" | grep -q "m2"
    then
        MOR_VERSION_YOU_ARE_TESTING="m2"
    else
        MOR_VERSION_YOU_ARE_TESTING=`cat /home/mor/.svn/entries | grep http | awk -F"/" '{
          if($6 == "trunk")
            print $6;
          else
            print $7;
        }'`
    fi

    MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS="$MOR_VERSION_YOU_ARE_TESTING"

    MOR_VERSION_YOU_ARE_TESTING=`echo $MOR_VERSION_YOU_ARE_TESTING | awk -F"." '{print $1}'`    # quick hack for MOR 12.126; for various core and db related scripting

    if [ "$MOR_VERSION_YOU_ARE_TESTING" == "trunk" ]; then
        MOR_VERSION="11"
    else
        MOR_VERSION="$MOR_VERSION_YOU_ARE_TESTING"
    fi
    
  
    mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS" #returns variable $MOR_MAPPED_VERSION_WEIGHT 
    
}
#-------------
gui_revision_check()
{
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This function checks if the system has the newest revision of GUI: (MOR and crm)
#
#   Arguments:
#       1   -   #{1 - on,0 - off} messages
#
#   Returns:
#       0   -   GUI is already the newest version
#       1   -   GUI needs to be upgraded

    MESSAGES="$1"

    DEBUG=0     # {1 - on, 0 - off}


    mor_gui_current_version #getting release version. Possible values are: 8,9, 10, trunk, etc...

    GUI_REVISION_IN_SYSTEM=`svn info /home/mor | sed -n '9p' | sed 's/ //g' | awk -F":" '{print $NF}'`


    if [ "$debug" == "1" ]; then
        echo "$MOR_VERSION_YOU_ARE_TESTING"
    fi

    if [ "$MOR_VERSION_YOU_ARE_TESTING" == "trunk" ]; then
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/mor/gui/trunk | grep 'Last Changed Rev' | awk '{print $NF}'`
    elif [ "$MOR_VERSION_YOU_ARE_TESTING" == "crm" ]; then
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/crm/trunk | grep 'Last Changed Rev' | awk '{print $NF}'`
    elif [ "$MOR_VERSION_YOU_ARE_TESTING" == "m2" ]; then
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/m2/gui/trunk/ | grep 'Last Changed Rev' | awk '{print $NF}'`
    else
        GUI_REVISION_IN_REPOSITORY=`svn info http://svn.kolmisoft.com/mor/gui/branches/$MOR_VERSION_YOU_ARE_TESTING | grep 'Last Changed Rev' | awk '{print $NF}'`
    fi

    if [ "$GUI_REVISION_IN_SYSTEM" -lt "$GUI_REVISION_IN_REPOSITORY" ]; then
        if [ "$MESSAGES" == "1" ]; then
            report "There is a newer version GUI, please upgrade your GUI to the newest. Your GUI current revision is: $GUI_REVISION_IN_SYSTEM, Repository revision: $GUI_REVISION_IN_REPOSITORY" 1
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "System GUI  revision: $GUI_REVISION_IN_SYSTEM\nLatest GUI revision version: $GUI_REVISION_IN_REPOSITORY";
        fi
        return 1;
    else
        if [ "$MESSAGES" == "1" ]; then
            report "System already has the newest GUI version. Revision: $GUI_REVISION_IN_SYSTEM" 0
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "System GUI  revision: $GUI_REVISION_IN_SYSTEM\nLatest GUI revision: $GUI_REVISION_IN_REPOSITORY";
        fi
        return 0;
    fi

    
}
get_MOR_webdir()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function gets Web_Dir from  /home/mor/config/environment.rb

    MOR_WEB_DIR=`grep Web_Dir /home/mor/config/environment.rb |  awk -F'\"' '{print $2}'`
}
get_MOR_Web_URL()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function gets Web_URL from  /home/mor/config/environment.rb

    MOR_Web_URL=`grep Web_URL /home/mor/config/environment.rb |  awk -F'\"' '{print $2}'`
}
check_with_wget()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function tries to wget a given url to webpage and checks if a given string(-s) exists. If you want to check multiple strings - use regexep supported by grep
    #
    # Returns:
    #   0   -   OK, the page was accessible and string(-s) given with regexp were found
    #   1   -   FAILED, the strings given were not found

    local URL_TO_DOWNLOAD="$1"
    local STRINGS_TO_CHECK="$2"

    local temp=`/bin/mktemp`
    /usr/bin/wget -t 1 -T 10 --no-check-certificate -O $temp $URL_TO_DOWNLOAD &> /dev/null
    grep "$STRINGS_TO_CHECK" $temp &> /dev/null
    local STATUS="$?"
    rm -rf $temp
    if [ "$STATUS" == "0" ]; then
        return 0;
    else
        return 1;
    fi
}
check_if_mor_login_page_is_accessible()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This functions checks if mor login screen is accessible

    # Returns:
    #   0   -   OK, MOR GUI is accessible
    #   1   -   FAILED, MOR GUI is not accessible. Possible problem is bad environmnent.rb settings
    #   2   -   GUI is accessible only via 127.0.0.1. Failed to access with settings from environment.rb
    #
    #   ONLY_VIA_LOCAL_ADDRESS=1   #this global variable is set when the page is accessible only via local IP address 127.0.0.1
    #   ONLY_VIA_LOCAL_ADDRESS_AND_SSL=1 #this global variable is set when the page is accessible only via local IP address 127.0.0.1 and SSL
    #   WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS # this global variable holds the correct address to access GUI from scripts

    get_MOR_webdir
    get_MOR_Web_URL

    #-----------Trying with IP and WEBDIR retrieved from environment.rb
    check_with_wget "$MOR_Web_URL$MOR_WEB_DIR" "login_psw\|login_username"
    if [ "$?" == "0" ]; then
        WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS="$MOR_Web_URL$MOR_WEB_DIR"
        return 0;
    fi

    #-----------Trying with local IP: 127.0.0.1 and WEBDIR retrieved from environment.rb
    check_with_wget "http://127.0.0.1/$MOR_WEB_DIR" "login_psw\|login_username"
    if [ "$?" == "0" ]; then
        ONLY_VIA_LOCAL_ADDRESS=1
        WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS="http://127.0.0.1/$MOR_WEB_DIR"
        return 0;
    fi

    check_with_wget "http://127.0.0.1/$MOR_WEB_DIR/callc/login" "login_psw\|login_username"
    if [ "$?" == "0" ]; then
        ONLY_VIA_LOCAL_ADDRESS=1
        WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS="http://127.0.0.1/$MOR_WEB_DIR/callc/login"
        return 0;
    fi


    #-----------Trying with local IP: 127.0.0.1, WEBDIR retrieved from environment.rb AND SSL
    check_with_wget "https://127.0.0.1/$MOR_WEB_DIR" "login_psw\|login_username"
    if [ "$?" == "0" ]; then
        ONLY_VIA_LOCAL_ADDRESS=1
        ONLY_VIA_LOCAL_ADDRESS_AND_SSL=1
        WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS="https://127.0.0.1/$MOR_WEB_DIR"
        return 0;
    fi

    return 1;   #nothing was matched. GUI was not accessible with currently defined rules
}
check_current_crontab_url()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks given url for MOR cron actions
    # Returns:
    #   0   -   OK
    #   1   -   FAILED

    CRONTAB_PATH_IN_SYSTEM="$1"

    local CURRENT_URL=`grep -m 1 http $CRONTAB_PATH_IN_SYSTEM  | awk -F'wget' '{print $NF}' | grep -o "https\?://[a-z,/,.,0-9,_,:]*" | awk -F"/" '{print $1 "//" $3}' `
    get_MOR_webdir
    check_with_wget "$CURRENT_URL$MOR_WEB_DIR" "login_psw\|login_username"
    if [ "$?"  != "0" ]; then
        return 1;
    fi
}
fix_mor_gui_crontab()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function fixes crontab if possible
    #
    # Arguments:
    #   1   -   path to cron action in MOR GUI, for example: /callc/hourly_actions
    #   2   -   path to crontab file
    #   3   -   crontab settings
    #
    # Returns:
    #   0   -   OK - crontab was already OK
    #   1   -   FAILED to fix the crontab
    #   4   -   FIXED
    PATH_TO_CRON_ACTION_IN_GUI="$1"
    CRONTAB_PATH_IN_SYSTEM="$2"
    CRONTAB_SETTINGS="$3"   #for example:  0 0 * * * root wget -o /dev/null -O /dev/null

    check_current_crontab_url $CRONTAB_PATH_IN_SYSTEM
    if [ "$?" == "0" ]; then
        return 0;
    else
        #----------Begin fix
        check_if_mor_login_page_is_accessible   # Get the working URL to MOR login page
        if [ "$WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS" != "" ]; then
            get_MOR_webdir
            echo "$CRONTAB_SETTINGS $WORKING_ADDRESS_TO_ACCESS_GUI_FROM_SCRIPTS$PATH_TO_CRON_ACTION_IN_GUI" > $CRONTAB_PATH_IN_SYSTEM
        else
            return 1;
        fi
        #-------- Check again
        check_current_crontab_url $CRONTAB_PATH_IN_SYSTEM
        if [ "$?" == "0" ]; then
            return 4;
        else
            return 1;
        fi
    fi
}
#=== Services ====

#==== Apache ====
apache_exists()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2010
    #   About:  This function checks if Apache exists

    #   Arguments:
    #       None arguments are excepted
    #   Returns:
    #       0 - Apache exists in the system
    #       1 - Apache does not exist or some components are missing


    if [ -f /usr/sbin/httpd ] && [ -d /etc/httpd ]; then
        return 0;
    else
        return 1;
    fi
}

apache_is_running()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2010
    #   About:  This function checks if Apache is running

    #   Arguments:
    #       None arguments are excepted
    #
    #   Returns:
    #       0 - Apache is running
    #       1 - Apache apache not found in the system
    #       2 - Apache is not running

    apache_exists
    if [ "$?" == "1" ]; then
        return 1;
    fi

    /etc/init.d/httpd status &> /dev/null
    APACHE_IS_RUNNING="$?"
    if [ "$APACHE_IS_RUNNING" == "0" ]; then
        return 0;
    else
        return 2;
    fi
}

#==== MySQL =====
mysql_exists()
{
    #Author: Mindaugas Mardosas
    #This functions detects if it is being run on CentOS (or other RedHat based distribution) if no - forces the script to exit. If it is being run on  CentOS - checks if /etc/my.cnf file exists. This is the default MySQL configuration file in CentOS, if it is not there - MySQL is not installed at all
    #Returns:
        #   0 - OK, MySQL exists
        #   1 - FALSE, MySQL does not exist in this server

    if [ ! -f /etc/redhat-release ]; then   # added this test for OS because /etc/my.cnf place is different in other Operating Systems
        echo "Sorry, but this test supports only CentOS"
        exit 1;
    fi

    if [ -r /etc/my.cnf ]; then
        return 0;
    else
        return 1;
    fi
}
mysql_is_running()
{
    #   Author: Mindaugas Mardosas
    #   Year: 2011
    #   This functions checks if MySQLd service is running
    #   Returns:
    #       0   -   mysqld is running
    #       1   -   mysqld is not running
    #       2   -   mysqld is not present in the system

    mysql_exists
    if [ "$?" == "1" ]; then
        return 2;
    fi

    /etc/init.d/mysqld status &> /dev/null
    MYSQL_IS_RUNNING="$?"
    if [ "$MYSQL_IS_RUNNING" == "0" ]; then
        return 0;
    else
        return 1;
    fi
}
#-----
mysql_server_version()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011-2013
    #   About:  This function gets current MySQL version
    #
    #   Returns:
    #       MYSQL_VERSION - mysql version number

    . /usr/src/mor/x5/framework/settings.sh

    read_mor_db_settings
    if [ "$DB_PRESENT" == "1" ]; then
        MYSQL_VERSION=`mysql --version | awk '{print $5}' | sed 's/,//g'` # 5.0.95
        MYSQL_VERSION_2=`echo $MYSQL_VERSION | awk -F"." '{print $1"."$2}'` # Outputs like this: 5.0
    else
        mysql_connect_data_v2  > /dev/null
        MYSQL_VERSION=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e 'SHOW VARIABLES LIKE "version";' | grep version | awk '{print $2}'` # 5.0.95
        MYSQL_VERSION_2=`echo $MYSQL_VERSION | awk -F"." '{print $1"."$2}'` # Outputs like this: 5.0
        REMOTE_DB=1
    fi
}
#----

mysql_connect_data_v2_internal_test_settings()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function tests MySQL connection settings.
    #
    #   Arguments:
    #       $1  -   Path to file
    #
    #   Returns:
    #       0   -   OK
    #       1   -   FAILED

    PATH_TO_CFG="$1"

    DEBUG="0"     #   0 - off, 1 - on

    if [ "$DEBUG" == "1" ]; then
        report "\n$PATH_TO_CFG:\nDB_HOST:$DB_HOST\nDB_NAME:$DB_NAME\nDB_USERNAME:$DB_USERNAME\nDB_PASSWORD:$DB_PASSWORD" 7
    fi

    if [ ! -f "/usr/bin/mysql" ]; then
        yum -y install mysql
    fi

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "USE $DB_NAME" &> /dev/null
    STATUS="$?";

    if [ "$STATUS" == "0" ]; then
        if [ "$TEST_MODE" == "test" ]; then
            report "$PATH_TO_CFG MySQL settings" 0
        fi
        return 0;
    else
        if [ "$TEST_MODE" == "test" ]; then
            report "$PATH_TO_CFG has bad MySQL settings - failed to connect using them" 1
        fi
        return 1;
    fi
}

read_user_input()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function gets user input and sets provided default if user does not enter anything (presses enter)
    #
    #   Arguments:
    #       $1  -   User question
    #       $2  -   default value if not set

    USER_QUESTION="$1"
    DEFAULT_VALUE_TO_SET="$2"

    echo "$USER_QUESTION"
    read input_from_user

    if [ "$input_from_user" == "" ]; then
        GET_VALUE=$DEFAULT_VALUE_TO_SET
    else
        GET_VALUE=$input_from_user    
    fi
}

mysql_connect_data_v2()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010-2013
    #   About:  This function retrieves db settings from various MOR configuration files. This script has 2 modes: test - tests each configuration file if settings are correct and normal - normal mode retrieves first successfull settings from one of configuration files
    #
    #   Parameters:
    #       $1  -   "test" //for test mode
    #
    #   Returns:
    #       0   -   OK
    #       1   -   None settings were correct

    TEST_MODE="$1"

    config="/etc/mor/system.conf"
    if [ -r "$config" ]; then
        DB_HOST=`sed 's/ //g'  $config | grep dbhost | awk  -F"="  '{print $2}'`;
        DB_NAME=`sed 's/ //g'  $config | grep dbname | awk  -F"=" '{print $2}'`;
        DB_USERNAME=`sed 's/ //g'  $config | grep dbuser | awk  -F"=" '{print $2}'`;
        DB_PASSWORD=`sed 's/ //g'  $config | grep dbsecret | awk  -F"=" '{print $2}'`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
    	    return 0;
        fi
    fi


    apache_is_running

    HTTPD_STATUS="$?"
    config="/home/mor/config/database.yml"
    if [ -r "$config" ] && [ "$HTTPD_STATUS" == "0" ]; then
        DB_HOST=`awk -F"#" '{print $1}'  $config | grep -iA 5 "^production:$" | grep host | awk '{print $2}' | sed "s/'\|\"//g"`;
        DB_NAME=`awk -F"#" '{print $1}'  $config | grep -iA 5 "^production:$" | grep database | awk '{print $2}' | sed "s/'\|\"//g"`;
        DB_USERNAME=`awk -F"#" '{print $1}'  $config | grep -iA 5 "^production:$" | grep username |  awk '{print $2}' | sed "s/'\|\"//g"`;
        DB_PASSWORD=`awk -F"#" '{print $1}'  $config | grep -iA 5 "^production:$" | grep password | awk '{print $2}' | sed "s/'\|\"//g"`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
            return 0;
        fi
    fi


    asterisk_is_running
    ASTERISK_STATUS="$?"

    config="/etc/asterisk/mor.conf"
    if [ -r "$config" ] && [ "$ASTERISK_STATUS" == "0" ]; then

        DB_HOST=`awk -F";" '{print $1}' $config | grep -iA 5 "global]" | sed 's/ //g' | grep hostname | awk -F"=" '{print $2}'`;
        DB_NAME=`awk -F";" '{print $1}' $config | grep -iA 5 "global]" | sed 's/ //g' | grep dbname | awk  -F"=" '{print $2}'`;
        DB_USERNAME=`awk -F";" '{print $1}' $config | grep -iA 5 "global]" | sed 's/ //g' | grep user | awk  -F"=" '{print $2}'`;
        DB_PASSWORD=`awk -F";" '{print $1}' $config | grep -iA 5 "global]" | sed 's/ //g' | grep password | awk  -F"=" '{print $2}'`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
            return 0;
        fi
    fi


    config="/etc/asterisk/res_mysql.conf"
    if [ -r "$config" ] && [ "$ASTERISK_STATUS" == "0" ]; then

        DB_HOST=`awk -F";" '{print $1}' $config | grep -iA 5 "general]" | sed 's/ //g' | grep dbhost | awk  -F"=" '{print $2}'`;
        DB_NAME=`awk -F";" '{print $1}' $config | grep -iA 5 "general]" | sed 's/ //g' | grep dbname | awk  -F"=" '{print $2}'`;
        DB_USERNAME=`awk -F";" '{print $1}' $config | grep -iA 5 "general]" | sed 's/ //g' | grep dbuser | awk  -F"=" '{print $2}'`;
        DB_PASSWORD=`awk -F";" '{print $1}' $config | grep -iA 5 "general]" | sed 's/ //g' | grep dbpass | awk  -F"=" '{print $2}'`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
            return 0;
        fi
    fi

    config="/var/lib/asterisk/agi-bin/mor.conf"
    if [ -r "$config" ] && [ "$ASTERISK_STATUS" == "0" ]; then

        DB_HOST=`sed 's/ //g'  $config | grep host | awk  -F"="  '{print $2}'`;
        DB_NAME=`sed 's/ //g'  $config | grep db | awk  -F"=" '{print $2}'`;
        DB_USERNAME=`sed 's/ //g'  $config | grep user | awk  -F"=" '{print $2}'`;
        DB_PASSWORD=`sed 's/ //g'  $config | grep secret | awk  -F"=" '{print $2}'`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
            return 0;
        fi
    fi

    mysql_is_running
    MYSQL_STATUS="$?"

    grep master-host /etc/my.cnf &> /dev/null
    REPL="$?"

    mysql_server_version
    if [ "$MYSQL_VERSION" == "5.0.77" ]; then  # MySQL 5.0 < does not keep replication settings in /etc/my.cnf. Instead it keeps them in a database itself. MySQL 5.0 ships only with CentOS 5.x
        config="/etc/my.cnf"
        if [ -r "$config" ] && [ "$MYSQL_STATUS" == "0" ] && [ "$REPL" == "0" ]; then
            DB_HOST=`awk -F"#" '{print $1}'  $config | sed 's/ //g' | grep master-host | awk  -F"="  '{print $2}'`;
            DB_NAME=`awk -F"#" '{print $1}'  $config | sed 's/ //g' | grep replicate-do-db | awk  -F"=" '{print $2}'`;
            DB_USERNAME=`awk -F"#" '{print $1}'  $config | sed 's/ //g' | grep master-user | awk  -F"=" '{print $2}'`;
            DB_PASSWORD=`awk -F"#" '{print $1}'  $config | sed 's/ //g' | grep master-password | awk  -F"=" '{print $2}'`;

            mysql_connect_data_v2_internal_test_settings $config
            if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
                return 0;
            fi
        fi
    fi

    #---- If we got till here - we cannot determine MOR MySQL connect data from normal configuration files. Most probably this is a MySQL dedicated server.

    config="/etc/mor/mor_db_connect_data.cnf"
    if [ -f "$config" ]; then
        DB_HOST=`awk -F";" '{print $1}' $config | sed 's/ //g' | grep dbhost | awk  -F"=" '{print $2}'`;
        DB_NAME=`awk -F";" '{print $1}' $config | sed 's/ //g' | grep dbname | awk  -F"=" '{print $2}'`;
        DB_USERNAME=`awk -F";" '{print $1}' $config | sed 's/ //g' | grep dbuser | awk  -F"=" '{print $2}'`;
        DB_PASSWORD=`awk -F";" '{print $1}' $config | sed 's/ //g' | grep dbpass | awk  -F"=" '{print $2}'`;

        mysql_connect_data_v2_internal_test_settings $config
        if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
            return 0;
        fi
    else 
        if [ "$TEST_MODE" != "test" ]; then 
            mkdir -p /etc/mor

            report "It seems that this server is running only the database. Please provide connection details to MOR database in order the scripts would work - we will create a MOR DB configuration file: /etc/mor/mor_db_connect_data.cnf" 3

            read_user_input "Please provide MySQL host (press enter for default: localhost): " "localhost"
            DB_HOST="$GET_VALUE"

            read_user_input "Please provide MySQL database name (press enter for default: mor): " "mor"
            DB_NAME="$GET_VALUE"

            read_user_input "Please provide MySQL database username (press enter for default: mor): " "mor"
            DB_USERNAME="$GET_VALUE"

            read_user_input "Please provide MySQL database password (press enter for default: mor): " "mor"
            DB_PASSWORD="$GET_VALUE"

            echo -e "dbhost=$DB_HOST\ndbname=$DB_NAME\ndbuser=$DB_USERNAME\ndbpass=$DB_PASSWORD\n" > /etc/mor/mor_db_connect_data.cnf

            mysql_connect_data_v2_internal_test_settings $config
            if [ "$?" == "0" ] && [ "$TEST_MODE" != "test" ]; then  #will not continue searching if correct settings were found.
                return 0;
            fi
        fi
    fi

    return 1;       #none settings were correct
}

magento_mysql_connect_data()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function gets magento installation database settings

    DATABASE_username=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/username $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_password=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/password $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_DB_NAME=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/dbname $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_host=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/host $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
}

#====== Network ======
check_if_address_is_accessible()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2011
    #   About:  This function checks if an address is accessible via icmp. If any request fails - failed status is reported
    #
    #   Arguments:
    #       $1  -   Server IP ir domain
    #       $2  -   Number of times to ping
    #
    #   Returns:
    #       0   -   OK, address is accessible
    #       1   -   Failed, address is not accessible
    #
    #   Example:
    #       check_if_address_is_accessible svn.kolmisoft.com 2
    #

    local addresssToPing="$1";
    local numberOfPings="$2";

    ping -c $numberOfPings $addresssToPing &> /dev/null
    local STATUS="$?"
    if [ $STATUS == "0" ]; then
        return 0;
    else
        return 1;
    fi
}
default_interface_ip()
{
    #Author: Mindaugas Mardosas
    #This function makes available in your scripts 2 variables: DEFAULT_INTERFACE  - this will be the name of the default interface throw which the traffic will be routed when no other destination adress mathced in kernel routing table. DEFAULT_IP - this is the IP assigned to DEFAULT_INTERFACE
    #How to use this function:
        # write anywhere in your script a call to this function and then you can use those two global variables for that script. Example:
        #       default_interface_ip;
        #       echo $DEFAULT_INTERFACE;
        #       echo $DEFAULT_IP;

    DEFAULT_INTERFACE=`/bin/netstat -nr | (read; cat) | (read; cat) | grep "^0.0.0.0" | awk '{ print $8}' | head -n 1` #Gets kernel routing table, when skips 2 first lines, when grep's the default path and finally prints the interface name
    DEFAULT_IP=`/sbin/ip addr show $DEFAULT_INTERFACE | grep "inet " | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`
    DEFAULT_INTERFACE_MAC=`/sbin/ifconfig | grep eth | awk -F'HWaddr' '{print $2}' | sed 's/ //g'`
}
#=========Fail2Ban=====
fail2ban_started()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This function checks if fail2ban is running.

#   Returns:
#       0 - Fail2Ban is running
#       1 - Fail2Ban is not running

    /etc/init.d/fail2ban status &> /dev/null
    RUNNING="$?"
    if [ "$RUNNING" == "0" ]; then
        return 0;
    else
        return 1;
    fi
}
fail2ban_installed()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This function checks if fail2ban is installed. If not - fixes that.

# Returns:
    # 0 - OK
    # 1 - failed to fix
    # 4 - fixed

    if [ -f "/etc/fail2ban/jail.conf" ]  && [ -f "/etc/fail2ban/fail2ban.conf" ]  && [ -f  "/etc/init.d/fail2ban" ]; then
        fail2ban_started
        if [ "$?" == "0" ]; then
            #report "Fail2Ban is installed and running" 0
            return 0
        else
            /etc/init.d/fail2ban start

            fail2ban_started    #testing again if fail2ban started successfully
            if [ "$?" == "0" ]; then
                return 4 #fixed
            else
                return 1 #failed to fix
            fi
        fi
    else
        fail2ban_started
        if [ "$?" == "0" ]; then
            return 0    # OK
        else
            return 1    # FAILED
        fi
    fi
}
fail2banAddressesToIgnore()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function generates a list of addresses that should not be blocked by fail2ban

    IGNORE_ADDRESSES="192.168.0.1/16 10.0.0.0/8 127.0.0.1/8 172.16.0.0/12 46.251.50.103 "

    ifconfig | sed -n '/^[A-Za-z0-9]/ {N;/dr:/{;s/.*dr://;s/ .*//;p;}}' | while read IP; do
        echo -n " $IP" >> /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt
    done
    OTHER_ADDRESSES=`cat /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt`
    rm -rf /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt #clean
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf_backup_$mor_time
    ruby /usr/src/fail2ban-0.8.4/files/change_first_found_param_in_file.rb /etc/fail2ban/jail.conf "ignoreip =" "ignoreip = 192.168.0.1/16 10.0.0.0/8 127.0.0.1/8 172.16.0.0/12 46.251.50.103 $OTHER_ADDRESSES"
}


#=========SVN==========
checkoutMor()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks out mor version and revision you ask
    #
    #   Arguments:
    #       $1  -   MOR version (must match path in svn)
    #       $2  -   MOR revision
    #       $3  -   Where to checkout
    #
    #   Example:
    #       checkoutMor 8 7212 /tmp/mor

    morVersion="$1"
    morRevision="$2"
    whereToCheckout="$3"

    if [ ! -f /usr/bin/svn ]; then
        yum -y install subversion
        if [ "$?" != "0" ]; then
            report "Failed to install subversion"
            exit 1
        fi
    fi

    echo "Checking out GUI: $TEST_MOR_VERSION Revision: $TEST_REVISION "
    if [ "$morVersion" == "trunk" ]; then
        svn co -r $morRevision http://svn.kolmisoft.com/mor/gui/trunk $whereToCheckout  &> /dev/null
    elif [ "$morVersion" == "crm" ]; then
        svn co -r $morRevision http://svn.kolmisoft.com/crm/trunk $whereToCheckout  &> /dev/null
    else
        svn co -r $morRevision http://svn.kolmisoft.com/mor/gui/branches/$morVersion $whereToCheckout &> /dev/null
    fi

    STATUS="$?"
    if [ "$?" == "0" ]; then
        report "Successfully checked out MOR $morVersion Revision: $morRevision" 0
        return 0
    else
        report "Failed to checkout out MOR $morVersion Revision: $morRevision" 1
        return 1
    fi
}
updateOrDowngradeMorRevision()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function updates/downgrades mor gui to version and revision you ask. Be carefull with this function - it cares only about GUI
    #
    #   Arguments:
    #       $1  -   MOR version (must match path in svn)
    #       $2  -   MOR revision
    #       $3  -   Where to checkout
    #
    #   Example:
    #       updateOrDowngradeMorRevision 8 7212 /tmp/mor

    morVersion="$1"
    morRevision="$2"
    whereToCheckout="$3"

    if [ ! -f /usr/bin/svn ]; then
        yum -y install subversion
        if [ "$?" != "0" ]; then
            report "Failed to install subversion"
            exit 1
        fi
    fi

    echo "Changing MOR GUI revision"
    if [ "$morVersion" == "trunk" ]; then
        svn update -r $morRevision http://svn.kolmisoft.com/mor/gui/trunk $whereToCheckout  &> /dev/null
    elif [ "$morVersion" == "crm" ]; then
        svn update -r $morRevision http://svn.kolmisoft.com/crm/trunk $whereToCheckout  &> /dev/null
    else
        svn update -r $morRevision http://svn.kolmisoft.com/mor/gui/branches/$morVersion $whereToCheckout &> /dev/null
    fi

    STATUS="$?"
    if [ "$?" == "0" ]; then
        report "Successfully updated MOR $morVersion Revision: $morRevision" 0
        return 0
    else
        report "Failed to updated out MOR $morVersion Revision: $morRevision" 1
        return 1
    fi
}
#--------------Rotation-----------------
rotate_files_dirs()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2011
    #   About:  This function rotates a given number of files or directories in a specified dir. The function works in the folllowing way: sorts all folder content with command ls -1 ant deletes the first entry if overall count is higher that specified

    #   Arguments:
    #       $1  -   directory to rotate
    #       $2  -   number of newest files/directories to keep
    #       $3  -   "on"/"off"  messages

    #   Returns:
    #       0   -   OK, rotate was successfull
    #       1   -   Rotate failed
    #       2   -   the directory provided does not exist

    #   Example:
    #       rotate_files_dirs /var/lib/mysql_pool/9 3 on

    local dirToRotate="$1";
    local filesToKeep="$2";
    local msgToDisplay="$3";

    if [ ! -d "$dirToRotate" ]; then
        if [ "$msgToDisplay" == "on" ]; then
            echo "Failed to rotate dir - dir provided does not exist";
        fi
        return 2;
    fi

    local numberOfFilesOrDirs=`ls -1 $dirToRotate | wc -l`;

    if  [ "$numberOfFilesOrDirs" -gt "$filesToKeep" ]; then
        fileDirToDelete=`ls -1 $dirToRotate | head -n 1`;
        rm -rf "$dirToRotate"/"$fileDirToDelete";
        if [ "$?" == "0" ]; then
            if [ "$msgToDisplay" == "on" ]; then
                echo "SUccessfully rotated $dirToRotate";
            fi
            #--------Checking again how many files/directories are left
            local numberOfFilesOrDirs=`ls -1 $dirToRotate | wc -l`;
            if  [ "$numberOfFilesOrDirs" -gt "$filesToKeep" ]; then
                rotate_files_dirs $dirToRotate $filesToKeep $msgToDisplay
            else
                return 0;
            fi
        else
            if [ "$msgToDisplay" == "on" ]; then
                echo "Failed to rotate dir";
            fi
            return 1;
        fi
    else
            if [ "$msgToDisplay" == "on" ]; then
            echo "Nothing to rotate";
        fi
    fi
}

mnp_enabled()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function detects if MNP database exists. If exists - that means that MNP database is enabled
	#
	# Returns:
	#	0	-	MNP is enabled
	#	1	-	MNP is not enabled


    mysql_connect_data_v2 > /dev/null
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD -e "use mor_mnp" &> /dev/null
    if [ "$?" == "0" ]; then
        MNP_ENABLED=0
    else
        MNP_ENABLED=1
        return 1
    fi

#   old logic....
#
#    if [ -f /usr/local/mor/mor_mnp.conf ]; then
#	    return 0
#    else
#        if [ -f /home/mor/config/environment.rb ]; then
#	        MNP_Activated=`awk -F"#" '{print $1}' /home/mor/config/environment.rb | grep MNP_Active | awk '{print $NF}'`
#	        if [ "$MNP_Activated" == "1" ]; then
#		        return 0
#	        else
#		        return 1
#	        fi
#        else
#            return 1
#        fi
#    fi
}

selinux_installed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function detects if selinux is installed

    if [ -f "/usr/sbin/sestatus" ]; then
        return 0
    else
        return 1
    fi
}

asterisk_rpms()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script checks if there is Asterisk installed from RPMs. If yes - such server has to be reinstalled
    #
    # Returns:
    #   0   -   OK, Asterisk RPMs were not detected
    #   1   -   FAILED, Asterisk RPMs were detected

    if [ `rpm -qa | grep asterisk | wc -l` == "0" ]; then
        return 0
    else
        # http://trac.kolmisoft.com/trac/ticket/4434
        # Order an engineer to reinstall the server
        report "Asterisk installation detected from RPM packets. The server must be reinstalled" 1
        read
        exit 1
    fi
}
#------------
check_ping()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if the server can ping the given address 3 times successfully
    #
    # Arguments:
    #   $1 - Address to ping, for example: google.com

    # Returns:
    #   0   -   OK
    #   1   -   Failed

    local ADDRESS_TO_PING="$1"
    ping -c 3 $ADDRESS_TO_PING | grep "3 received" &> /dev/null

    if [ "$?" == "0" ]; then
        return 0
    else
        return 1
    fi
}
#------------
svn_repo_accessibility()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if a given svn repository is accessible for the server
    #
    # Arguments:
    #   $1   -   IP/HOSTNAME to svn repo
    #   $2   -   remaining URL to the exact repo
    #
    #
    # Example:
    #   svn_repo_accessibility "svn.kolmisoft.com" "mor/gui/trunk"

    local M_HOSTNAME="$1"
    local M_REMAINING_URL="$2"

    svn list http://$M_HOSTNAME/$M_REMAINING_URL &> /dev/null
    if [ "$?" == "0" ];  then
        report "svn list http://$M_HOSTNAME/$M_REMAINING_URL ok" 0
        return 0
    else
        report "svn list http://$M_HOSTNAME/$M_REMAINING_URL failed. That is a sign of network problems in this server. Checking if $M_HOSTNAME at least responds to ping" 1
        check_ping "$M_HOSTNAME"
        if [ "$?" == "0" ]; then
            report "[OK] ping -c 3 $M_HOSTNAME" 3
            return 1
        else
            report "ping -c 3 $M_HOSTNAME" 1
            return 1
        fi
    fi
}
#----------------------------------------
current_ssh_session_ip()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function retrieves SSH_CLIENT IP from env
    #
    # Returns:
    #   $ssh_env_ip - holds the ip of user who connected and is working with all these scripts.

    ssh_env_ip=`env | grep SSH_CLIENT | awk -F"=| " '{print $2}'`
}
#---------------------------------------
log_revision()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This is a logging function.
    #
    # Arguments:
    #   $1 - kolmisoft product: [ 'mor' ]
    #   $2 - component: ['gui']

    local product="$1"
    local component="$2"
    local notes="$3"

    _mor_time
    current_ssh_session_ip

    if [ "$product" == "mor" ]; then
        mkdir -p /var/log/mor
        mor_gui_current_version
        gui_revision_check
        mkdir -p /var/log/mor
        echo "$mor_time $ssh_env_ip $MOR_VERSION_YOU_ARE_TESTING $GUI_REVISION_IN_SYSTEM $notes" >> /var/log/mor/gui_version_log
    fi
}

detect_vm()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011-2013
    # About:    This script detects if the machine is a Virtual Machine.
    #
    # Returns:
    #   0   -   VM detected
    #   1   -   VM not detected
    #
    # Variable:
    #   VM_DETECTED=[0 - not detected, 1 - detected]

    VM_DETECTED=1
    if [ -f /proc/sys/xen ] || [ -f /sys/bus/xen ] || [ -f /proc/xen ]; then
        VM_TYPE="XEN"
        return 0;
    fi

    if [ ! -f /sbin/lspci ]; then
        yum -y install pciutils
    fi

    if [ -f /proc/vz/veinfo ]; then
        VM_TYPE="OpenVZ"
        return 0;
    fi

    local KVM=`lspci 2> /dev/null | grep RAM | grep Qumranet | wc -l`
    if [ "$KVM" == "1" ]; then
        VM_TYPE="KVM"
        return 0;
    fi

    #--- VMware
    local VMware=`lspci | grep VMware | wc -l`
    if [ "$VMware" != "0" ]; then
        VM_TYPE="VMWARE"
        return 0;
    fi
    
    #--- VirtualBox ---
    local VirtualBox=`lspci | grep VirtualBox | wc -l`
    if [ "$VirtualBox" != "0" ]; then
        VM_TYPE="VirtualBox"
        return 0;
    fi    
    
    #--- Qemu ---
    local QEMU=`cat /proc/cpuinfo | grep -F QEMU | wc -l`
    if [ "$QEMU" != "0" ]; then
        VM_TYPE="QEMU"
        return 0;
    fi  

    #--- LXC ---
    if [ -f "/proc/1/cgroup" ]; then
        local LXC=`grep lxc /proc/1/cgroup | wc -l`
        if [ "$LXC" != "0" ]; then
            VM_TYPE="LXC"
            return 0;
        fi 
    fi
    
    VM_DETECTED=0
    return 1 # VM not detected
}
# ---- RVM functions ----
rvm_is_installed()
{
    #   Author: Mindaugas Mardosas
    #   Year:  2011
    #   About:  This function checks if rvm (ruby version manager) is installed in the system.
    #
    #   Returns:
    #       0   -   OK, installed
    #       1   -   FAILED, not installed

    rvm list &> /dev/null
    if [ "$?" == "0" ]; then
        RVM_INSTALLED=0
        return 0;
    else
        RVM_INSTALLED=1
        return 1;
    fi
}
vercomp() {
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function compares version numbers
    #
    # Returns:
    #    0) op='=';;
    #    1) op='>';;
    #    2) op='<';;

    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
get_answer()
{
    #   Author: Nerijus Sapola
    #   Year:   2012
    #   About:  This function asks users question and returns y or n depending on answer. Default value returned if user hits Enter.
    #           Function does not allow any other answers, just y or n.
    #
    #   Returns:
    #   $answer - variable which contains "y" or "n"
    #
    #   Parameters:
    #       $1 - question
    #       $2 - default value (used if Enter is pressed). Should be "y" or "n"
    #
    #   Example: get_answer "are you ok?" "y"
    #
    if [ "$2" == "y" ]; then
        echo "$1 (Y/n)";
    elif [ "$2" == "n" ]; then
        echo "$1 (y/N)";
    else
        echo "Invalid default value parameter: $2"
        exit 1
    fi

    read answer;
    if [ -z "$answer" ]; then
        answer="$2"              #default value. Applied if Enter is pressed without entering any value.
    else
        while [ "$answer" != "y" ] && [ "$answer" != "n" ]; do
            echo "YES or NO? (y/n)"
            read answer
        done
    fi
}
get_last_stable_mor_revision()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function is used to retrieve last stable MOR GUI revision number
    #
    # Arguments:
    #   $1 - MOR_VERSION    # For which version to determine the last stable revision?
    #
    # Returns:
    #   LAST_STABLE_GUI - this variable contains last stable revision number

    MOR_VERSION_TO_CHECK="$1"

    LAST_STABLE_GUI=`cat /usr/src/mor/upgrade/$MOR_VERSION_TO_CHECK/stable_revision | head -n 1`
}
check_if_ip_is_registered_in_kolmisoft_support_system()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function checks if server IP is registered in Kolmisoft support system
    #
    # Arguments:
    #   $1 - Server IP
    #
    # Returns:
    #    0  -   server is registered
    #    1  -   server is NOT registered
    
    IP="$1"
    if [ `curl "https://support.kolmisoft.com/api/ip_present?ip=$IP" 2> /dev/null | grep 1 | wc -l` == "0" ]; then
        return 1    # not found
    else
        return 0    #found
    fi
}
mor_version_mapper()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function checks if server IP is registered in Kolmisoft support system
    #
    # Arguments:
    #   $1 - version as users call it - Extend, ROR3, X3 or whatever.
    #
    # Returns:
    #
    #   MOR_MAPPED_VERSION_WEIGHT -  weight of version. Use it in various to determine if some upgrade is needed or not
    
    
    local VERSION="$1"
    if [ "$VERSION" == "0.8" ] || [ "$VERSION" == "8" ]; then
        MOR_MAPPED_VERSION_WEIGHT="80"
        return 80
    fi
    if [ "$VERSION" == "9" ]; then
        MOR_MAPPED_VERSION_WEIGHT="90"
        return 90
    fi
    if [ "$VERSION" == "10" ]; then
        MOR_MAPPED_VERSION_WEIGHT="100"
        return 100
    fi
    if [ "$VERSION" == "11" ]; then
        MOR_MAPPED_VERSION_WEIGHT="110"
        return 110
    fi
    if [ "$VERSION" == "extend" ] || [ "$VERSION" == "12.126" ]; then
        MOR_MAPPED_VERSION_WEIGHT="120"
        return 120
    fi
    if [ "$VERSION" == "ror3" ] || [ "$VERSION" == "12" ] || [ "$VERSION" == "x3" ]; then   # Ask older Kolmisoft staff about this mess :)
        MOR_MAPPED_VERSION_WEIGHT="123"
        return 123
    fi    
    if [ "$VERSION" == "x4" ]; then
        MOR_MAPPED_VERSION_WEIGHT="140"
        return 140
    fi
    if [ "$VERSION" == "x5" ]; then
        MOR_MAPPED_VERSION_WEIGHT="150"
        return 150
    fi
    
    if [ "$VERSION" == "m2" ]; then
        MOR_MAPPED_VERSION_WEIGHT="160"
        return 160
    fi
}

mor_db_version_mapper()
{
    # Author: Mindaugas Mardosas
    # Year:   2013
    # About:  This function checks if shell is running in screen
    #
    # Returns:
    #
    #   MOR_MAPPED_DB_VERSION - DB version. Rurned MOR_MAPPED_DB_VERSION variable exactly matches the one returned by mor_version_mapper function.
    
    mysql_connect_data_v2 > /dev/null

    MOR_MAPPED_DB_VERSION=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'mor_mapped_db_version' LIMIT 1" | (read; cat)`
    if [ "$MOR_MAPPED_DB_VERSION" == "" ]; then
        MOR_MAPPED_DB_VERSION="0"   # Means that value is not found
    fi
    return $MOR_MAPPED_DB_VERSION
}


are_we_inside_screen()
{
    # Author: Mindaugas Mardosas
    # Year:   2012
    # About:  This function checks if shell is running in screen
    #
    # Returns:
    #
    #   0 - OK, you are running in screen
    #   1 - Failed, you are not running in screen
    
    if [ "$TERM" == "screen" ]; then
        return 0
    else
        return 1  
    fi
    
}

postfix_running()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function checks if postfix service is running
    #
    #   Returns:
    #       0   -   Failed. Postfix is not running
    #       1   -   OK, Postfix is running
    #    
    #       Global variable: POSTFIX_STATUS
    
    POSTFIX_STATUS=`service postfix status | grep running | wc -l`
    return  $POSTFIX_STATUS
}

gemset_check_and_create()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function creates ruby gemset for requested ruby version if it does not exist
    #
    #   Parameters:
    #       1   - ruby version for which gemset has to be created
    #       2   - gemset version
    #
    #   Return:
    #       0   -   gemset was already present
    #       1   -   Failed to create gemset
    #       4   -   gemset was successfully created
    
    local ruby_version="$1"
    local gemset_version="$2"
    
    if [ `rvm $ruby_version gemset list | grep $gemset_version | wc -l` == "0" ]; then
        rvm $ruby_version gemset create $gemset_version
        if [ `rvm $ruby_version gemset list | grep $gemset_version | wc -l` == "0" ]; then
            report "Failed to create gemset $gemset_version for ruby: $ruby_version" 1
            return 1
        else
            report "Create gemset $gemset_version for ruby: $ruby_version" 4
            return 4
        fi
    else
        return 0
    fi
}

calls_in_db()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    This script checks how many calls are there in DB.
    #
    # Returns:
    #   CALLS_IN_DB - global variable containing the amount of calls.
    #   As exit code this function also returns the amount of calls.
    #
    # Important notes:
    #   Be sure that function mysql_connect_data_v2 is called before calling this function!!!!
    
    local TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" -e "SELECT count(*) FROM calls;" | (read; cat) > $TMP_FILE
    CALLS_IN_DB=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
    return $CALLS_IN_DB
}

do_not_allow_to_downgrade_if_current_gui_higher_than()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function will prevent downgrading the system if it already has a higher version of MOR
    #
    #   Arguments:
    #       $1 - do not upgrade if system has higher MOR version than this variable - check function mor_version_mapper for correct values
    
    local DO_NOT_UPGRADE_IF_VERSION_HIGHER_THAN="$1"
    
    mor_gui_current_version
    mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
    if [ "$MOR_MAPPED_VERSION_WEIGHT" -gt "$DO_NOT_UPGRADE_IF_VERSION_HIGHER_THAN" ]; then
        report "You already have a higher MOR version, downgrading without damaging the system is not possible" 1
        exit 0 
    fi     
}
space_in_remote_server()
{
    #   Auhor:  Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks if there are more free space when specified by argument
    #
    #   In order this function would work - passwordless SSH keys must be installed
    #
    #   Arguments:
    #       $1 - username
    #       $2 - port
    #       $3 - host
    #       $4 - higher % than x. For example  10%
    #
    #   Returns:
    #       $SPACE_OK = {"OK", "FAILED"}
    #
    #   Usage example:
    #       space_in_remote_server root 22 "192.168.1.116" 10
    
    
    local username=$1
    local port=$2
    local host=$3
    local percent=$4
    
    DF_output=`ssh $username@$host -p$port 'df -h |  grep "/$"'`
    SPACE_LEFT_PERCENT=`echo $DF_output | awk '{print $5}' | awk -F'%' '{print $1}'`
    echo $SPACE_LEFT_PERCENT
    
    if [ "$SPACE_LEFT_PERCENT" -gt "$percent" ]; then
        SPACE_OK="OK"
        return 0
    else
        SPACE_OK="FAILED"
        return 1
    fi
}
get_mor_admin_email()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This script gets MOR admin email.
    #
    #   Returns:
    #       0   -   Email found
    #       1   -   Email not found
    #
    #       Global variable: $ADMIN_EMAIL
    
    mysql_connect_data_v2  > /dev/null
    local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT email FROM  addresses WHERE id = 1;"`
    ADMIN_EMAIL=`echo $RESULT | awk '{print $2}'`    
    
    if [ "$ADMIN_EMAIL" == "" ]; then
        return 1 # Email not found
    else
        return 0 # Email found
    fi
}
get_mor_admin_smtp_settings()
{
    #   Author:   Mindaugas Mardosas
    #   Year:     2013
    #   About:    This functions gets MOR email settings.
    #
    #   Returns:
    #       SMTP_SERVER
    #       SMTP_PORT
    #       SMTP_USERNAME
    #       SMTP_PASSWORD
    #       SMTP_EMAIL_FROM # Required and encouraged to use this because some SMTP servers filter relay address
    #       EMAIL_SENDING_ENABLED { 0 - not enabled, 1 - enabled}
    
    mysql_connect_data_v2  > /dev/null
    
    DEBUG=0;    # {0 - disabled, 1 - enabled}
    
    #MAIL_SENDING_ENABLED
    local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_Sending_Enabled' AND owner_id=0 LIMIT 1;"`
    EMAIL_SENDING_ENABLED=`echo $RESULT | awk '{print $2}'`
    
    if [ "$DEBUG" == "1" ]; then
        echo "EMAIL_SENDING_ENABLED: $EMAIL_SENDING_ENABLED"
    fi

    if [ "$EMAIL_SENDING_ENABLED" == "1" ]; then
        #SMTP_SEVER
        local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_Smtp_Server' AND owner_id=0 LIMIT 1;"`
        SMTP_SERVER=`echo $RESULT | awk '{print $2}'`
        if [ "$DEBUG" == "1" ]; then
            echo "SMTP_SERVER: $SMTP_SERVER"
        fi
        
        #SMTP_PORT
        local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_port' AND owner_id=0 LIMIT 1;"`
        SMTP_PORT=`echo $RESULT | awk '{print $2}'`
        if [ "$DEBUG" == "1" ]; then
            echo "SMTP_PORT: $SMTP_PORT"
        fi        
        
        #SMTP_USERNAME
        local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_Login' AND owner_id=0 LIMIT 1;"`
        SMTP_USERNAME=`echo $RESULT | awk '{print $2}'`
        if [ "$DEBUG" == "1" ]; then
            echo "SMTP_USERNAME: $SMTP_USERNAME"
        fi
        
        #SMTP_PASSWORD
        local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_Password' AND owner_id=0 LIMIT 1;"`
        SMTP_PASSWORD=`echo $RESULT | awk '{print $2}'`
        if [ "$DEBUG" == "1" ]; then
            echo "SMTP_PASSWORD: $SMTP_PASSWORD"
        fi
        
        # SMTP_EMAIL_FROM
        local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT value FROM conflines WHERE name = 'Email_from' AND owner_id=0 LIMIT 1;"`
        SMTP_EMAIL_FROM=`echo $RESULT | awk '{print $2}'`
        if [ "$DEBUG" == "1" ]; then
            echo "SMTP_EMAIL_FROM: $SMTP_EMAIL_FROM"; 
        fi
    fi
    
}
add_logrotate_if_not_present()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function adds logrotate if it is not present
    #
    #   Arguments:
    #       $1  -   path log file
    #       $2  -   logrotate name in /etc/logrotate.d foler
    #
    #   Example usage:
    #       add_logrotate_if_not_present "/var/log/mor/ami_debug.log" "mor_ami_debug"
    
    local logPath="$1"
    local logrotateName="$2"
    
    if [ ! -f /etc/logrotate.d/$logrotateName ] && [ `grep "$logPath" /etc/logrotate.conf | wc -l` == "0" ] ; then
        echo "$logPath {
            daily
            compress
            rotate 2
            create
            }" > /etc/logrotate.d/$logrotateName
            
        chmod 644 /etc/logrotate.d/$logrotateName

        if [ -f "/etc/logrotate.d/$logrotateName" ]; then
            report "Added new logrotate for $logPath: /etc/logrotate.d/$logrotateName" 4
        else
            report "Failed to add new logrotate for $logPath: /etc/logrotate.d/$logrotateName" 1
        fi
    else
	report "Logrotate $logrotateName already present" 0
    fi
}

add_critical_logrotates_if_not_present ()
{

    # add logroates critical to MOR system
    # GUI - production.log_
    # asterisk - messages/full
    
    # Due historic reasons these logrotates go to /etc/logrotate.conf config file

    
    if ! grep -q '/home/mor/log/production.log' /etc/logrotate.conf; then
        echo "/home/mor/log/production.log  {
              daily
              compress
              rotate 7
              create
              copytruncate
              }
              " >> /etc/logrotate.conf
              
              if grep -q '/home/mor/log/production.log' /etc/logrotate.conf; then
                 report "Added new logrotate for /home/mor/log/production.log in /etc/logrotate.conf file" 4
              else
                 report "Failed to add new logrotate for /home/mor/log/production.log in /etc/logrotate.conf file" 1
              fi
    fi
    
    
    
   
    if ! grep -q '/var/log/asterisk/messages' /etc/logrotate.conf; then
        echo "/var/log/asterisk/messages /var/log/asterisk/full {
              missingok
	      daily
	      compress
	      rotate 14
	      create
	      postrotate
	          /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
	      endscript
	      }
	      " >> /etc/logrotate.conf
	      
	      if grep -q '/var/log/asterisk/messages' /etc/logrotate.conf; then
                 report "Added new logrotate for /var/log/asterisk/messages and /var/log/asterisk/full in /etc/logrotate.conf file" 4
              else
                 report "Failed to add new logrotate for /var/log/asterisk/messages and /var/log/asterisk/full in /etc/logrotate.conf file" 1
              fi
    fi  
    
    
}

cpu_count()
{
    
    #    Author: Mindaugas Mardosas
    #    Year:   2013
    #    About:  This function determines the cpu count in server
    # 
    #    Returns:
    #        NUMBER_OF_CPUS  -   global variable assigned the number of CPUs
    #
    
    NUMBER_OF_CPUS=`grep -c ^processor /proc/cpuinfo`
}

validateIP()
{
    #    Author: Mindaugas Mardosas
    #    Year:   2013
    #    About:  This function validates given IP address
    #    Arguments:
    #       $1  -   IP to validata
    #
    #    Returns:
    #       0  -   IP address is invalid
    #       1   -  IP address is valid
    #
    #    Returns global variable:
    #        IP_IS_VALID - {"TRUE", "FALSE"}
    #
    #

    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi

    if [ "$stat" == "0" ]; then
        IP_IS_VALID="TRUE"
    else
        IP_IS_VALID="FALSE"
    fi
    return $stat
}
mor_resolve_ip()
{
    #    Author: Mindaugas Mardosas
    #    Year:   2013
    #    About:  This function resolves given address to IP
    #    Arguments:
    #       $1  -   Hostname to resolve
    #
    #    Returns:
    #        RESOLVED_IP - global variable assigned the number of CPUs
    #
    
    HOSTNAME_TO_RESOLVE="$1"
    RESOLVED_IP=`host $HOSTNAME_TO_RESOLVE | head -n 1 | awk '{print $NF}'`
    
    validateIP "$RESOLVED_IP"
    if [ "$IP_IS_VALID" == "FALSE" ]; then
        RESOLVED_IP="FALSE"
    fi
}
check_if_there_is_enough_space_to_dump_and_archive_mor_db()
{
    #   Author:   Mindaugas Mardosas
    #   Year:     2013
    #   About:    This functions checks if there are enough free space to create backup and compress it.
    #
    #   Arguments:
    #       $1  -   path where function should check for FREE space
    #
    #
    #   Returns:
    #       0   -   OK, there is enough FREE space to create a backup and compress it.
    #       1   -   There is not enough FREE space to create a backup and compress it.
    #
    #   Returns global variables:
    #       LOCATION_SPACE  -  how much FREE space the location asked has in bytes
    #       MOR_TABLES_CONSUME  -   how much MOR database tables consume on hard disk in bytes
    #       SPACE_NEEDED_FOR_BACKUP  -   calculated FREE space needed for backup and compression

    local LOCATION_TO_CHECK="$1"
    
    # ------ Variables ------
    DEBUG=0
    
    # --- MOR tables space without junk tables-----
    mysql_connect_data_v2  > /dev/null
    local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT ROUND(SUM(Data_length)/1024) AS SIZE FROM  INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_SCHEMA = '$DB_NAME' AND   TABLE_NAME  != 'call_logs' AND   TABLE_NAME  != 'sessions'"`
    MOR_TABLES_CONSUME=`echo $RESULT | awk '{print $2}'`
    
    #------- System space ------
    LOCATION_SPACE=`df -P $LOCATION_TO_CHECK | (read; awk '{print $4}')`
    
    if [ "$DEBUG" == "1" ]; then
        report "System space: $LOCATION_SPACE; MOR tables space: $MOR_TABLES_CONSUME" 3
    fi
    
    SPACE_NEEDED_FOR_BACKUP=`echo "$MOR_TABLES_CONSUME * 2 " | bc`
    
    if [ ! "$LOCATION_SPACE" -gt "$SPACE_NEEDED_FOR_BACKUP" ]; then
        # There is NOT enough FREE space.
        DISK_SPACE=1
        return 1
    else
        DISK_SPACE=0
        return 0
    fi 
}


dump_mor_db()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function is responsible for doing full MOR DB dump.
    #
    # Arguments:
    #   $1  -   Backup dir - where backup has to be store
    #
    # Returns:
    #   0   OK
    #   1   Failed to create backup
    #   3   DB backup already exists in provided directory
    BACKUP_DIR="$1"

    if [ ! -d "$BACKUP_DIR" ]; then
        BACKUP_DIR="/home"
    fi

    _mor_time

    PATH_TO_BACKUP="$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.tar.gz"

    if [ -f "$PATH_TO_BACKUP" ]; then
        report "DB backup already exists: $PATH_TO_BACKUP . Rename existing backup if would like another one would be created" 3
        return 3
    fi

    #====== Check if there is enough free space to dump ===============
    check_if_there_is_enough_space_to_dump_and_archive_mor_db $BACKUP_DIR
    if [ "$DISK_SPACE" == "1" ]; then
        report "There is not enough free space in $BACKUP_DIR. Please specify another directory" 3
        read BACKUP_DIR
        if [ ! -d "$BACKUP_DIR" ]; then
            report "Your provided path is not a directory" 1
            return 1
        else
            check_if_there_is_enough_space_to_dump_and_archive_mor_db $BACKUP_DIR
            if [ "$DISK_SPACE" == "1" ]; then
                report "There is not enough free space in $BACKUP_DIR. Exiting" 1
                return 1
            fi
        fi
    fi
    #==================================================================


    mysql_connect_data_v2  > /dev/null
    report "Dumping database to $BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql" 3
    mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql"

    if [ ! -f  "$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql" ]; then
        report "Failed to dump $BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql. Exiting" 1
        return 1
    fi

    report "Compressing database $BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql to $BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.tar.gz" 3
    
    cd $BACKUP_DIR
    tar czf "$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.tar.gz" "DB_BACKUP_$CURRENT_DATE.sql"
    STATUS="$?"

    rm -rf "$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.sql"

    if [ "$STATUS" == "0" ] && [ -f "$BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.tar.gz" ]; then
        report "Database backup prepared successfully: $BACKUP_DIR/DB_BACKUP_$CURRENT_DATE.tar.gz" 3
        return 0
    else
        return 1
    fi
}

check_if_db_index_present()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks if index is present in table
    #
    #   Arguments:
    #
    #       $1  -   table_name
    #       $2  -   index name
    #   Returns:
    #       0 - index is not present
    #       1 - index is present
    #       >1 - column has duplicate indexes

    TABLE="$1"
    INDEX_NAME="$2"
    
    mysql_connect_data_v2      &> /dev/null
    return `/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e "SHOW indexes FROM $TABLE;" | awk '{print $3}' | grep  "^$INDEX_NAME\$" | wc -l` 

}
check_if_db_column_exists()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks if DB column exists
    #
    #   Requires:
    #       This function requires that mysql_connect_data_v2 would be initialized in order all its connection variables would be made available.
    #
    #   Arguments:
    #       $1  - DB table
    #       $2  - table column to check
    #
    #   Returns:
    #       0   -   table column not found
    #       1   -   table column found

    DB_TABLE_TO_CHECK="$1"
    TABLE_COLUMN_TO_CHECK="$2"

    COLUMN_EXISTS=0 # not found
    if [ `/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e "DESC $DB_TABLE_TO_CHECK;" |  awk '{print $1}' | grep "^$TABLE_COLUMN_TO_CHECK\$" | wc -l` == "1" ]; then
        COLUMN_EXISTS=1 # found
    fi
    return $COLUMN_EXISTS
}

svn_last_change_info()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks last SVN commit information

    LAST_SVN_CHANGE_REVISION=`svn info /home/mor | grep "Last Changed Rev:" | awk '{print $NF}'`
    LAST_SVN_CHANGE_AUTHOR=`svn info /home/mor | grep "Last Changed Author:" | awk '{print $NF}'`
    LAST_SVN_CHANGE_TIME=`svn info /home/mor | grep "Last Changed Date:" | awk -F": " '{print $NF}' | awk '{print $1" "$2}'`
}

get_ccl_status()
{
    #   Author: Nerijus Sapola
    #   Year:   2013
    #   About:  Reads CCL option stats from database and returs 1 if it is on or 0 if it is off.

mysql_connect_data_v2      &> /dev/null
local RESULT=`/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -B --disable-column-names -e "select value from mor.conflines where name='CCL_Active'"`
if [ "$RESULT" != "1" ]; then
    CCL_STATUS=0
else
    CCL_STATUS=1;
fi
}

# run some functions to set vars
core_count
