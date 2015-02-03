#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script ensures that encoding is set in environment.rb to UTF-8

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_and_fix_encoding_variables()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks if encoding variables are present and set to UTF-8
    
    if [ `awk -F"#" '{print $1}' /home/mor/config/environment.rb | grep Encoding  | wc -l` != "2" ];  then
        # delete all Encoding variables if there are any and insert those 2 variables with utf8 after File.expand_path line
        sed '/Encoding/d' /home/mor/config/environment.rb |  sed '/File.expand_path/a\Encoding.default_internal = Encoding::UTF_8\nEncoding.default_external = Encoding::UTF_8' > /tmp/env_tmp
        mv /tmp/env_tmp /home/mor/config/environment.rb     
        service httpd restart &> /dev/null
        if [ `awk -F"#" '{print $1}' /home/mor/config/environment.rb | grep Encoding  | wc -l` == "2" ];  then
            return 4
        else
            return 1    
        fi
    else
        return 0        
    fi
   
}
#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 0
fi


mor_gui_current_version
mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS" 

if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
    check_and_fix_encoding_variables
    status="$?"
    if [ "$status" == "4" ]; then
        report "Added Encoding::UTF_8 variables to environment.rb" 4
    elif [ "$status" == "1" ]; then
        report "Failed to add variables:\n\nEncoding::UTF_8\nEncoding.default_external = Encoding::UTF_8 \n\nto environment.rb. Place these variables after line require File.expand_path('../application', __FILE__)" 1
    else
	report "Encodings are correctly set to UTF-8 in environment.rb" 0
    fi
#else
    #report "MOR version to old"
fi
