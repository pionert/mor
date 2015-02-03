#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This function library is intended for work with MySQL only

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh



#----- FUNCTIONS ------------

mysql_check_if_grant_is_present()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function checks if given MySQL grant (permission) is present. If not - tries to add it. If fails - reports it to user.
	#
	# Arguments:
	#	$1	-	Grant name to check
	#
	# Returns:
	#	0	-	MySQL grant is not present
	#	1 	-	MySQL grant is present
	#   MYSQL_GRANT_IS_PRESENT - global variable.
	#
	# Depends on: mysql_connect_data_v2
	#
	# Example:
	#	mysql_check_add_grant "SUPER"	# will check SUPER grant

	local GRANT="$1"

	if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SHOW GRANTS FOR '$DB_NAME'@'$DB_HOST';" | grep $GRANT | wc -l` == 0 ]; then
		MYSQL_GRANT_IS_PRESENT="0"
	else
		MYSQL_GRANT_IS_PRESENT="1"
	fi

	return "$MYSQL_GRANT_IS_PRESENT"
}

mysql_check_add_grant()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function adds given MySQL grant (permission) if it is not present.
	#
	# Arguments:
	#	$1	-	Grant name to check
	#
	# Returns:
	#	0	-	grant is already present or successfully added
	#	1 	-	Failed to add MySQL grant, it is not present
	#	GRANT_IS_PRESENT
	# Depends on: mysql_connect_data_v2
	#
	# Example:
	#	mysql_check_add_grant "SUPER"	# will add SUPER grant

	local GRANT="$1"

	mysql_check_if_grant_is_present "$GRANT"

	if [ "$MYSQL_GRANT_IS_PRESENT" == "1" ]; then
		return 0
	else
	    /usr/bin/mysql -h "$DB_HOST" -u root "$DB_NAME" -e "grant $GRANT on *.* to '$DB_USERNAME'@'$DB_HOST'"
		mysql_check_if_grant_is_present "$GRANT"    
		if [ "$MYSQL_GRANT_IS_PRESENT" == "1" ]; then
			report "Successfully added $GRANT grant for MOR DB user" 4
			GRANT_IS_PRESENT="0"
			
		else
			report "Failed to add $GRANT grant for MOR DB user. Try to run this script directly in DB server: /usr/src/mor/test/scripts/mysql/mysql_grants.sh to fix this problem. If problem remains - contact Kolmisoft"  1
			GRANT_IS_PRESENT="1"
      	fi
      	return "$GRANT_IS_PRESENT"
  	fi
}
check_if_db_column_is_decimal()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks if DB column is decimal
    #
    #   Requires:
    #       This function requires that mysql_connect_data_v2 would be initialized in order all its connection variables would be made available.
    #
    #   Arguments:
    #       $1  - DB table
    #       $2  - table column to check
    #
    #   Returns:
    #       0   -   table column is not decimal
    #       1   -   table column is decimal

    DB_TABLE_TO_CHECK="$1"
    TABLE_COLUMN_TO_CHECK="$2"

    IS_DECIMAL=0 # column is not decimal
    if [ `/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" -e "DESC $DB_TABLE_TO_CHECK;" | grep "^$TABLE_COLUMN_TO_CHECK" |grep decimal | wc -l` == "1" ]; then
        IS_DECIMAL=1 # column is a decimal
    fi
    return $IS_DECIMAL
}
