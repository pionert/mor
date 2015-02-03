/*
*
*	MOR ActionLog AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2012
*
*	v1.0
*
* 	2012.07.06 v1.0 Initial release
*
*	This AGI updates DB ivr_action_log with the info from IVR
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
	char buff[100] = "";
	char str[100] = "";
	int i;

        time_t now;

	char script_time[30] = "";

        MYSQL_RES   *result;
        MYSQL_ROW   row;

	char *variable;
	char *value;

	// variables
	
	char ivr_msg[100] = "";
	char uniqueid[100] = "";



        if ( time(&now) != (time_t)(-1) ){
    	    struct tm *mytime = localtime(&now);
            if ( mytime ) {
                strftime(script_time, sizeof script_time, "%Y-%m-%d %T", mytime);
            }
        }



	AGITool_Init(&agi);


	sprintf(str, "Script executed at: %s", script_time);
	AGITool_verbose(&agi, &res, str, 0);

                                                                    

	// DB connection
	read_config();

//	sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
//	AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
			
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    AGITool_Destroy(&agi);
	    return 0;
	} else {
	    //AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}


	AGITool_get_variable2(&agi, &res, "UNIQUEID", uniqueid, sizeof(uniqueid));
	AGITool_get_variable2(&agi, &res, "IVR_TXT", ivr_msg, sizeof(ivr_msg));

	sprintf(str, "UniqueID: %s, IVR MSG: %s", uniqueid, ivr_msg);
	AGITool_verbose(&agi, &res, str, 0);

	
	/* put action into DB */
	sprintf(sqlcmd, "INSERT INTO ivr_action_logs (created_at, action_text, uniqueid) VALUES ('%s', '%s', '%s');", script_time, ivr_msg, uniqueid);
	mysql_query(&mysql, sqlcmd);



	AGITool_Destroy(&agi);
	mysql_close(&mysql);  

	return 0;
}


