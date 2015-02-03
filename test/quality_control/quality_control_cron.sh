#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script automatically checks code quality by revisions and generates statistics if the code is getting better or worse
#
# Arguments:
#	$1 - PATH TO check, for example /home/mor/app
#	$2 - PATH where to place final results file
# 
# Example:
#
#	*/1 * * * * root /bin/bash -l -x /usr/src/mor/test/quality_control/quality_control_cron.sh /var/www/html/quality.kolmisoft.com/x5/mor/app /var/www/html/quality.kolmisoft.com/x5  >> /var/www/html/quality.kolmisoft.com/x5/log

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh



#------VARIABLES-------------

PATH_TO_SVN_FOLDER="$1"
if [ ! -d "$PATH_TO_SVN_FOLDER/.svn" ]; then
	report "Please specify correct path to svn folder" 1
	exit 1
fi


FINAL_INTERMEDIATE_RESULT_DIR="$2"
if [ "$FINAL_INTERMEDIATE_RESULT_DIR" == "" ]; then
	FINAL_INTERMEDIATE_RESULT_DIR="$PATH_TO_SVN_FOLDER/code_quality_cron/FINAL_INTERMEDIATE_RESULT_DIR"
fi

mkdir -p $FINAL_INTERMEDIATE_RESULT_DIR


FINAL_INTERMEDIATE_RESULT_FILE="$FINAL_INTERMEDIATE_RESULT_DIR/FINAL.html"


TEST_LAST_REVISIONS=100 	# Define here how many last revision you want to keep checked


mkdir -p "$PATH_TO_SVN_FOLDER"/code_quality_cron

touch "$FINAL_INTERMEDIATE_RESULT_FILE"

LOCK_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/quality_lock"


LAST_DEFECTS_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/min_defects"

LAST_CHECKED_REVISION_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/last_checked_revision"


LAST_FOUND_BAD_PRACTICES_COUNT_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/bad_practices_count"


INTERMEDIATE_RESULT_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/intermediate_result"
if [ ! -f "$INTERMEDIATE_RESULT_FILE" ]; then
	echo -e "\n\n" > "$INTERMEDIATE_RESULT_FILE"
fi


LOG_FILE="$PATH_TO_SVN_FOLDER/code_quality_cron/log"
touch "$LOG_FILE"

RESULT_FILES="$PATH_TO_SVN_FOLDER/code_quality_cron/result_files"
mkdir -p RESULT_FILES

#---------------------------- FUNCTIONS ---------------------------------
svn_last_change_info()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks last SVN commit information


    LAST_SVN_CHANGE_REVISION=`svn info $PATH_TO_CHECK | grep "Last Changed Rev:" | awk '{print $NF}'`
    LAST_SVN_CHANGE_AUTHOR=`svn info $PATH_TO_CHECK | grep "Last Changed Author:" | awk '{print $NF}'`
    LAST_SVN_CHANGE_TIME=`svn info $PATH_TO_CHECK | grep "Last Changed Date:" | awk -F": " '{print $NF}' | awk '{print $1" "$2}'`
    MOR_VERSION=`svn info $PATH_TO_CHECK  | grep URL | awk -F"/" '{print $7}'`
    
    if [ "$MOR_VERSION" == "app" ]; then
        MOR_VERSION="m2"
    fi
}
get_color()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013	
	#
	# Arguments:
	#	$1 	-	check name
	#	$2 	-	new counted warnings for this version
	# Returns:
	#	MIN_DEFECT_COUNT
	#	COLOR = {"red", "green", "white"}	RED - now there are more errors. GREEN - now there are less errors. White - there is the same count of errors # For last check
	#	STATUS = {0 - Grey, 1 - Green, 2 - Red}	# for last check
	#
	#	Final results of all checks
	#
	#	FINAL_COLOR_STATUS = {0 - Grey, 1 - Green, 2 - Red}
	#	STATUS = {0 - Grey, 1 - Green, 2 - Red}

	local CHECK_NAME="$1"	# { "RBP", "REEK"}
	local NEW_COUNTED_WARNINGS="$2"


	echo "`date` Detecting color for $CHECK_NAME result" >> $LOG_FILE

	if [ ! -f "$LAST_DEFECTS_FILE"_"$CHECK_NAME" ]; then
		echo "$NEW_COUNTED_WARNINGS" > "$LAST_DEFECTS_FILE"_"$CHECK_NAME"	# initializing file with high value
	fi

	MIN_DEFECT_COUNT=`tail -n 1 "$LAST_DEFECTS_FILE"_"$CHECK_NAME"`

	if [ "$NEW_COUNTED_WARNINGS"  == "$MIN_DEFECT_COUNT" ]; then
		COLOR="#2A2A2A";	# Grey	
		STATUS=0
	elif [ "$NEW_COUNTED_WARNINGS"  -lt "$MIN_DEFECT_COUNT" ]; then		
		COLOR="#79AB4A";	# Green
		STATUS=1
	else
		COLOR="#CF3736";	# Red
		STATUS=2
	fi
 
	if [ "$STATUS" -gt "$FINAL_COLOR_STATUS" ]; then
		FINAL_COLOR_STATUS="$STATUS"
		FINAL_COLOR="$COLOR"
	fi
}

make_diff_file ()
{

#	Author:	Gilbertas Matusevicius
	#	Year:	2014
	#
	#	Arguments:
	#		$1 	-	comand name { "RUBOCOP", "REEK"}
	
	local CHECK_NAME="$1"	
	
	if [ $OLD_REVISION -eq "0" ]; then OLD_REVISION="$NEW_REVISION"; fi
	
	echo "`date` Calculating $CHECK_NAME diff between $OLD_REVISION and $NEW_REVISION" >> $LOG_FILE
	
	if [ "$CHECK_NAME" == "RUBOCOP" ]; then
	
		perl -pe 's/\.rb\:\d+\:\d+\://' "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt" > "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt_cleaned"
		perl -pe 's/\.rb\:\d+\:\d+\://' "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt" > "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt_cleaned"
	fi
	
	if [ "$CHECK_NAME" == "REEK" ]; then
		
		perl -pe 's/\[\d+.*?\]://' "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt" > "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt_cleaned"
		perl -pe 's/\[\d+.*?\]://' "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt" > "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt_cleaned"
	fi
	

	if [ ! -f /usr/bin/colordiff ]; then yum -y install colordiff; fi
	
	if [ ! -f /usr/local/bin/ansi2html.sh ]; then
		wget http://www.pixelbeat.org/scripts/ansi2html.sh -O /usr/local/bin/ansi2html.sh
		chmod +x /usr/local/bin/ansi2html.sh
	fi
	
	colordiff -u "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt_cleaned" "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt_cleaned" | /usr/local/bin/ansi2html.sh > "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.html"
	
	
	rm -f "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$NEW_REVISION.txt_cleaned"
	rm -f "$FINAL_INTERMEDIATE_RESULT_DIR/$CHECK_NAME/$OLD_REVISION.txt_cleaned"
}



calculate_diff()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013	
	# About:	This method is responsible for counting the difference between last and new defect count
	# 
	# Returns:
	#	WARNINGS_DIFF - 


	local CHECK_NAME="$1"	# { "RBP", "REEK", etc...}
	local NEW_COUNTED_WARNINGS="$2"

	echo "`date` Calculating diff for $CHECK_NAME warnings" >> $LOG_FILE

	if [ ! -f /usr/bin/bc ]; then yum -y install bc; fi

	if [ ! -f "$LAST_DEFECTS_FILE"_"$CHECK_NAME" ]; then
		echo "$NEW_COUNTED_WARNINGS" > "$LAST_DEFECTS_FILE"_"$CHECK_NAME"	# initializing file with high value
	fi

	LAST_MIN_DEFECT_COUNT=`tail -n 1 "$LAST_DEFECTS_FILE"_"$CHECK_NAME"`
	
	WARNINGS_DIFF=`echo "$LAST_MIN_DEFECT_COUNT - $NEW_COUNTED_WARNINGS" | bc`
}

set_last_defects_result()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013

	local CHECK_NAME="$1"	# { "RBP", "REEK"}
	local LAST_DEFECT_COUNT="$2"

	echo "$LAST_DEFECT_COUNT" > "$LAST_DEFECTS_FILE"_"$CHECK_NAME"
}

get_last_checked_revision()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	#
	# Returns:
	#	LAST_REVISION

	if [ ! -f "$LAST_CHECKED_REVISION_FILE" ]; then
		LAST_CHECKED_REVISION="0"
		return 1
	fi

	export LAST_CHECKED_REVISION=`cat $LAST_CHECKED_REVISION_FILE`
}
set_last_checked_revision()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	#
	# Arguments:
	#	$1	-	LAST CHECKED REVISION NUMBER (IN DIGITS)

	LAST_CHECKED_REVISION="$1"
	echo "`date` Setting last SVN checked revision to $LAST_CHECKED_REVISION" >> $LOG_FILE
	echo "$LAST_CHECKED_REVISION" > $LAST_CHECKED_REVISION_FILE
}

check_if_code_check_is_needed()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013

	svn update $PATH_TO_SVN_FOLDER
	 

	CURRENT_FOLDER_REVISION=`svn info $PATH_TO_SVN_FOLDER | grep -F "Last Changed Rev:" | awk '{print $NF}'`

	if [ "$CURRENT_FOLDER_REVISION" == "$LAST_CHECKED_REVISION" ]; then
		report "The newest available revision is already tested, exiting the script" 3
		exit 0
	fi
}

insert_result()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#	About:	This function insert result at the beginning of the result file using the form of HTML form table tags

	RBP="$1"	# Ruby Best Practices score
	COLOR="$2"
	REVISION_TO_INSERT="$3"
	REEK="$4"
	REEK_DIFF="$5"
	RUBOCOP="$6"
	RUBOCOP_DIFF="$7"

	echo "`date` Inserting result into intermediate result file $INTERMEDIATE_RESULT_FILE" >> $LOG_FILE

	svn_last_change_info
	
	sed -i "1s/^/<tr style=\"background-color: $COLOR;\"><td>$LAST_SVN_CHANGE_TIME<\/td><td><a href=\"http:\/\/trac.kolmisoft.com\/trac\/changeset\/$REVISION_TO_INSERT\">$REVISION_TO_INSERT<\/a><\/td><td>$LAST_SVN_CHANGE_AUTHOR<\/td><td><a href=\"RBP\/$REVISION_TO_INSERT.html\">$RBP<\/a><\/td><td><a href=\"REEK\/$REVISION_TO_INSERT.txt\">$REEK<\/a>\&nbsp\;<a href=\"REEK\/$REVISION_TO_INSERT.html\">($REEK_DIFF)<\/a><\/td><td><a href=\"RUBOCOP\/$REVISION_TO_INSERT.txt\">$RUBOCOP<\/a>\&nbsp\;<a href=\"RUBOCOP\/$REVISION_TO_INSERT.html\">($RUBOCOP_DIFF)<\/a><\/td><\/tr>\n/" "$INTERMEDIATE_RESULT_FILE"  
}

generate_result_table()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#	About:	This function generates final result file
	#
	#	Arguments:
	#		$1 	-	show this much latest results

	SHOW_RESULTS="$1"

	echo "`date` Generating final result table of $TEST_LAST_REVISIONS results" >> $LOG_FILE

	echo "<html><head> 
<style type=\"text/css\">
#table-2 {
  font-family: Verdana,Helvetica,Arial;
  border: 0px;
  background-color: #1F1F1F;
  color: #D4D4D4;
  width: 100%;
  border-collapse:collapse;
}
#table-2 a{
  color:#D4D4D4;
  text-decoration:none;
}
#table-2 td, #table-2 th {
  padding: 5px;
  border: 0px;
}
#table-2 thead {
  padding: .2em 0 .2em .5em;
  text-align: left;
  background-color: #C8C8C8;
  border: 0px;
}
#table-2 th {
  font-size: 14px;
  font-style: normal;
  font-weight: bold;
  text-align: left;
  border: 0px;
}
#table-2 td {
  font-size: 12px;
  border: 0px;
}

</style>

<script type=\"text/JavaScript\">

function timedRefresh(timeoutPeriod) {
	setTimeout(\"location.reload(true);\",timeoutPeriod);
}
</script>

	</head>
	<body bgcolor=\"#000\" onload=\"JavaScript:timedRefresh(10000);\">
	<div style=\"font-weight:bold;color:#D4D4D4;font-family:Verdana,Helvetica,Arial;font-size:20px;\">$MOR_VERSION</div>
	<table id=\"table-2\" border=\"0\"><tr><th>Date</th><th>Revision</th><th>Author</th><th><a href=\"http://blog.rubybestpractices.com/\">RBP</a></th><th><a href=\"https://github.com/troessner/reek/\">REEK</a></th><th><a href=\"https://github.com/bbatsov/rubocop\">RUBOCOP</a></th></tr>" > $FINAL_INTERMEDIATE_RESULT_FILE
	head -n $SHOW_RESULTS $INTERMEDIATE_RESULT_FILE >> $FINAL_INTERMEDIATE_RESULT_FILE
	echo "</table></body></html>" >> $FINAL_INTERMEDIATE_RESULT_FILE
}

check_the_quality()
{
	#	Author:	Mindaugas Mardosas
	#	Year:	2013
	#
	#	Arguments:
	#		$1 	-	PATH to check, usually: /home/mor/app
	#		$2 	-	Desired revision to check

    PATH_TO_CHECK="$1"
    REVISION_TO_CHECK="$2"
    
    local RBP_COLOR
    local RBP_COLOR_STATUS
    local REEK_COLOR
    local REEK_COLOR_STATUS
    local MAX_COLOR_STATUS=0
    local MAX_COLOR="#2A2A2A"

    cd $PATH_TO_CHECK
    svn update -r "$REVISION_TO_CHECK"

    #---- Put here all checks --------------

	echo "`date` Revision: $REVISION_TO_CHECK. Testing with RBP" >> $LOG_FILE
	RBP_WARNINGS=`/usr/src/mor/test/quality_control/rbp.sh "$PATH_TO_CHECK" "SILENT" "$FINAL_INTERMEDIATE_RESULT_DIR" "$REVISION_TO_CHECK"`

	#RBP_WARNINGS=`shuf -i 1-10 -n 1`	# For testing

	echo "`date` Revision: $REVISION_TO_CHECK. Testing with REEK" >> $LOG_FILE
	REEK_WARNINGS=`/usr/src/mor/test/quality_control/reek.sh "$PATH_TO_CHECK" "$FINAL_INTERMEDIATE_RESULT_DIR" "$REVISION_TO_CHECK"`
	#REEK_WARNINGS=`shuf -i 1-10 -n 1`	# For testing
	
	echo "`date` Revision: $REVISION_TO_CHECK. Testing with RUBOCOP" >> $LOG_FILE
	RUBOCOP_WARNINGS=`/usr/src/mor/test/quality_control/rubocop.sh "$PATH_TO_CHECK" "$FINAL_INTERMEDIATE_RESULT_DIR" "$REVISION_TO_CHECK"`
	#RUBOCOP_WARNINGS=`shuf -i 1-10 -n 1`

	# These are defined before all color checks
	FINAL_COLOR_STATUS=0
	FINAL_COLOR="#2A2A2A"
	
	MAX_COLOR_STATUS=0
	MAX_COLOR="#2A2A2A"
	#--------------------

	# ---Check here the color for all tests----
	
	get_color "RBP" "$RBP_WARNINGS"
	
	# --- Save RPB color info
	RBP_FINAL_COLOR="$FINAL_COLOR"
	RBP_FINAL_COLOR_STATUS="$FINAL_COLOR_STATUS"
	
	get_color "REEK" "$REEK_WARNINGS"
	
	REEK_FINAL_COLOR="$FINAL_COLOR"
	REEK_FINAL_COLOR_STATUS="$FINAL_COLOR_STATUS"
	
	get_color "RUBOCOP" "$RUBOCOP_WARNINGS"
	
	if [ "$RBP_COLOR_STATUS" -gt "$MAX_COLOR_STATUS" ]; then
	        MAX_COLOR="$RBP_COLOR"
	        MAX_COLOR_STATUS="$RBP_COLOR_STATUS"
	fi
	
	if [ "$REEK_COLOR_STATUS" -gt "$MAX_COLOR_STATUS" ]; then
	        MAX_COLOR="$REEK_COLOR"
	        MAX_COLOR_STATUS="$REEK_COLOR_STATUS"
	fi
	
	if [ "$MAX_COLOR_STATUS" -gt "$FINAL_COLOR_STATUS" ]; then
	        FINAL_COLOR="$MAX_COLOR"
	        FINAL_COLOR_STATUS="$MAX_COLOR_STATUS"
	fi
	
	
	

	
	
        

	# --- Calculate here diffs for values----

	calculate_diff "RBP" "$RBP_WARNINGS"
	RBP_FINAL_RESULT="$RBP_WARNINGS ($WARNINGS_DIFF)"

	calculate_diff "REEK" "$REEK_WARNINGS"
	REEK_FINAL_RESULT="$REEK_WARNINGS"
	REEK_DIFF="$WARNINGS_DIFF"
	
	make_diff_file "REEK"
	
        calculate_diff "RUBOCOP" "$RUBOCOP_WARNINGS"
	RUBOCOP_FINAL_RESULT="$RUBOCOP_WARNINGS"
	RUBOCOP_DIFF="$WARNINGS_DIFF"
	
	make_diff_file "RUBOCOP" 
	
	



	#--- Generating the results ---
	
	insert_result "$RBP_FINAL_RESULT" "$FINAL_COLOR" "$REVISION_TO_CHECK" "$REEK_FINAL_RESULT" "$REEK_DIFF" "$RUBOCOP_FINAL_RESULT" "$RUBOCOP_DIFF"

	generate_result_table "$TEST_LAST_REVISIONS" 

	#--- /Generating the results ---

	set_last_checked_revision "$REVISION_TO_CHECK"


	# For colors correct behaviour
	set_last_defects_result "RBP"	"$RBP_WARNINGS"
	set_last_defects_result "REEK"	"$REEK_WARNINGS"
	set_last_defects_result "RUBOCOP" "$RUBOCOP_WARNINGS"
	
}

#--------MAIN -------------


if [ -f "$LOCK_FILE" ]; then
	echo "`date` Testing is already started, exiting" >> $LOG_FILE
	report "`date` Testing is already started, exiting" 3
	exit 1;
fi


cd $PATH_TO_SVN_FOLDER
check_if_code_check_is_needed
temp=`mktemp`

touch $LOCK_FILE
report "Created lock: $LOCK_FILE" 3

svn log -l 20  "$PATH_TO_SVN_FOLDER" | grep ^r | awk -F"r" '{print $2}' | awk '{print $1}'| sort -n > $temp	# Getting 100 latest revisions sorted by ASC
exec < $temp
while read line; do
	get_last_checked_revision
	if [ "$line" -gt "$LAST_CHECKED_REVISION" ]; then
		NEW_REVISION="$line"
		OLD_REVISION="$LAST_CHECKED_REVISION"
		echo "`date` Starting NEW revision: $NEW_REVISION" >> $LOG_FILE
		
		check_the_quality "$PATH_TO_SVN_FOLDER" "$NEW_REVISION" "$OLD_REVISION"

		echo "=============REVISION \[$line\] FINISHED ===========================================" >> $LOG_FILE

		
	fi
done

cd $PATH_TO_SVN_FOLDER
rm -rf $temp 

report "Removing lock: $LOCK_FILE" 3
rm -rf $LOCK_FILE

