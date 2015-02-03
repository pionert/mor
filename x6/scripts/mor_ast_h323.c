/*
*
*	MOR Asterisk H323 configuration generation script
*	Copyright Mindaugas Kezys / Kolmisoft 2009-2012
*
*	v0.1.4
*
*	2012-11-29 v0.1.4 - Do not create port setting if port is 0, this allows incoming calls from all ports #6879
*       2009.02.11 v0.1.3 - Codec support
*       2009.02.06 v0.1.2 - Provider name = prov+device.id
*       2009.01.23 v0.1.1 - CallerID support
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

int generate_h323_server_configuration();
int generate_h323_device_configuration();

void device_codecs(char *codecs_string, int device_id);



void read_config();
static int mysql_connect();





void my_debug(char *msg) {
    FILE *file;
    file = fopen("/tmp/mor_ast_h323.log","a+");
    fprintf(file,"%s\n",msg);
    fclose(file);
}

void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/tmp/mor_ast_h323.log","a+");
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


//    printf("\n\n%s %s - Start of MOR Auto-Dialer Cron script.\n", mdate, mtime);

    read_config();

    if (!mysql_connect())
	return 0;




    generate_h323_server_configuration();
    generate_h323_device_configuration();


    mysql_close(&mysql);




    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;
//    printf("End of MOR Auto-Dialer Cron script.\nTotal campaigns: %i, total numbers: %i\nExecution time: %f s\n\n", total_campaigns, total_numbers, (float) (ut1-ut0)/1000000);

    //gets(NULL);

}



/* Functions */


int generate_h323_server_configuration() {

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;
    int device_id = 0;

    char buff[2048];
    char codecs_string[2048] = "";


        sprintf(buff, "\n; =========== MOR H323 Provider configuration ============\n");
	printf(buff);


	sprintf(sqlcmd,"SELECT providers.name, providers.id, devices.id, devices.host, devices.port, devices.faststart, devices.h245tunneling, devices.dtmfmode, devices.name FROM devices JOIN providers ON (providers.device_id = devices.id) WHERE providers.tech = 'H323';");


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

		    sprintf(buff, "");

		    sprintf(buff, "\n;Provider id: %s, name: %s\n;Device id: %s\n[%s]\ntype=peer\nhost=%s\n", row[1], row[0], row[2], row[8], row[3]);

		    // no info about port if port = 0
		    if (atoi(row[4])){
			sprintf(buff, "%sport=%s\n", buff, row[4]);
		    }

		    sprintf(buff, "%sfastStart=%s\nh245Tunneling=%s\ndtmfmode=%s\n", buff, row[5], row[6], row[7]);


		    if (row[2]) device_id = atoi(row[2]); else device_id = 0;
		    device_codecs(codecs_string, device_id);

		    sprintf(buff, "%s%s", buff, codecs_string);

		    // output to asterisk
		    printf(buff);

		    // output to debug file
		    my_debug(buff);

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



    return res;

}



int generate_h323_device_configuration() {

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;
    int device_id = 0;

    char codecs_string[2048] = "";
    char buff[2048];

    FILE *file;
    file = fopen("/etc/asterisk/extensions_mor_h323.conf","w");

        sprintf(buff, "\n; =========== MOR H323 Device configuration ============\n");
	fprintf(file,"%s\n",buff);



        sprintf(buff, "\n; =========== MOR H323 Device configuration ============\n");
	printf(buff);


	sprintf(sqlcmd,"SELECT devices.name, devices.id, devices.host, devices.port, devices.faststart, devices.h245tunneling, devices.dtmfmode, devices.callerid FROM devices WHERE devices.device_type = 'H323' and devices.user_id != -1;");
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

		    sprintf(buff, "\n;Device id: %s\n[%s]\ntype=friend\nhost=%s\n", row[1], row[0], row[2]);

		    // no info about port if port = 0
		    if (atoi(row[3])){
			sprintf(buff, "%sport=%s\n", buff, row[3]);
		    }

		    sprintf(buff, "%sfastStart=%s\nh245Tunneling=%s\ndtmfmode=%s\ncontext=h323_%s\n", buff, row[4], row[5], row[6], row[1]);


		    if (row[1]) device_id = atoi(row[1]); else device_id = 0;
		    device_codecs(codecs_string, device_id);

		    sprintf(buff, "%s%s", buff, codecs_string);

		    // output to asterisk
		    printf(buff);

		    // output to debug file
		    my_debug(buff);


		    // make Asterisk extensions.conf configuration

		    sprintf(buff, "");
		    if ((row[7]) && (strlen(row[7])) ){
    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Set(CALLERID(all)=%s)\nexten => _X.,3,Goto(mor,${EXTEN},1)\n", row[1], row[1], row[7]);
    		    } else {
    			sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Goto(mor,${EXTEN},1)\n", row[1], row[1]);
    		    }


		    fprintf(file,"%s\n",buff);

		    //output to debug
		    my_debug(buff);


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


    fclose(file);


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
