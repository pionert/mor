
#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

#include "cagi.c"


/*	Variables	*/

char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;
static int connected = 0; /* Initially not connected to the DB */

int SHOW_SQL = 0, DEBUG = 0;

static MYSQL	mysql;

AGI_TOOLS agi;
AGI_CMD_RESULT res;


char systcmd[1024];
char sqlcmd[2048];    



/*	Function definitions	*/

static int mysql_connect();
void read_config();
float mor_convert_currency(float amount, char src_currency[10], char dst_currency[10]);




/*	Debug functions		*/


void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/agi_debug.log","a+");
    fprintf(file,"logger: %s\n",msg);
    fclose(file);
}
			
void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/agi_debug.log","a+");
    fprintf(file,"logger: %i\n",msg);
    fclose(file);
}


/*	Functions	*/


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
	    dbport = atoi(val);        
	} else {
	if (!strcmp(var, "show_sql")) {
	    SHOW_SQL = atoi(val);        
	} else {
	if (!strcmp(var, "debug")) {
	    DEBUG = atoi(val); 
	} } } } } } }

    }
    
    fclose(file);

    //if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %s. Calls one time: %i, cron interval: %i, SHOW_SQL: %i, DEBUG: %i\n", dbhost, dbname, dbuser, dbpass, dbport, calls_one_time, cron_interval, SHOW_SQL, DEBUG);

}


static int mysql_connect()
{

//    AGITool_verbose(&agi, &res, "mc1", 0);


//    char my_database[50];

//    strcpy(my_database, dbname);
							
    if(dbhost && dbuser && dbpass && dbname) {

//    AGITool_verbose(&agi, &res, "mc2", 0);


        if(!mysql_init(&mysql)) {
	    //printf("Insufficient memory to allocate MySQL resource.\n");
    	    AGITool_verbose(&agi, &res, "Insufficient memory to allocate MySQL resource.", 0);
    	    return 0;
	}

//    AGITool_verbose(&agi, &res, "mc3", 0);


        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, dbname, dbport, NULL, 0)) {
	    //if (DEBUG) printf("Successfully connected to database.\n");
	    //
//    	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	    return 1;
        } else {
    	    AGITool_verbose(&agi, &res, "Failed to connect database server. Check debug for more info.", 0);
	    //printf("Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
	    //printf("Cannot Connect: %s\n", mysql_error(&mysql));
	    return 0;
        }
	
//    AGITool_verbose(&agi, &res, "mc4", 0);
	
	
    } else {
    
//    AGITool_verbose(&agi, &res, "mc5", 0);
    
	if(mysql_ping(&mysql) != 0) {
    	    AGITool_verbose(&agi, &res, "Failed to reconnect. Check debug for more info.", 0);
	    //printf("Failed to reconnect. Check debug for more info.\n");
	    //printf("Server Error: %s\n", mysql_error(&mysql));
	    return 0;
        }

//    AGITool_verbose(&agi, &res, "mc6", 0);


        if(mysql_select_db(&mysql, dbname) != 0) {
    	    AGITool_verbose(&agi, &res, "Database Select Failed", 0);
	    //printf("Unable to select database: %s. Still Connected.\n", my_database);
	    //printf("Database Select Failed: %s\n", mysql_error(&mysql));
	    return 0;
        }


//    AGITool_verbose(&agi, &res, "mc7", 0);

    	AGITool_verbose(&agi, &res, "DB connected.", 0);
        //if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}



/* convert currency */
float mor_convert_currency(float amount, char src_currency[10], char dst_currency[10]){

    char sqlcmd[2048] = "";
    MYSQL_RES   *result;
    MYSQL_ROW   row;
    //int res=0;
                    

    char buff[1024] = "";

    float src_currency_exchange_rate = 1;
    float dst_currency_exchange_rate = 1;
    float converted_amount = 0;



    /* retrieve exchange rates */



    sprintf(sqlcmd, "SELECT (SELECT exchange_rate FROM `currencies` WHERE name = '%s'), (SELECT exchange_rate FROM `currencies` WHERE name = '%s');", src_currency, dst_currency);	


//#if SHOW_QUERIES
//        sprintf(buff, "SQL: %s\n", sqlcmd);	
        //if (SHOW_NOTICE) ast_log(LOG_NOTICE, "%s", buff);
//        AGITool_verbose(&agi, &res, buff, 0);
//#endif	
		
//	ast_mutex_lock(&mysql_lock);

	if (mysql_query(&mysql, sqlcmd))
	{
	    // error	  	
	    sprintf(buff, "ERROR: SQL problem!\n");	    
	    //if (SHOW_ERROR) ast_log(LOG_ERROR, "%s", buff);
	    AGITool_verbose(&agi, &res, buff, 0);
	    
	    //res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
		while ((row = mysql_fetch_row(result)))
		{
		    if (row[0]) src_currency_exchange_rate = atof(row[0]);
		    if (row[1]) dst_currency_exchange_rate = atof(row[1]);
    		}
			
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    sprintf(buff, "ERROR: Error: %s\n", mysql_error(&mysql));
		    //if (SHOW_ERROR) ast_log(LOG_ERROR, "%s", buff);
		    AGITool_verbose(&agi, &res, buff, 0);
		    
		    //res = -1;
		}
	    }
	}

//	ast_mutex_unlock(&mysql_lock);


    /* possible error fix */
    if (src_currency_exchange_rate == 0) src_currency_exchange_rate = 1;
    if (dst_currency_exchange_rate == 0) dst_currency_exchange_rate = 1;


    converted_amount = amount / src_currency_exchange_rate * dst_currency_exchange_rate;


    sprintf(buff, "Converted %f %s (%f) to %f %s (%f)\n", amount, src_currency, src_currency_exchange_rate, converted_amount, dst_currency, dst_currency_exchange_rate);
    AGITool_verbose(&agi, &res, buff, 0);


    return converted_amount;

}

