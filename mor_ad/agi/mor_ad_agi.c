/*
*
*	MOR Auto-Dialer AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2007-2012
*
*	v0.1.5
*
*	2012.07.06	v0.1.5	Save uniqueid for adnumber
*	2009.08.13	v0.1.4	+IVR action
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>

#include "cagi.c"


/*	Structures	*/


struct action{

    int priority;
    char action[30];
    char data[100];

};


/*	Variables	*/
char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;
int SHOW_SQL = 0, DEBUG = 0;

static MYSQL	mysql;

int campaign_id;
char number[30];
char channel[100];

struct action actions[50];
int total_actions = 0;

char sound_dir[100];

AGI_TOOLS agi;
AGI_CMD_RESULT res;


/*	Function definitions	*/

static int mysql_connect();
void read_config();
int get_actions();
void run_actions();
void mark_call_as_completed();
int get_ivr_block_id(int ivr_id);

/*	Main function	*/

int main(int argc, char *argv[])
{
	char dest[100];
	char str[100];

	strcpy(sound_dir, "/var/lib/asterisk/sounds/mor/ad");

	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR Auto-Dial AGI script started.", 0);

	AGITool_get_variable2(&agi, &res, "MOR_AD_CAMPAIGN_ID", dest, sizeof(dest));	
	campaign_id = atoi(dest);
	strcpy(number, AGITool_ListGetVal(agi.agi_vars, "agi_extension")); 
	strcpy(str, AGITool_ListGetVal(agi.agi_vars, "agi_channel")); 
	strncpy(dest, str, strlen(str) - 2);
	sprintf(channel, "%s,2", dest);

	sprintf(str, "Campaign ID: %i, number: %s, channel: %s", campaign_id, number, channel);
	AGITool_verbose(&agi, &res, str, 0);

	read_config();

	sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
	AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    return 0;
	} else {
	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}

	get_actions();
	if (total_actions > 0) {
	    sprintf(str, "Found %i actions", total_actions);
	    AGITool_verbose(&agi, &res, str, 0);
	} else {
    	    AGITool_verbose(&agi, &res, "ERROR! No actions found.", 0);
	    return 0;	
	}

	mark_call_as_completed();

	run_actions();



	AGITool_verbose(&agi, &res, "MOR Auto-Dial AGI script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);

	
	mysql_close(&mysql);  

	return 0;
}


/*	Functions	*/


void mark_call_as_completed(){

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    

    char uniqueid[100] = "";
    AGITool_get_variable2(&agi, &res, "UNIQUEID", uniqueid, sizeof(uniqueid));


    sprintf(sqlcmd,"UPDATE adnumbers SET status='completed', completed_time = CURRENT_TIMESTAMP, channel = '%s', uniqueid = '%s' WHERE number = '%s' AND campaign_id = %i", channel, uniqueid, number, campaign_id);
    mysql_query(&mysql,sqlcmd);

}


void run_actions(){

    int i;    
    char str[200];
    int ivr_block_id = 0;

    for(i=0; i < total_actions; i++){
	sprintf(str, "Action's priority: %i, action: %s, data: %s", actions[i].priority, actions[i].action, actions[i].data);
	AGITool_verbose(&agi, &res, str, 0);    

	if (!strcmp(actions[i].action, "PLAY")){
	    sprintf(str, "%s/%s", sound_dir, actions[i].data);
	    AGITool_stream_file(&agi,&res, str, "", 0);    
	} 

	if (!strcmp(actions[i].action, "WAIT")){
	    sprintf(str, "WAIT %s", actions[i].data);
	    AGITool_exec(&agi, &res, str, 0);        
	} 

	if (!strcmp(actions[i].action, "IVR")){
	
	    ivr_block_id = get_ivr_block_id(atoi(actions[i].data));
	
	    if (ivr_block_id) {
    		sprintf(str, "ivr_block%i", ivr_block_id);
 		AGITool_exec_goto(&agi, &res, str, "s", "1");
	    } else {
		sprintf(str, "Invalid block ID for IVR with ID: %s", actions[i].data);
		AGITool_verbose(&agi, &res, str, 0);    
	    }
	} 
	
	

    }

}


int get_ivr_block_id(int ivr_id){
    
    int res = 0;
    int i;

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    
    int block_id = 0;

    
	sprintf(sqlcmd,"SELECT start_block_id FROM ivrs WHERE id = %i;", ivr_id);

        //if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);	
	
	if (mysql_query(&mysql,sqlcmd))
	{    // error	
	    //printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
		while ((row = mysql_fetch_row(result)))
		{

		    if (row[0]) block_id = atoi(row[0]);
	    	    
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    //printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
		    res = -1;
		}
	    }
	}
    
        
    return block_id;

}



int get_actions(){
    
    int res = 0;
    int i;

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";    

    
	sprintf(sqlcmd,"SELECT priority, action, data FROM adactions WHERE campaign_id = %i ORDER BY priority ASC", campaign_id);

        //if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);	
	
	if (mysql_query(&mysql,sqlcmd))
	{    // error	
	    //printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
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

		    actions[i].priority = atoi(row[0]);
		    if (row[1]) strcpy(actions[i].action, row[1]); else strcpy(actions[i].action, "");
		    if (row[2]) strcpy(actions[i].data, row[2]); else strcpy(actions[i].data, "");
	    	    
		    i++;
    		}
		total_actions = i;
		res = total_actions;
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    //printf("No numbers found for campaign: %s, id: %i\n", campaigns[ci].name, campaigns[ci].id);	    
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
//    strcpy(dbport, "3306");
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
//	    strcpy(dbport, val);        
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
    char my_database[50];

    strcpy(my_database, dbname);
							
    if(dbhost && dbuser && dbpass && my_database) {
        if(!mysql_init(&mysql)) {
	    //printf("Insufficient memory to allocate MySQL resource.\n");
    	    return 0;
	}
        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, my_database, dbport, NULL, 0)) {
	    //if (DEBUG) printf("Successfully connected to database.\n");
	    //
	    return 1;
        } else {
	    //printf("Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
	    //printf("Cannot Connect: %s\n", mysql_error(&mysql));
	    return 0;
        }
    } else {
	if(mysql_ping(&mysql) != 0) {
	    //printf("Failed to reconnect. Check debug for more info.\n");
	    //printf("Server Error: %s\n", mysql_error(&mysql));
	    return 0;
        }

        if(mysql_select_db(&mysql, my_database) != 0) {
	    //printf("Unable to select database: %s. Still Connected.\n", my_database);
	    //printf("Database Select Failed: %s\n", mysql_error(&mysql));
	    return 0;
        }

        //if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}

