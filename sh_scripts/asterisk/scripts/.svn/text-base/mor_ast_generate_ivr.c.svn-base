/*
*
*	MOR Asterisk IVR Realtime hooks generation
*	Copyright Mindaugas Kezys / Kolmisoft 2008-2012
*
*	v0.1.1

	2012-05-15	0.1.1 	Asterisk 1.8 version

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

int server_id = 0;

static MYSQL	mysql;


/* Function declarations */

int generate_ivr();

void read_config();
static int mysql_connect();





void my_debug(char *msg) {
    FILE *file;
    file = fopen("/tmp/mor_ast_reg.log","a+");
    fprintf(file,"%s\n",msg);
    fclose(file);
}
		
void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/tmp/mor_ast_reg.log","a+");
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



//my_debug(argv[1]);


    
    read_config();

    if (!mysql_connect()) 
	return 0;
    
    
    generate_ivr();




    mysql_close(&mysql);    



    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;
//    printf("End of MOR Auto-Dialer Cron script.\nTotal campaigns: %i, total numbers: %i\nExecution time: %f s\n\n", total_campaigns, total_numbers, (float) (ut1-ut0)/1000000);    
					      
    //gets(NULL);

}







/* Functions */


//int generate_registry(){
int generate_ivr(){

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    
    int res = 0, i;    

    char buff[2048];
    

	sprintf(sqlcmd,"SELECT id FROM ivr_blocks ORDER BY id ASC");
	
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

		    printf("\n");
		    sprintf(buff, "");		
		    sprintf(buff, "[ivr_block%s]\n", row[0]);
		    printf(buff);

		    sprintf(buff, "");
		    sprintf(buff, "switch => Realtime/ivr_block%s@extensions\n", row[0]);

		    printf(buff);


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
		