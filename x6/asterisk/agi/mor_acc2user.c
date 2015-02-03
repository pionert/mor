/*
*
*	MOR Acc2User AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2008
*
*	v0.1.1
*
* 	2008.06.09 v0.1.1 Use of mor_agi_functions
*
*	This AGI takes accountcode of the caller and returns user details to the dialplan (such as extension)
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "mor_agi_functions.c"




/*	Main function	*/

int main(int argc, char *argv[])
{
	char buff[100];
	char str[100];
	int i;

	time_t now;

        MYSQL_RES   *result;
        MYSQL_ROW   row;

	char *variable;
	char *value;

	// variables
	
	int accountcode;
	char extension[50];

	// initial values
	strcpy(extension, "");




//	strcpy(datetime,"");

	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR Acc2User AGI script started.", 0);


	// DB connection
	read_config();

//	sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
//	AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
			
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    AGITool_Destroy(&agi);
	    return 0;
	} else {
	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}


	accountcode = atoi(AGITool_ListGetVal(agi.agi_vars, "agi_accountcode"));

	sprintf(str, "Accountcode: %i", accountcode);
	AGITool_verbose(&agi, &res, str, 0);


	// ------- get user details -----
	
	sprintf(sqlcmd, "SELECT devices.extension FROM devices WHERE devices.id = '%i';", accountcode);
	
        if (mysql_query(&mysql,sqlcmd)) {    
    	    // error
            //res = -1;
        } else {
        // query succeeded, process any data returned by it
    	    result = mysql_store_result(&mysql);
    	    if (result) {
    	    // there are rows
        	//i = 0;
                while ((row = mysql_fetch_row(result))) {	
                    if (row[0]) strcpy(extension, row[0]); 
            	}
        	mysql_free_result(result);
            } 
        }

    	AGITool_set_variable(&agi, &res, "BLA", extension);

	sprintf(str, "Extension: %s", extension);
	AGITool_verbose(&agi, &res, str, 0);


//	strcpy(variable, "MOR_DEVICE_EXT");
	//strcpy(value, extension);
	
//	sprintf(value, "%s", extension);
	
    	AGITool_set_variable(&agi, &res, "MOR_EXT", extension);
	
	

	AGITool_verbose(&agi, &res, "MOR Acc2User AGI script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);
	mysql_close(&mysql);  

	return 0;
}


/*	Functions	*/






