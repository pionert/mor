/*
*
*	MOR Answer Mark AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2011-2012
*
*	v0.8

*	2012-10-23 v0.8 put answer time into local internal db for rare cases when it is not possible to pass it over channel variables
*	2012-10-23 v0.7 show master channel for debug
*	2012-10-22 v0.6 small 'just in case' addition for answer time
*	2012.09.06 v0.5 ast18 support, pdd
* 	2011.11.28 v0.4 bugfix to support mor 9/10
* 	2011.11.27 v0.3 Save legB Codec and PDD into Active Calls
* 	2011.03.12 v0.2 Bugfix to ringing calls not marked as Answered
* 	2011.01.07 v0.1 Initial release
*
*	This AGI updates DB activecalls table with Call answer time and sets MOR_ANSWER_TIME to the channel so MOR+ast18 could bill the call
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/timeb.h>

#include "mor_agi_functions.c"


/*	Main function	*/

int main(int argc, char *argv[])
{
	char buff[100] = "";
	char str[100] = "";
	int i;

        time_t now;

	char answer_time[30] = "";

        MYSQL_RES   *result;
        MYSQL_ROW   row;

	char *variable;
	char *value;

	// variables

	char uniqueid[100] = "";


	/* answer time in unix time with nanoseconds */
	struct timeb tp;
	char mili_time[100] = "";

	ftime(&tp);
	sprintf(mili_time, "%ld.%d", tp.time, tp.millitm);


        if ( time(&now) != (time_t)(-1) ){
    	    struct tm *mytime = localtime(&now);
            if ( mytime ) {
                strftime(answer_time, sizeof answer_time, "%Y-%m-%d %T", mytime);
            }
        }


	AGITool_Init(&agi);

	/* tell MOR answer time, send value to master's(caller's) channel, because here we are at the receiver's channel */
	AGITool_set_variable(&agi, &res, "MASTER_CHANNEL(MOR_ANSWER_TIME)", mili_time);

	// also send to the current channel - just in case
	AGITool_set_variable(&agi, &res, "MOR_ANSWER_TIME", mili_time);

	// get uniqueid
	AGITool_get_variable2(&agi, &res, "ARG1", buff, sizeof(buff));
	strcpy(uniqueid, buff);


	// also put it into internal Asterisk DB
	AGITool_database_put(&agi, &res, "MOR_ANSWER_TIME", uniqueid, mili_time);

	char master_channel[200] = "";
	AGITool_get_variable2(&agi, &res, "MASTER_CHANNEL(CHANNEL(name))", master_channel, sizeof(master_channel));


        sprintf(str, "Channel: %s, Master Channel: %s", AGITool_ListGetVal(agi.agi_vars, "agi_channel"), master_channel);
        AGITool_verbose(&agi, &res, str, 0);


	sprintf(str, "Call Answered at %s, mili-unix time: %s", answer_time, mili_time);
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



	//sprintf(str, "UniqueID: %s", uniqueid);
	//AGITool_verbose(&agi, &res, str, 0);


	/* channel details */
	char codec[1024] = "";
	//char client[1024] = "";
	AGITool_get_variable2(&agi, &res, "CHANNEL(audionativeformat)", codec, sizeof(codec));
	//AGITool_get_variable2(&agi, &res, "SIPCHANINFO(useragent)", client, sizeof(client));
	//function_sipchaninfo_read: This function can only be used on SIP channels.

	/* channel details */
	char pdd[30] = "";
	AGITool_get_variable2(&agi, &res, "CDR(pddsec)", pdd, sizeof(pdd));
	/* tell pdd to master channel so core could read it */
	AGITool_set_variable(&agi, &res, "MASTER_CHANNEL(MOR_PDD)", pdd);

	/* get pdd_limit */
	char pdd_limit_less[30] = "";
	char pdd_limit_more[30] = "";
	char pdd_limit_provider_id[30] = "";
	AGITool_get_variable2(&agi, &res, "MASTER_CHANNEL(MOR_PDD_LIMIT_LESS)", pdd_limit_less, sizeof(pdd_limit_less));
	AGITool_get_variable2(&agi, &res, "MASTER_CHANNEL(MOR_PDD_LIMIT_MORE)", pdd_limit_more, sizeof(pdd_limit_more));
	AGITool_get_variable2(&agi, &res, "MASTER_CHANNEL(MOR_PDD_LIMIT_PROVIDER_ID)", pdd_limit_provider_id, sizeof(pdd_limit_provider_id));

	//sprintf(buff, "Caller's Codec: %s, Client: %s", codec, client);
	sprintf(buff, "Callee's (Leg B) Codec: %s, PDD: %s, PDD limit less: %0.5f, PDD limit more: %0.5f", codec, pdd, atof(pdd_limit_less), atof(pdd_limit_more));
	AGITool_verbose(&agi, &res, buff, 0);


	sprintf(sqlcmd, "UPDATE activecalls SET answer_time = '%s' WHERE uniqueid = '%s';", answer_time, uniqueid);
	mysql_query(&mysql, sqlcmd);

	/* this will fail on prior MOR 11 */
	sprintf(sqlcmd, "UPDATE activecalls SET legb_codec = '%s', pdd = '%s' WHERE uniqueid = '%s';", codec, pdd, uniqueid);
	mysql_query(&mysql, sqlcmd);

	char activecalls_uniqueid[128] = "";
	char activecalls_uniqueid_master[128] = "";
	AGITool_get_variable2(&agi, &res, "MASTER_CHANNEL(MOR_ACTIVECALLS_UNIQUEID)", activecalls_uniqueid_master, sizeof(activecalls_uniqueid_master));

	if (strlen(activecalls_uniqueid_master)) {
		strcpy(activecalls_uniqueid, activecalls_uniqueid_master);
	} else {
		AGITool_get_variable2(&agi, &res, "MOR_ACTIVECALLS_UNIQUEID", activecalls_uniqueid, sizeof(activecalls_uniqueid));
	}

	if (strlen(activecalls_uniqueid)) {
	    char system_cmd[256] = "";
	    sprintf(system_cmd, "asterisk -rx 'mor answer mark %s'", activecalls_uniqueid);
	    system(system_cmd);
	}

	AGITool_verbose(&agi, &res, "Call marked as Answered", 0);
//	AGITool_verbose(&agi, &res, "", 0);

	if (atoi(pdd_limit_provider_id) > 0 && atof(pdd) > 0) {
		sprintf(buff, "Provider id: %d", atoi(pdd_limit_provider_id));
		AGITool_verbose(&agi, &res, buff, 0);
	    if ((atof(pdd) < atof(pdd_limit_less)) || ((atof(pdd) > atof(pdd_limit_more)) && (atof(pdd_limit_more) > 0))) {
	        AGITool_verbose(&agi, &res, "PDD limit reached, hanging up call", 0);
	        AGITool_set_variable(&agi, &res, "MASTER_CHANNEL(MOR_HGC)", "248");
	        AGITool_sendcmd(&agi, &res, "HANGUP %s\n", AGITool_ListGetVal(agi.agi_vars, "agi_channel"));
	    }
	}

	AGITool_Destroy(&agi);
	mysql_close(&mysql);

	return 0;
}


