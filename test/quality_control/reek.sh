#! /bin/bash

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script tests the code using reek. The script does not update code. If need update manually with command: svn update /path/to/update

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
mkdir -p "$RESULT_DIR/REEK"


REVISION="$3"
REEK_CONFIG_FILE="/usr/src/mor/test/quality_control/defaults.reek"


source "/usr/local/rvm/scripts/rvm" &> /dev/null

#----- FUNCTIONS ------------

reek_for_execution_expired_file()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#	About:	This function checks again files which timeout
	#
	#	Arguments:
	#		$1 	-	log file to scan
	#
	#	Returns:
	#		COUNT - global var which holds total count of warnings  per file

	local log_file="$1"
        local TMP_COUNT
        
	while read EXPIRED_FILE; do
            
		local file=$(echo $EXPIRED_FILE | awk -F ":" '{print $1}')
	
		TMP_COUNT=$(reek -c $REEK_CONFIG_FILE $file | tail -n +1 | head -n 1 | awk -F'--' '{print $NF}' | awk '{print $1}')
		
		COUNT=$(($COUNT+$TMP_COUNT));
                
	done < <(grep -F "Timeout::Error: execution expired" $log_file)

}


reek_check()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#	About:	This function tests the code using reek
	 

            
	PATH_TO_CHECK="$1"
        

        if [ `gem list | grep reek | wc -l` == "0" ]; then
            cd /home/mor
            gem install reek
            if [ "$?" != "0" ]; then report "Reek gem install failed" 1; exit 1; fi
        fi

        local reek_tmp=`mktemp`
        rvm `cat /dev/shm/last_used_ruby_version` do reek -c $REEK_CONFIG_FILE "$PATH_TO_CHECK" &> $reek_tmp

        REEK_WARNINGS=`grep -F 'total warnings' $reek_tmp  | awk '{print $1}'`
        
        reek_for_execution_expired_file $reek_tmp
        
        REEK_WARNINGS=$((REEK_WARNINGS+COUNT))
        mv $reek_tmp $RESULT_DIR/REEK/$REVISION.txt
        chmod 755 $RESULT_DIR/REEK/$REVISION.txt
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

reek_check $PATH_TO_CHECK

echo $REEK_WARNINGS
