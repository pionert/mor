/*
*
*	MOR Auto-Dialer Cron script
*	Copyright Mindaugas Kezys / Kolmisoft 2007
*
*	v0.1.9
*
*	2012-08-21	rename changed to mv
*	2009.12.31	BUG in call distribution
*	2008.11.25	CallerID support
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

struct number{

    int id;
    char number[30];
    char status[30];
    int campaign_id;
    int touch_time_diff;
};


struct campaign {

    int id;
    char name[50];
    char campaign_type[20];
    char status[20];
    char start_time[20];
    char stop_time[20];
    int max_retries;
    int retry_times;
    int wait_time;
    int user_id;
    int device_id;
    int active_numbers;
    char callerid[100];


    struct number numbers[5000];
    int total_numbers;
};

/* Variables */

char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;
int calls_one_time, cron_interval;
int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;

int total_calls_per_period;
int calls_per_campaign;
double call_every_s;

static MYSQL	mysql;

struct campaign campaigns[100];
int total_campaigns = 0;

int total_numbers = 0;

/* Function declarations */

void read_config();
static int mysql_connect();
void create_call_file(char *dst, int max_retries, int retry_time, int wait_time, int account, int time_diff, int campaign_id, char *callerid);
int get_campaigns(char *mtime);
int get_numbers();
void execute_numbers();





main() {

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

    printf("\n\n%s %s - Start of MOR Auto-Dialer Cron script.\n", mdate, mtime);    
    
    read_config();

    if (!mysql_connect()) 
	return 0;
    
    if ((get_campaigns(mtime) < 0) || (total_campaigns == 0))
	return 0;
	
    get_numbers();

    execute_numbers();        

    mysql_close(&mysql);    

    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;
    printf("End of MOR Auto-Dialer Cron script.\nTotal campaigns: %i, total numbers: %i\nExecution time: %f s\n\n", total_campaigns, total_numbers, (float) (ut1-ut0)/1000000);    
					      
    //gets(NULL);

}



/* Functions */


void execute_numbers(){

    int ci, ni;
    char sqlcmd[2048] = "";    

    for (ci=0; ci < total_campaigns; ci++){
	
	if (campaigns[ci].total_numbers > 0) {
	    for (ni=0; ni < campaigns[ci].total_numbers; ni++){

		if (EXECUTE_CALL_FILES) {

	    	    create_call_file(campaigns[ci].numbers[ni].number, campaigns[ci].max_retries, campaigns[ci].retry_times, campaigns[ci].wait_time, campaigns[ci].device_id, campaigns[ci].numbers[ni].touch_time_diff, campaigns[ci].id, campaigns[ci].callerid);

		    /*	Update DB	*/
		
		    sprintf(sqlcmd,"UPDATE adnumbers SET status = 'executed', executed_time = CURRENT_TIMESTAMP WHERE number = '%s' AND campaign_id = %i", campaigns[ci].numbers[ni].number, campaigns[ci].id);
		    if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);	
		    mysql_query(&mysql,sqlcmd);
		}
		
		total_numbers++;
	    }
	}    
    }
}



int get_numbers(){
    
    //int numbers_to_get = calls_per_campaign * total_campaigns;
    int retrieved_numbers = 0;
    int ci, ni;
    int res = 0;

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    


    total_calls_per_period = calls_one_time * cron_interval;
    calls_per_campaign = total_calls_per_period / total_campaigns;
    call_every_s = (float) (cron_interval * 60.0 / total_calls_per_period);
    if (DEBUG) printf("Total calls per period: %i, calls per campaign: %i, call every %f s\n", total_calls_per_period, calls_per_campaign, call_every_s);

    for (ci=0; ci < total_campaigns; ci++){
	
	campaigns[ci].total_numbers = 0;
    
	sprintf(sqlcmd,"SELECT * FROM adnumbers WHERE adnumbers.status = 'new' AND campaign_id = %i LIMIT %i", campaigns[ci].id, calls_per_campaign);

        if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);	
	
	if (mysql_query(&mysql,sqlcmd))
	{    // error	
	    printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        ni = 0;
		while ((row = mysql_fetch_row(result)))
		{

		    campaigns[ci].numbers[ni].id = atoi(row[0]);
		    if (row[1]) strcpy(campaigns[ci].numbers[ni].number, row[1]); else strcpy(campaigns[ci].numbers[ni].number, "");
		    if (row[2]) strcpy(campaigns[ci].numbers[ni].status, row[2]); else strcpy(campaigns[ci].numbers[ni].status, "");	
		    campaigns[ci].numbers[ni].campaign_id = atoi(row[3]);
		    
		    campaigns[ci].numbers[ni].touch_time_diff = rint(((float) ((ni * total_campaigns) + ci)) * call_every_s);
	
		    if (DEBUG) printf("Number: %s, will be called with diff: %i\n", campaigns[ci].numbers[ni].number, campaigns[ci].numbers[ni].touch_time_diff);
	    	    
		    ni++;
    		}
		campaigns[ci].total_numbers = ni;
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
		    res = -1;
		}
	    }
	}
    
    
	if (DEBUG) printf("Total %i numbers for campaign: %i retrieved.\n", campaigns[ci].total_numbers, campaigns[ci].id);	    


    }
    
    return res;

}



int get_campaigns(char *mtime){

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    
    int res = 0, i;    
    
    

	sprintf(sqlcmd,"SELECT campaigns.id, campaigns.name, campaigns.campaign_type, campaigns.status, campaigns.start_time, campaigns.stop_time, campaigns.max_retries, campaigns.retry_time, campaigns.wait_time, campaigns.user_id, campaigns.device_id, COUNT(adnumbers.id), campaigns.callerid FROM campaigns JOIN adnumbers ON (adnumbers.campaign_id = campaigns.id AND adnumbers.status = 'new') JOIN users ON (campaigns.user_id = users.id AND users.blocked = 0 AND ((users.postpaid = 0 AND users.balance > 0) OR ((users.postpaid = 1) AND ((users.balance + users.credit > 0) OR (users.credit = -1))) ) )  WHERE ((start_time < stop_time AND (start_time < '%s' AND stop_time > '%s')) OR (start_time > stop_time AND (start_time < '%s' OR stop_time > '%s'))) AND campaigns.status = 'enabled' GROUP BY campaigns.id;", mtime, mtime, mtime, mtime);

        if (SHOW_SQL)printf("SQL: %s\n", sqlcmd);	

	if (mysql_query(&mysql,sqlcmd))
	{
	    // error	
	    printf("No campaigns found active this time: %s\n", mtime);	    
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
		    campaigns[i].id = atoi(row[0]);
		    strcpy(campaigns[i].name, row[1]);		    
		    if (row[2]) strcpy(campaigns[i].campaign_type, row[2]); else strcpy(campaigns[i].campaign_type, "");
		    if (row[3]) strcpy(campaigns[i].status, row[3]); else strcpy(campaigns[i].status, "");
		    if (row[4]) strcpy(campaigns[i].start_time, row[4]); else strcpy(campaigns[i].start_time, "");
		    if (row[5]) strcpy(campaigns[i].stop_time, row[5]); else strcpy(campaigns[i].stop_time, "");
		    campaigns[i].max_retries = atoi(row[6]);
		    campaigns[i].retry_times = atoi(row[7]);
		    campaigns[i].wait_time = atoi(row[8]);
		    campaigns[i].user_id = atoi(row[9]);
		    campaigns[i].device_id = atoi(row[10]);
		    campaigns[i].active_numbers = atoi(row[11]);
		    if (row[12]) strcpy(campaigns[i].callerid, row[12]); else strcpy(campaigns[i].callerid, "");


		    if (DEBUG) printf("Campaign id: %i, name: %s, type: %s, status: %s, time: %s-%s, retries: %i, r.time: %i, wait: %i, usrid: %i, devid: %i, numbers: %i, callerid: %s\n", campaigns[i].id, campaigns[i].name, campaigns[i].campaign_type, campaigns[i].status, campaigns[i].start_time, campaigns[i].stop_time, campaigns[i].max_retries, campaigns[i].retry_times, campaigns[i].wait_time, campaigns[i].user_id, campaigns[i].device_id, campaigns[i].active_numbers, campaigns[i].callerid);	

		    i++;
    		}
		total_campaigns = i;
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
    		    printf("No campaigns found active this time: %s\n", mtime);	    
		    res = -1;
		}
	    }
	}
    
    
    if (DEBUG) printf("Total campaigns retrieved: %i\n", total_campaigns);	    
    
    return res;

}



void create_call_file(char *dst, int max_retries, int retry_time, int wait_time, int account, int time_diff, int campaign_id, char *callerid){

    FILE *cfile;
    char callfile[1000];    		
    
    char fname[50], temp_file[100], spool_file[100];
    
    char systcmd[200];

    char touch_time[30];
    struct tm tm;
    time_t t1;
        
    sprintf(fname, "mor_ad_%s", dst);
    sprintf(temp_file, "/tmp/%s", fname);
    sprintf(spool_file, "/var/spool/asterisk/outgoing/%s", fname);

    sprintf(callfile, "CallerID: %s <%s>\nChannel: Local/%s@mor_ad_exec/n\nMaxRetries: %i\nRetryTime: %i\nWaitTime: %i\nAccount: %i\nContext: mor_ad_play\nExtension: %s\nPriority: 1\nSet: MOR_AD_CAMPAIGN_ID=%i\n", callerid, callerid, dst, max_retries, retry_time, wait_time, account, dst, campaign_id);

    //printf("%s", callfile);

    /* Write to temp file */
    cfile = fopen(temp_file,"w");
    fprintf(cfile,"%s\n",callfile);	    
    fclose(cfile);

    /* Touch file to change it's execution time */

    t1 = time(NULL) + time_diff;
    localtime_r(&t1, &tm);
    strftime(touch_time, 128, TOUCH_TIME_FORMAT, &tm);

    sprintf(systcmd, "touch -m -t %s %s", touch_time, temp_file);
    system(systcmd);

    /* Move temp file to spool */
    if (EXECUTE_CALL_FILES) { //rename(temp_file, spool_file); //did not work for 1 client, changed to mv
	sprintf(systcmd, "mv %s %s", temp_file, spool_file);
	system(systcmd);
    }


    if (DEBUG) printf("Number %s will be called at: %s\n", dst, touch_time);    
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
	if (!strcmp(var, "calls_one_time")) {
	    calls_one_time = atoi(val);        
	} else {
	if (!strcmp(var, "cron_interval")) {
	    cron_interval = atoi(val); 
	} else {
	if (!strcmp(var, "show_sql")) {
	    SHOW_SQL = atoi(val);        
	} else {
	if (!strcmp(var, "debug")) {
	    DEBUG = atoi(val); 
	} else {
	if (!strcmp(var, "execute_call_files")) {
	    EXECUTE_CALL_FILES = atoi(val);
	} } } } } } } } } }

    }
    
    fclose(file);

    if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %i. Calls one time: %i, cron interval: %i, SHOW_SQL: %i, DEBUG: %i\n", dbhost, dbname, dbuser, dbpass, dbport, calls_one_time, cron_interval, SHOW_SQL, DEBUG);

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
	    if (DEBUG) printf("Successfully connected to database.\n");
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

        if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}
