#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script tests Ruby code quality for common mistakes.
#
# Usage:    /usr/src/mor/test/code_quality_test.sh /path/to/mor/directory <--- (optional)
#
# Currently added tests for:
#  http://trac.kolmisoft.com/trac/ticket/7847

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
MOR_DIRECTORY="$1"
if [ "$MOR_DIRECTORY" == "" ]; then
    MOR_DIRECTORY="/home/mor"
fi

#----- FUNCTIONS ------------
html_safe()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    
    PATH_TO_GUI="$1"
    grep -r "\.html_safe" $PATH_TO_GUI | grep -v "\"\.html_safe\|'\.html_safe\|:html_safe\|\.svn\|to_s\.html_safe"
}

#--------MAIN -------------

report "Testing Ruby code for .htmlsafe method\n\n\n" 3
html_safe $MOR_DIRECTORY
 
 
 