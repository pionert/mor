/*
*
*	MOR Asterisk SIP configuration generation script
*	Copyright Mindaugas Kezys / Kolmisoft 2009
*
*	v0.1.1
*
*	2009-08-19 0.1.1 Log file changed
*	2009-04-22 0.1.0 Initial version
*
*/


#include <mysql.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>

/* Defines */

#define DATE_FORMAT "%Y-%m-%d"
#define TIME_FORMAT "%T"
#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S"


/* Structures */

/* Variables */

char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;
int calls_one_time, cron_interval;

int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;

int server_id = 1;

static MYSQL	mysql;


/* Function declarations */

int generate_sip_device_configuration();
int generate_sip_extensions();
void device_codecs(char *codecs_string, int device_id);



void read_config();
static int mysql_connect();





void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/mor_ast_sip.log","a+");
    fprintf(file,"%s\n",msg);
    fclose(file);
}

void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/mor_ast_sip.log","a+");
    fprintf(file,"%i\n",msg);
    fclose(file);
}



main(int argc, char *argv[]) {

    struct tm tm;
    struct timeval t0, t1;
    char mdate[20];
    char mtime[20];
    time_t t;
    suseconds_t	ut0, ut1;

    /* Get current time */
    gettimeofday(&t0, NULL);
    t=t0.tv_sec;
    ut0=t0.tv_usec;
    localtime_r(&t, &tm);
    strftime(mdate, 128, DATE_FORMAT, &tm);
    strftime(mtime, 128, TIME_FORMAT, &tm);


    read_config();

    if (!mysql_connect())
	return 0;

    generate_sip_device_configuration();
//    generate_sip_extensions();

    mysql_close(&mysql);

    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;

}



/* Functions */



int generate_sip_extensions() {

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;
    int device_id = 0;

    char buff[2048];
    char extension[128] = "";

    FILE *file;
    file = fopen("/etc/asterisk/extensions_mor_sip.conf","w");


	fprintf(file,"\n; =========== MOR SIP Device configuration ============\n\n; Any custom changes to this file will be overwritten \n\n[mor_local_sip]\n");


	sprintf(sqlcmd,"SELECT extlines.device_id, extlines.exten, extlines.priority, extlines.app, extlines.appdata FROM extlines JOIN devices ON (extlines.device_id = devices.id) WHERE devices.device_type = 'SIP' ORDER BY exten ASC, priority ASC;");
//        my_debug(sqlcmd);

        //printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))

	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {



	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{


		    // make Asterisk configuration

		    // new line for pretier view
		    if (strcmp(extension, row[1]))
		      fprintf(file, "\n");

		    fprintf(file, "exten => %s,%s,%s(%s)\n", row[1], row[2], row[3], row[4]);

		    strcpy(extension, row[1]);


		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}


    fclose(file);


    return res;

}




int generate_sip_device_configuration() {

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;
    int device_id = 0;

    char codecs_string[2048] = "";
    char buff[2048];

//    FILE *file;
//    file = fopen("/etc/asterisk/extensions_mor_sip.conf","w");

//        sprintf(buff, "\n; =========== MOR SIP Device configuration ============\n");
//	fprintf(file,"%s\n",buff);



        sprintf(buff, "\n; =========== MOR SIP Device configuration ============\n");
	printf(buff);


	sprintf(sqlcmd,"SELECT devices.name, devices.id, devices.host, devices.port, devices.faststart, devices.h245tunneling, devices.dtmfmode, devices.callerid, secret, context, extension, username, transfer, deny, permit, nat, qualify, canreinvite, callgroup, pickupgroup, fromuser, fromdomain, trustrpid, sendrpid, insecure, progressinband, videosupport, t38pt_udptl, promiscredir FROM devices WHERE devices.device_type = 'SIP';");
//        my_debug(sqlcmd);

        //if (SHOW_SQL)	printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))

	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{


		    // make Asterisk configuration

		    sprintf(buff, "");

		    sprintf(buff, "\n;Device id: %s\n[%s]\ntype=friend\n", row[1], row[0]);

		    //accountcode
		    if ((row[1]) && (strlen(row[1]))) sprintf(buff, "%saccountcode=%s\n", buff, row[1]);

		    //host
		    if ((row[2]) && (strlen(row[2]))) sprintf(buff, "%shost=%s\n", buff, row[2]);

		    //port
		    if ((row[3]) && (strlen(row[3]))) sprintf(buff, "%sport=%s\n", buff, row[3]);

		    //dtmfmode
		    if ((row[6]) && (strlen(row[6]))) sprintf(buff, "%sdtmfmode=%s\n", buff, row[6]);

		    //callerid
		    if ((row[7]) && (strlen(row[7]))) sprintf(buff, "%scallerid=%s\n", buff, row[7]);

		    //secret
		    if ((row[8]) && (strlen(row[8]))) sprintf(buff, "%ssecret=%s\n", buff, row[8]);

		    //context
		    if ((row[9]) && (strlen(row[9]))) sprintf(buff, "%scontext=%s\n", buff, row[9]);

		    //username
		    if ((row[11]) && (strlen(row[11]))) sprintf(buff, "%susername=%s\n", buff, row[11]);

		    //deny
		    if ((row[13]) && (strlen(row[13]))) sprintf(buff, "%sdeny=%s\n", buff, row[13]);

		    //permit
		    if ((row[14]) && (strlen(row[14]))) sprintf(buff, "%spermit=%s\n", buff, row[14]);

		    //nat
		    if ((row[15]) && (strlen(row[15]))) sprintf(buff, "%snat=%s\n", buff, row[15]);

		    //qualify
		    if ((row[16]) && (strlen(row[16]))) sprintf(buff, "%squalify=%s\n", buff, row[16]);

		    //canreinvite
		    if ((row[17]) && (strlen(row[17]))) sprintf(buff, "%scanreinvite=%s\n", buff, row[17]);

		    //callgroup
		    if ((row[18]) && (strlen(row[18]))) sprintf(buff, "%scallgroup=%s\n", buff, row[18]);

		    //pickupgroup
		    if ((row[19]) && (strlen(row[19]))) sprintf(buff, "%spickupgroup=%s\n", buff, row[19]);

		    //fromuser
		    if ((row[20]) && (strlen(row[20]))) sprintf(buff, "%sfromuser=%s\n", buff, row[20]);

		    //fromdomain
		    if ((row[21]) && (strlen(row[21]))) sprintf(buff, "%sfromdomain=%s\n", buff, row[21]);

		    //trustrpid
		    if ((row[22]) && (strlen(row[22]))) sprintf(buff, "%strustrpid=%s\n", buff, row[22]);

		    //sendrpid
		    if ((row[23]) && (strlen(row[23]))) sprintf(buff, "%ssendrpid=%s\n", buff, row[23]);

		    //insecure
		    if ((row[24]) && (strlen(row[24]))) sprintf(buff, "%sinsecure=%s\n", buff, row[24]);

		    //progressinband
		    if ((row[25]) && (strlen(row[25]))) sprintf(buff, "%sprogressinband=%s\n", buff, row[25]);

		    //videosupport
		    if ((row[26]) && (strlen(row[26]))) sprintf(buff, "%svideosupport=%s\n", buff, row[26]);

		    //t38pd_udptl
		    if ((row[27]) && (strlen(row[27]))) sprintf(buff, "%st38pd_udptl=%s\n", buff, row[27]);

		    //promiscredir
		    if ((row[28]) && (strlen(row[28]))) sprintf(buff, "%spromiscredir=%s\n", buff, row[28]);



		    if (row[1]) device_id = atoi(row[1]); else device_id = 0;
		    device_codecs(codecs_string, device_id);

		    sprintf(buff, "%s%s", buff, codecs_string);

		    // output to asterisk
		    printf(buff);

		    // output to debug file
		    my_debug(buff);


		    // make Asterisk extensions.conf configuration

//		    sprintf(buff, "");
//		    if ((row[7]) && (strlen(row[7])) ){
//    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Set(CALLERID(all)=%s)\nexten => _X.,3,Goto(mor,${EXTEN},1)\n", row[1], row[1], row[7]);
//    		    } else {
//    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Goto(mor,${EXTEN},1)\n", row[1], row[1]);
//    		    }


//		    fprintf(file,"%s\n",buff);

		    //output to debug
//		    my_debug(buff);


//		    printf("register => test:test@212.59.21.2:5060/1244\n");

//		    if (DEBUG) printf("Campaign id: %i, name: %s, type: %s, status: %s, time: %s-%s, retries: %i, r.time: %i, wait: %i, usrid: %i, devid: %i, numbers: %i\n", campaigns[i].id, campaigns[i].name, campaigns[i].campaign_type, campaigns[i].status, campaigns[i].start_time, campaigns[i].stop_time, campaigns[i].max_retries, campaigns[i].retry_times, campaigns[i].wait_time, campaigns[i].user_id, campaigns[i].device_id, campaigns[i].active_numbers);

		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}


//    fclose(file);


    return res;

}






void device_codecs(char *codecs_string, int device_id) {

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;
//    int device_id = 0;


    char buff[2048] =  "disallow=all\n";


// ================= codecs ==================



	sprintf(sqlcmd,"SELECT codecs.name FROM codecs JOIN devicecodecs ON (devicecodecs.codec_id = codecs.id AND devicecodecs.device_id = %i);", device_id);
//        my_debug(sqlcmd);

        //if (SHOW_SQL)	printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))

	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{


		    // make Asterisk configuration


		    sprintf(buff, "%sallow=%s\n", buff, row[0]);

//my_debug(buff);


		    // make Asterisk extensions.conf configuration
/*
		    sprintf(buff, "");
		    if ((row[7]) && (strlen(row[7])) ){
    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Set(CALLERID(all)=%s)\nexten => _X.,3,Goto(mor,${EXTEN},1)\n", row[1], row[1], row[7]);
    		    } else {
    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Goto(mor,${EXTEN},1)\n", row[1], row[1]);
    		    }
*/
//		    fprintf(file,"%s\n",buff);

//my_debug(buff);


//		    printf("register => test:test@212.59.21.2:5060/1244\n");

//		    if (DEBUG) printf("Campaign id: %i, name: %s, type: %s, status: %s, time: %s-%s, retries: %i, r.time: %i, wait: %i, usrid: %i, devid: %i, numbers: %i\n", campaigns[i].id, campaigns[i].name, campaigns[i].campaign_type, campaigns[i].status, campaigns[i].start_time, campaigns[i].stop_time, campaigns[i].max_retries, campaigns[i].retry_times, campaigns[i].wait_time, campaigns[i].user_id, campaigns[i].device_id, campaigns[i].active_numbers);

		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}


    strcpy(codecs_string, buff);

}






void read_config(){
    FILE	*file;
    char var[200], val[200];

    file = fopen("/var/lib/asterisk/agi-bin/mor.conf", "r");

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;
    //strcpy(dbport, "3306");

    calls_one_time = 20;
    cron_interval = 10;

    /* Read values from conf file */
    while (fscanf(file, "%s = %s", var, val) != EOF) {

	if (!strcmp(var, "host")) {
	    strcpy(dbhost, val);
	} else {
	if (!strcmp(var, "db")) {
	    strcpy(dbname, val);
	} else {
	if (!strcmp(var, "user")) {
	    strcpy(dbuser, val);
	} else  {
	if (!strcmp(var, "secret")) {
	    strcpy(dbpass, val);
	} else {
	if (!strcmp(var, "port")) {
	    //strcpy(dbport, val);
	    dbport = atoi(val);
	} else {
	if (!strcmp(var, "show_sql")) {
	    SHOW_SQL = atoi(val);
	} else {
	if (!strcmp(var, "debug")) {
	    DEBUG = atoi(val);
	} else {
	if (!strcmp(var, "server_id")) {
	    server_id = atoi(val);
	} else {
	} } } } } } } }

    }

    fclose(file);

    my_debug("server_id");
    my_debug_int(server_id);


//    if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %i, SHOW_SQL: %i, DEBUG: %i, server_id\n", dbhost, dbname, dbuser, dbpass, dbport, SHOW_SQL, DEBUG);

}


static int mysql_connect()
{
    char my_database[50];

    strcpy(my_database, dbname);

    if(dbhost && dbuser && dbpass && my_database) {
        if(!mysql_init(&mysql)) {
	    printf("Insufficient memory to allocate MySQL resource.\n");
    	    return 0;
	}
        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, my_database, dbport, NULL, 0)) {
	    //if (DEBUG) printf("Successfully connected to database.\n");
	    return 1;
        } else {
	    printf("Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
	    printf("Cannot Connect: %s\n", mysql_error(&mysql));
	    return 0;
        }
    } else {
	if(mysql_ping(&mysql) != 0) {
	    printf("Failed to reconnect. Check debug for more info.\n");
	    printf("Server Error: %s\n", mysql_error(&mysql));
	    return 0;
        }

        if(mysql_select_db(&mysql, my_database) != 0) {
	    printf("Unable to select database: %s. Still Connected.\n", my_database);
	    printf("Database Select Failed: %s\n", mysql_error(&mysql));
	    return 0;
        }

        //if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}
