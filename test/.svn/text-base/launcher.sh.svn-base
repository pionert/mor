#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script launches various scripts from gui with admin permissions.
#
# Usage: /usr/src/mor/test/launcher.sh "command with all parameters"
#
# Returns:
#	0	-	success
#	>0	-	failure
# Prints:
#	0	-	success
#	>0	-	failure

SCRIPT_WITH_PARAMS="$*"

$SCRIPT_WITH_PARAMS
STATUS="$?"

echo "STATUS:$STATUS"

exit "$STATUS"