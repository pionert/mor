#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012-2013
# About:    Script adds AST_18 = 1 variable to environment.rb on GUI server, if Asterisk 1.8 detected.
#           Also, reports about incorrect extlines separators.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------
asterisk_version=0

#----- FUNCTIONS ------------

#--------MAIN -------------


#checking for Asterisk 1.8 by extlines, because Asterisk can be on remote server
mysql_connect_data_v2

#--- Asterisk part ----
asterisk_is_running
if [ "$RUNNING" == "0" ]; then
    asterisk_current_version
    if [ "$ASTERISK_BRANCH" == "1.8" ]; then
        mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -s --skip-column-names -e "UPDATE extlines SET appdata=( REPLACE (appdata,'|', ',')) WHERE appdata not like \"\$[\$[%\${DIALSTATUS%CHANUNAVAIL%]|\$[%DIALSTATUS%CONGESTION%\";"
    fi
fi


# GUI Part

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

# Don't cry when looking at these few lines :)   See ticket http://trac.kolmisoft.com/trac/ticket/7019#comment:6
number_of_ast18_extlines=`mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -s --skip-column-names -e 'SELECT count(*) FROM extlines where appdata like "%,%" AND appdata not like "$[$[%${DIALSTATUS%CHANUNAVAIL%]|$[%DIALSTATUS%CONGESTION%";'`

number_of_pre_ast18_extlines=`mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -s --skip-column-names -e 'SELECT count(*) FROM extlines WHERE appdata like "%|%" AND appdata not like "$[$[%${DIALSTATUS%CHANUNAVAIL%]|$[%DIALSTATUS%CONGESTION%"';`

if [ "$number_of_ast18_extlines" -gt "0" ] && [ "$number_of_pre_ast18_extlines" -gt "0" ]; then
    report "Found not updated extlines after migration to different Asterisk version, please fix this manually" 
fi

if [ "$number_of_ast18_extlines" -gt "0" ]; then
    mor_gui_current_version
    if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "140" ]; then  #case of X4 or above
        ast18_addon_var=`mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -s --skip-column-names -e "select value from conflines where name='AST_18'"`
        if [ "$ast18_addon_var" == "1" ]; then
            report "AST_18 support is enabled in addons list" 0
        elif [ "$ast18_addon_var" == "NULL" ]; then
            report "AST_18 support is NOT enabled in addons list. Please enable it." 1
        else
            report "Unable to read AST_18 varaible status" 1
        fi
    else
        grep AST_18 /home/mor/config/environment.rb &> /dev/null #case below X4
        if [ "$?" == "0" ]; then
            report "AST_18 variable found on environment.rb" 0
        else
            echo "AST_18 = 1" >> /home/mor/config/environment.rb
            grep AST_18 /home/mor/config/environment.rb &> /dev/null
            if [ "$?" == "0" ]; then
                report "AST_18 = 1 was added to environment.rb" 4
                service httpd restart
            else
                report "AST_18 = 1 was not added to environment.rb" 1
                exit 1;
            fi
        fi
    fi
else
    report "Asterisk version is not 1.8. AST_18 variable is not needed" 0
fi
exit 0;
