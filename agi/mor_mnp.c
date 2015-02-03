/*
*
*	MOR MNP - Mobile Number Portability AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2009
*
*	v0.1.2
*
*	2012-01-26	0.1.2	Check config file existance
*
*
*	This AGI searches for number and adds prefix if number is found in DB
* 	This lets MOR to use different routing(LCR) and Tariff for this number based on prefix: http://wiki.kolmisoft.com/index.php/LCR/Tariff_change_based_on_call_prefix
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "mor_agi_functions.c"



/*	Function definitions	*/

int read_config_mnp();



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
	char extension[1024] = "";
	char prefix[1024] = "";
	char new_extension[1024] = "";


//	strcpy(datetime,"");

	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR MNP AGI script started.", 0);


	if (!read_config_mnp()){

	    AGITool_verbose(&agi, &res, "ERROR!!! MOR MNP AGI script cannot find config file: /usr/local/mor/mor_mnp.conf", 0);
	    AGITool_verbose(&agi, &res, "", 0);

	    AGITool_Destroy(&agi);

	    return -1;
	}


	//sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
	//AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
			
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    AGITool_Destroy(&agi);
	    return 0;
	} else {
	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}


	strcpy(extension, AGITool_ListGetVal(agi.agi_vars, "agi_extension"));

	sprintf(str, "Extension: %s", extension);
	AGITool_verbose(&agi, &res, str, 0);




	// ------- get user details -----
	
	sprintf(sqlcmd, "SELECT prefix FROM numbers WHERE number = '%s';", extension);
	
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
                    if (row[0]) {

                	strcpy(prefix, row[0]); 

			sprintf(str, "Prefix: %s", prefix);
	    		AGITool_verbose(&agi, &res, str, 0);
	    	    }
            	}
        	mysql_free_result(result);
            } 
        }


	strcat(prefix, extension);

	sprintf(str, "New extension: %s", prefix);
	AGITool_verbose(&agi, &res, str, 0);


//	strcpy(variable, "MOR_DEVICE_EXT");
	//strcpy(value, extension);
	
//	sprintf(value, "%s", extension);
	
//    	AGITool_set_variable(&agi, &res, "EXTENSION", extension);
	
	AGITool_set_extension(&agi, &res, prefix);

	AGITool_verbose(&agi, &res, "MOR MNP AGI script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);
	mysql_close(&mysql);  

	return 0;
}


/*	Functions	*/




int read_config_mnp(){
    FILE	*file;
    char var[200], val[200];

    file = fopen("/usr/local/mor/mor_mnp.conf", "r");
    if (file==NULL) return 0;

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor_mnp");
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

//    if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %s, SHOW_SQL: %i, DEBUG: %i\n", dbhost, dbname, dbuser, dbpass, dbport, SHOW_SQL, DEBUG);

    return 1;
}


