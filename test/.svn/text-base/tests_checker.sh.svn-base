#! /bin/sh
# Author: Mindaugas Mardosas
# Year:   2012
# About:  This script checks for bad written tests

# Arguments:
#   $1 - dir to check for slow/bad tests

. /usr/src/mor/test/framework/bash_functions.sh

#---- Cleanup
rm -rf  /tmp/tests_with_wait_after_open /tmp/tests_with_wait_without_ajax

#---- Tests


CHECK_DIR="$1"
find $CHECK_DIR -name "*.case" | sort | while read testas;  do
    temp=`mktemp`
    
    
    #----- Replace all verifies ----
    NUMBER_OF_VERIFIES=`grep verify $testas | wc -l`
    if [ "$NUMBER_OF_VERIFIES" -gt "0" ]; then
        report "verifyXXX commands found in test $testas, fixing" 3
        sed -e 's/verify/assert/g' $testas > $temp
        mv $temp $testas
    fi
    
    #----- Check if there are tests with wait commands ----
    # http://doc.kolmisoft.com/display/kolmisoft/Testing+Speedup
    if [ `grep -A 5 open $testas | grep wait | wc -l` -gt 0 ]; then
        echo "Test: $testas has wait commands immeadiately after open command, written this test path to log /tmp/tests_with_wait_after_open"
        echo "$testas" >> /tmp/tests_with_wait_after_open
    fi
    
        #-------------------------Test with wait commands without approved AJAX for that page-----------------------------
    if [ `sed "/#ajax/,/open/d" $testas | grep wait | wc -l` -gt 0 ]; then
        echo "Wait commands without Ajax: $testas"
        echo "$testas" >> /tmp/tests_with_wait_without_ajax
    fi
    rm -rf $temp
done

