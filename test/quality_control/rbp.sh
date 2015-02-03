#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script tests the code using Ruby Best Practices guide. This script will not update your DIR. So if you want to test latest code - update it manualy using command svn update /path/to/dir

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
PATH_TO_CHECK="$1"
if [ ! -d "$PATH_TO_CHECK" ]; then
	PATH_TO_CHECK="/home/mor/app"
fi


SILENT="$2"

MOVE_RESULTS_TO_FOLDER="$3"

REVISION="$4"


if [ "$MOVE_RESULTS_TO_FOLDER" == "" ]; then
	MOVE_RESULTS_TO_FOLDER="$PATH_TO_CHECK"
fi

mkdir -p "$MOVE_RESULTS_TO_FOLDER/RBP"
mkdir -p "$PATH_TO_CHECK/config/"

cp "/usr/src/mor/test/quality_control/rails_best_practices.yml" "$PATH_TO_CHECK/config/rails_best_practices.yml"

source "/usr/local/rvm/scripts/rvm" &> /dev/null

#----- FUNCTIONS ------------
rbp_check()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#	About:	This function tests the code using Ruby Best Practices guide.
	
	PATH_TO_CHECK="$1"

	if [ ! -d "$PATH_TO_CHECK" ]; then
		report "$PATH_TO_CHECK doesn rails_best_practices_output exist. Exiting script" 1
		exit 1
	fi

	LAST_USED_RUBY_VERSION=`cat /dev/shm/last_used_ruby_version`

    if [ `rvm $LAST_USED_RUBY_VERSION do gem list | grep rails_best_practices | wc -l` == "0" ]; then
    	cd /home/mor
        rvm `cat /dev/shm/last_used_ruby_version` do gem install rails_best_practices
        if [ "$?" != "0" ]; then report "rails_best_practices gem install failed" 1; exit 1; fi
    fi

    cd $PATH_TO_CHECK

    local rbp_tmp=`mktemp`
    rvm `cat /dev/shm/last_used_ruby_version` do rails_best_practices -f html . &> /dev/null
    
    if [ ! -f "$PATH_TO_CHECK/rails_best_practices_output.html" ]; then
		report "RBP failed to genereate result file - maybe try it on a smaller directory???" 3
		exit 1
	fi

	RBP_WARNINGS=`grep "Found [0-9]* warnings." $PATH_TO_CHECK/rails_best_practices_output.html | awk '{print $2}'`	



	mv $PATH_TO_CHECK/rails_best_practices_output.html "$MOVE_RESULTS_TO_FOLDER"/RBP/"$REVISION".html
}

#--------MAIN -------------
# DETERMINING LAST USED RUBYVERSION
if [ -f /dev/shm/last_used_ruby_version ]; then
	LAST_USED_RUBY_VERSION=`cat /dev/shm/last_used_ruby_version`
else
	LAST_USED_RUBY_VERSION="ruby-1.9.3-p327@x4"
	echo "$LAST_USED_RUBY_VERSION" > /dev/shm/last_used_ruby_version
fi

rbp_check "$PATH_TO_CHECK"

if [ "$SILENT" == "SILENT" ]; then
	echo "$RBP_WARNINGS"
else
	echo "Code smells found: $RBP_WARNINGS"
fi