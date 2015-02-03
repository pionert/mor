#! /bin/bash
#===== README ====
# MOR installation must be upgraded to the most recent version
# This script upgrades mor GUI only with a command specified by GUI_UPGRADE_CMD  variable
# selenium-server must be running
# start selenium server with command:
# 		./mor_test_run.sh -s
#
#==============

. /usr/local/mor/test_environment/mor_test.cfg



if [ "$MODE" == "0" ]; then
	E_MAIL_RECIPIENTS="$TESTER_EMAIL" #separate each address with a space
elif [ "$MODE" == "1" ]; then
	E_MAIL_RECIPIENTS="serveriu.pranesimai@gmail.com aisteaisteb@gmail.com tankiaitaskuota@gmail.com kristinak.kolmisoft@gmail.com" #separate each address with a space
#	E_MAIL_RECIPIENTS="mkezys@gmail.com" #separate each address with a space
else
	echo "Unknown error when selecting MODE"
fi


#=======OPTIONS========
: ${dbg:="1"}	# dbg= {0 - off, 1 - on }  for debuging purposes
#============FUNCTIONS====================
start_selenium_server()
{
    running=`ps aux | grep -m 1 selenium-server.jar | awk '{ print $NF}'`
    if [ "$running" == "-singleWindow" ]; then
        echo "Selenium server is already running";
    else
        echo "Starting selenium server"
        DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -singleWindow >> /var/log/mor/selenium_server.log &
    fi
}
start_selenium_server
clean_logs()
{
    rm -rf /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
    touch /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
    chmod 777 /tmp/mor_debug.txt /tmp/mor_crash.log /home/mor/log/production.log /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mor/selenium_server.log #/var/log/mor/test_system
}


restart_services()
{
    #selenium   
    killall -9 java
    start_selenium_server;
    #-------
}
#--- git-------


git_check_and_install()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func installs git if it is not present
    if [ ! -f /usr/bin/git ]; then
        cd /usr/src/
        wget -c http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm
        rpm -Uvh epel-release-*
        yum check-update
        yum -y install git
    fi
}

gem_rest_client_check_and_install()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func installs rest-client gem if it is not present
    gem list | grep rest &> /dev/null
    if [ "$?" != "0" ]; then
        gem install rest-client
        if [ "$?" != "0" ]; then
            echo "FAILED TO INSTALL GEM: rest-client";
            exit 1;
        fi
    fi
}

checkout_brain_script()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This func downloads latest Kolmisoft TEST SYSTEM v2 brain scripts from brain git repo
    git_check_and_install
    rm -rf /usr/src/brain-scripts
    cd /usr/src
    git clone git://$GIT_REPO_ADDRESS/brain-scripts.git &
}

#git_check_and_install
#gem_rest_client_check_and_install
#checkout_brain_script


#---- /git-----

#------------------------------------------
prepare_db(){

	# recreate ramdisk
	cd /usr/local/mor
	./rebuild_mysql_ram.sh > /var/log/mor/rebuild_mysql_ram.log 2>&1

	cd /usr/src/mor/db/0.8/
	./make_new_db.sh nobk
	mysql mor < /home/mor/selenium/mor_0.8_testdb.sql;

        cd /usr/src/mor/db/9/
        ./import_changes.sh


        cd /usr/src/mor/db/10/
        ./import_changes.sh

        cd /usr/src/mor/db/trunk/
        ./import_changes.sh

#	echo "Importing test mor database from $PATH_TO_DATABASE_SQL";
#	mysql mor < $PATH_TO_DATABASE_SQL;

	mysql mor < /home/mor/selenium/mor_trunk_testdb.sql

	echo "Exporting prepared db to ramdisk"
	#rm -fr /home/ramdisk/mor.sql
	mysqldump -h localhost -u mor -pmor mor > /home/ramdisk/mor.sql

}


#------------------------------------------
import_db(){

#	cd /usr/src/mor/db/0.8/
#	./make_new_db.sh nobk

#	echo "Importing test mor database from $PATH_TO_DATABASE_SQL";
#	mysql mor < $PATH_TO_DATABASE_SQL;

	echo "Importing test mor database from /home/ramdisk/mor.sql";
	mysql mor < /home/ramdisk/mor.sql

}


#------------------------------------------
#------------------------------------------
dir_exists()
{
   if [ -d "$1" ];
			then
					[ $dbg == 1 ] && echo "$1 is dir";
					return 0;
      else return 1;
   fi
}
#-------------------------------------------
_mor_time()
{
	mor_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
}
#--------------------------------------------
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
run_all_rb()
{
		echo "1 paduotas kint: $1"
		delete_all_rb;
                
                rm -rf /tmp/mor_session.log /tmp/session.log.tar.gz
                touch /tmp/mor_session.log
		chmod 777 /tmp/mor_session.log
                
                
                convert_html_cases_to_rb "$1";

		echo -e "REVISION: $CURRENT_REVISION\nLAST AUTHOR: $LAST_AUTHOR">>$report

		find $TEST_DIR -name "*.rb" | sort | while read testas
		do
			dir_exists testas; #checking whether we have path to dir or file
			if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..'
	                skip_failed_test

			import_db; #dropping and importing a fresh database
			
            # cleanup
		    rm -rf /home/mor/public/ad_sounds/*.wav
            # cleaning test IVR files
            find /home/mor/public/ivr_voices/ -name "*test*" | xargs rm -rf
            #-----

			echo "Proceeding test: $testas"
			TMP_FILE=`mktemp`
    		ruby -rubygems $testas  | tee -a $report $TMP_FILE #logging the report to file   #| egrep "failures|Loaded"

			# memory
			free -m

			killall -9 dispatch.fcgi

			free -m


            grep "Error:\|Failure:" $TMP_FILE &> /dev/null
            if [ "$?" == "0" ]; then
                STATUS_v2="FAILED";
            else
                STATUS_v2="OK";
            fi

            #rm -rf $TMP_FILE    #house cleaning

            if [ -f /usr/src/brain-scripts/reporter.rb ]; then
                RELATVE_PATH_TO_TEST=`echo $testas | sed 's/\/home\/mor\/selenium\/tests\///'`
                #ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2

                local counter=0;


        	echo "Reporting to BRAIN..."

                while [ "$counter" != "5" ]; do
                
                
                    counter=$(($counter+1))
                    local temp=`mktemp`
                    echo "ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2" >> /tmp/reporter.log

                    if [ "$STATUS_v2" == "OK" ]; then
                        local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log` 
                        # "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_system_log /var/log/mor/test_system" "test_log $TMP_FILE" | tee -a $temp`
                    else
                        local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST $STATUS_v2 "my_debug /tmp/mor_debug.txt" "crash_log /tmp/mor_crash.log" "production_log /home/mor/log/production.log" "access_log /var/log/httpd/access_log" "error_log  /var/log/httpd/error_log" "selenium_server_log /var/log/mor/selenium_server.log" "test_log $TMP_FILE" | tee -a $temp /tmp/reporter.log`
                    fi


                    grep "RECEIVED" $temp &> /dev/null
                    if [ "$?" == "0" ]; then
                        rm -rf $temp $TMP_FILE
                        echo "Reporting complete!"
                        break;
                    fi
                    rm -rf $temp
                    #echo  $((3*$counter))
                    echo "Still reporting..."
                    sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
                done
            else
                echo "The reporter script was not found"
            fi

			echo -e "\n----\n" >> $report;
            clean_logs            
            #restart_services



		done

		echo -e "Report was generated...\nReport was saved to $report\n";

}
#=====================
delete_all_rb()
{
	echo "Deleting stale *.rb files";
		find $TEST_DIR -name "*.rb" | sort | while read testas
		do
			dir_exists testas; #checking whether we have path to dir or file
			if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..'

			rm -rf $testas
		done
		echo "All stale *rb files were deleted";
}
#=====================================================================
last_directory_in_the_path()
{
	last_dir_in_path=`pwd | awk -F\/ '{print $(NF)}'`;
}
#===========================MAIL======================================
send_report_by_email()	{
	if [ -f "$SEND_EMAIL" ]; then

		if [ "$STATUS" == "OK" ]; then
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][MOR TESTS $SERVER_NAME $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS     `cat $report`" -a /tmp/session.log.tar.gz  $EMAIL_SEND_OPTIONS > /tmp/mor_temp

		elif [ "$STATUS" == "FAILED" ]; then
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[$STATUS][MOR TESTS $SERVER_NAME $MOR_VERSION_YOU_ARE_TESTING] $CURRENT_REVISION $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: $STATUS `cat $report`" -a  /tmp/session.log.tar.gz -a $MOR_CRASH_LOG $EMAIL_SEND_OPTIONS > /tmp/mor_temp
		fi

		else echo "$SEND_EMAIL NOT FOUND!";
	fi

	if [ $? == 0 ]; then echo "Email was sent"; fi
}
#=====================================================================
skip_failed_test()
{   
    #   Author: Mindaugas Mardosas
    #   About: This function checks if this test was converted successfully - if not - forces to skip the test (problem was already reported)
    
    grep "$testas" /tmp/failed_conversions   &> /dev/null
    if [ "$?" == "0" ]; then
        echo "$testas was not converted successfully, skipping"
        continue;
    fi
}
convert_html_cases_to_rb()
{

	echo "Converting files which starts with: $TESTS_STARTS_WITH"

	find $TEST_DIR -name "*.case" | sort | while read testas
		do

			TEST_DIR_LENGTH=${#TEST_DIR}+1
			TEST_FIRST_LETTER=${testas:$TEST_DIR_LENGTH:1}
			POSITION_IN_ARRAY=`expr index "$TESTS_STARTS_WITH" $TEST_FIRST_LETTER`

			if [ $POSITION_IN_ARRAY != "0" ] ; then

			    dir_exists testas; #checking whether we have path to dir or file
			    if [ $? == 0 ]; then continue; fi; #let's do another cicle, nothing to do with dir..'
			    echo "Converting test: $testas"
                #local TEMP=`/bin/mktemp`
			    ruby /home/mor/selenium/converter/converter.rb -h "http://$1" $testas &> /tmp/test_convert_error

                grep "flunk\|converter.rb\|syntax error" /tmp/test_convert_error &> /dev/null

                if [ "$?" == "0" ]; then    #error was found!
                    #===report to brain
                    if [ -f /usr/src/brain-scripts/reporter.rb ]; then
                        RELATVE_PATH_TO_TEST=`echo $testas | sed 's/\/home\/mor\/selenium\/tests\///'`

                        local counter=0;
                        while [ "$counter" != "5" ]; do
                            counter=$(($counter+1))
                            local temp=`mktemp`

                            local result=`ruby /usr/src/brain-scripts/reporter.rb $MOR_VERSION_YOU_ARE_TESTING $CURRENT_REVISION $RELATVE_PATH_TO_TEST "FAILED" "test_log /tmp/test_convert_error" | tee -a $temp /tmp/reporter.log`

                            grep "RECEIVED" $temp &> /dev/null
                            if [ "$?" == "0" ]; then
                                rm -rf $temp $TMP_FILE
                                break;
                            fi

                            rm -rf $temp
                            sleep $((3*$counter))   #will wait incrementally: 0, 3, 6, 12, 15 seconds..
                        done
                    else
                        echo "The reporter script was not found"
                    fi
                    echo "$testas" >> /tmp/failed_conversions
                fi
                #======

                rm -rf /tmp/test_convert_error    # cleanup
                #================================
			else
			    echo "Skipping file: $testas"
			fi

		done
		#test_if_all_tests_were_converted_successfully
}
#====================================================================
is_another_test_still_running()
{
	if [ -f "$TEST_RUNNING_LOCK" ]; then
		echo "$mor_time Another test is already running, exiting";
		exit 0;
	fi
}
#======================================
test_if_all_tests_were_converted_successfully(){
	RB_FILES=`find $TEST_DIR -name "*.rb" | wc -l`;
	CASE_FILES=`find $TEST_DIR -name "*.case" | wc -l`;

	if [ $RB_FILES -ne $CASE_FILES ];
		then
			echo "Converting tests failed, stopping the script";
			$SEND_EMAIL -f mor_tests@kolmisoft.com -t $E_MAIL_RECIPIENTS -u "[FAILED][MOR TESTS $MOR_VERSION_YOU_ARE_TESTING] $mor_time" -m "REVISION: $CURRENT_REVISION  LAST AUTHOR: $LAST_AUTHOR  STATUS: FAILED TO CONVERT THE TESTS" $EMAIL_SEND_OPTIONS > /tmp/mor_temp
			rm -rf "$TEST_RUNNING_LOCK"
			exit 1;
		else
			echo "Successfully converted the tests";
	fi

}

test_beta_tests(){
	rm -rf $BETA_TESTS_DIR/*.rb
	find $BETA_TESTS_DIR -name "*.case" | sort | while read testas
		do
				echo "Converting beta test: $testas"

				ruby /home/mor/selenium/converter/converter.rb -h "http://localhost" $testas

		done

	find $BETA_TESTS_DIR -name "*.rb" | sort | while read testas
		do
			if [ ! -f "$testas"_report ]; then
				> /tmp/selenium_debugas

				for i in $(seq 1 $TEST_BETA_TESTS)
					do
						echo "Launching test: $i"
						echo "Importing the database" >> /tmp/selenium_debugas;
						/usr/local/mor/test_environment/mor_test_run.sh -i
						echo "Launched the ruby test" >> /tmp/selenium_debugas;
						ruby "$testas" >> /tmp/selenium_debugas;

						#====checking for errors or failures
						grep "Error:" /tmp/selenium_debugas
						if [ "$?" == "0" ]; then
							STATUS="FAILED";
							break;  #exiting the loop, because an error was found
							else STATUS="OK";
						fi

						grep "Failure:" $report
						if [ "$?" == "0" ]; then
							STATUS="FAILED";
							break;  #exiting the loop, because an error was found
						fi
						#===================================
				done

				echo $STATUS >> /tmp/selenium_debugas
				echo $STATUS;
				cp /tmp/selenium_debugas "$testas"_report
			fi
		done
}


#====================================MAIN============================
_mor_time;




if [ -z "$1" ];
	then
		echo -e "\n\n=========MOR TEST ENGINE CONTROLLER=======";
		echo "Arguments:";
		echo -e "\t-a \tUpgrades GUI, resets a database, runs all tests, sends the report by email.";
		echo -e "\t-i \tGives you a fresh database, by importing $PATH_TO_DATABASE_SQL";
		echo -e "\t-d \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS";
		echo -e "\t-r \tNOT USED ANYMORE - Dumps a current database state to $DIR_TO_STORE_DATABASE_DUMPS and replaces the default database file $PATH_TO_DATABASE_SQL \n";
		echo -e "\t-s \tStart a Selenium RC server\n";

	elif [ "$1" == "-a" ]; then  #do all tasks

        rm -rf /tmp/failed_conversions

		URL="$2" #saving second parameter before it gets overwritten by set command

		is_another_test_still_running #if another instance is running - script will terminate.

		touch "$TEST_RUNNING_LOCK"  #creating the lock


		svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
		chmod +x /usr/bin/mor
		chmod +x /home/mor/selenium/scripts/test_run.sh

		rm -rf /tmp/mor_crash.log
		echo -e "\n------\n" >> /var/log/mor/selenium_server.log
		touch /tmp/mor_crash.log
		chmod 777 /tmp/mor_crash.log

		[ $dbg == 1 ] && echo -e "\n$mor_time";

		if [ "$MODE" == "1" ]; then	#$GUI_UPGRADE_CMD;
		    cd /home/mor
		    ./gui_upgrade_light_4test.sh
		fi #upgrading GUI



		set $(cd /home/mor/ && svn info | grep "Last Changed Rev") &> /dev/null
		CURRENT_REVISION="$4";  #newest

		set $(cat "$LAST_REVISION_FILE" | tail -n 1 ) &> /dev/null
#				set $(cat /usr/local/mor/test_environment/last_revision | tail -n 1 ) &> /dev/null

		LAST_REVISION=$2;

		set $(cd /home/mor/ && svn info | grep "Last Changed Author:");
		LAST_AUTHOR="$4"

		[ $dbg == 1 ] && echo "Current revision: $CURRENT_REVISION";
		[ $dbg == 1 ] && echo "Last revision: $LAST_REVISION";
		[ $dbg == 1 ] && echo "Last author: $LAST_AUTHOR";


		if [ "$CURRENT_REVISION" != "$LAST_REVISION" ] || [ "$MODE" == "0" ]; then
			[ $dbg == 1 ] && echo "Versions didn't matched, running the tests"
			/etc/init.d/httpd restart
			report="$DIR_FOR_LOG_FILES/$LOGFILE_NAME.$mor_time.txt"
			prepare_db;
            echo "House cleaning...."
            # turn off swap
            sysctl -w vm.swappiness=0
            echo 0 >/proc/sys/vm/swappiness
            # kill some nonsense
            killall -9 wnck-applet
            # clean mem cache
            sync; echo 3 > /proc/sys/vm/drop_caches

            echo "Initiating apache/compiling ror..."
            # initiate apache/compile ror
            wget 127.0.0.1/billing > /dev/null
		    run_all_rb "$URL";
		    # house cleaning
		    # apache
		    killall -9 dispatch.fcgi
		    ipcs -s | grep apache | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
		    #clean mem cache
		    sync; echo 3 > /proc/sys/vm/drop_caches

            rm -fr /tmp/CGI*
            rm -fr /tmp/file*
            rm -fr /tmp/_sox*
            rm -fr /tmp/tmp.*
            rm -fr /tmp/*.json.part
            rm -fr /tmp/*.pdf.part


		    #	killall firefox  #this is needed because we started to use selenium server option "-browserSessionReuse", so selenium now doesn't kill the browser.

		    finish_time=`date +%Y\-%0m\-%0d\_%0k\:%0M\:%0S`;
		    echo "Started: $mor_time      Finished: $finish_time"
		    echo "Started:  $mor_time" >> $report
		    echo "Finished: $finish_time" >> $report
                    echo "Processed tests starting with: $TESTS_STARTS_WITH" >> $report

		    #====checking for errors or failures
		    grep "Error:" $report
		    if [ "$?" == "0" ]; then
			    STATUS="FAILED";
			    else STATUS="OK";
		    fi

		    grep "Failure:" $report
		    if [ "$?" == "0" ]; then STATUS="FAILED"; fi
		    #===================================

		    [ $dbg == 1 ] && echo  "$STATUS";
                    
                    
                    #----- put session log to email
                    if [ -f /tmp/mor_session.log ]; then
                        echo -e "\n\n=========== SESSION LOG ===================" >> $report
                        tar czf /tmp/session.log.tar.gz /tmp/mor_session.log
                        
                        
                        
                    else
                        echo -e "\n\n\nSession log /tmp/mor_session.log not found" >> $report
                    fi
                    #-----
                    
		    send_report_by_email;
		    echo -e "$mor_time\t$CURRENT_REVISION\t\t$LAST_AUTHOR\t$STATUS" >> $LAST_REVISION_FILE
		fi

		rm -rf "$TEST_RUNNING_LOCK";
		if [ "$?" != "0" ]; then echo "$mor_time Failed to delete $TEST_RUNNING_LOCK lock"; fi;

	elif [ "$1" == "-l" ]; then
		cd /home/mor
		./gui_upgrade_light_4test.sh
		svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
		prepare_db;
		import_db; 	#import
		chmod +x /usr/bin/mor
		chmod +x /home/mor/selenium/scripts/mor_test_run.sh

	elif [ "$1" == "-i" ]; then
         svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
	    	import_db; 	#import
	elif [ "$1" == "-b" ]; then   #RUN BETA TESTS
				is_another_test_still_running #if another instance is running - script will terminate.
				touch "$TEST_RUNNING_LOCK"  #creating the lock
				test_beta_tests;
				rm -rf "$TEST_RUNNING_LOCK";
				if [ "$?" != "0" ]; then echo "$mor_time Failed to delete $TEST_RUNNING_LOCK lock"; fi;
	elif [ "$1" == "-d" ]; then   # prepare db
				prepare_db;
	elif [ "$1" == "-di" ]; then   # import db
				import_db;
	elif [ "$1" == "-s" ]; then
#			echo "Starting a Selenium RC server";

								#outdated
								# 2009.05.16 DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -singleWindow >> /var/log/mor/selenium_server.log &
#			DISPLAY=:0 /usr/local/mor/test_environment/jre1.6.0_13/bin/java -jar /usr/local/mor/test_environment/selenium-server.jar -singleWindow >> /var/log/mor/selenium_server.log &
			start_selenium_server;


fi

