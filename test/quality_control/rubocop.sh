#! /bin/bash

# Author:   Gilbertas Matusevicius
# Company:  Kolmisoft
# Year:     2014
# About:	This script tests the code using rubocop. The script does not update code. If need update manually with command: svn update /path/to/update

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
PATH_TO_CHECK="$1"
if [ ! -d "$PATH_TO_CHECK" ]; then
	PATH_TO_CHECK="/home/mor/app"
fi


RESULT_DIR="$2"
if [ "$RESULT_DIR" == "" ]; then
	RESULT_DIR="$PATH_TO_CHECK"
fi
mkdir -p "$RESULT_DIR/RUBOCOP"


REVISION="$3"

cp "/usr/src/mor/test/quality_control/.rubocop.yml" "$PATH_TO_CHECK/.rubocop.yml"




source "/usr/local/rvm/scripts/rvm" &> /dev/null

#----- FUNCTIONS ------------

rubocop_check()
{
	# 	Author:	Gilbertas Matusevicius
	#	Year:	2014
	#	About:	This function tests the code using rubocop
	
	
	PATH_TO_CHECK="$1"
        

        if [ `gem list | grep rubocop | wc -l` == "0" ]; then
            cd /home/mor
            gem install rubocop
            if [ "$?" != "0" ]; then report "rubocop gem install failed" 1; exit 1; fi
        fi
        
        local rubocop_tmp=`mktemp`
        rvm `cat /dev/shm/last_used_ruby_version` do rubocop -R  "$PATH_TO_CHECK" &> $rubocop_tmp
        
        RUBOCOP_WARNINGS=`grep -F 'offences detected' $rubocop_tmp  | awk -F, '{print $2}' | awk {'print $1'}`
        
        

        mv $rubocop_tmp $RESULT_DIR/RUBOCOP/$REVISION.txt
        chmod 755 $RESULT_DIR/RUBOCOP/$REVISION.txt
        
}

      




#--------MAIN -------------


# DETERMINING LAST USED RUBYVERSION
if [ -f /dev/shm/last_used_ruby_version ]; then
	LAST_USED_RUBY_VERSION=`cat /dev/shm/last_used_ruby_version`
else
	LAST_USED_RUBY_VERSION="ruby-1.9.3-p327@x4"
	echo "$LAST_USED_RUBY_VERSION" > /dev/shm/last_used_ruby_version
fi
#-----


rubocop_check $PATH_TO_CHECK

echo $RUBOCOP_WARNINGS

