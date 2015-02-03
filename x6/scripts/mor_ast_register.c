/*
*
*	MOR Asterisk Registration script
*	Copyright Mindaugas Kezys / Kolmisoft 2015
*
*	v1.0
*
*
*   2015.01.26 v1.0 Code cleanup
*	2011.03.16 v0.2 Bugfix with registration line
*
*/


#define SCRIPT_VERSION "1.0"
#define SCRIPT_NAME    "mor_ast_register"

#include "mor_functions.c"


// GLOBAL VARIABLES


int calls_one_time = 0;
int cron_interval = 0;
char server_id_str[256] = "";
int server_id = 1;


// FUNCTION DECLARATIONS


int generate_registry(char *prov_type);


// MAIN FUNCTION


int main(int argc, char *argv[]) {

    mor_init("Starting MOR X6 Asterisk Provider Register script\n");

    mor_get_variable("server_id", server_id_str);
    if (strlen(server_id_str)) {
        server_id = atoi(server_id_str);
    }
    mor_log("Server id: %d\n", server_id);

    if (argc > 1) {
        mor_log("Provider type: %s\n", argv[1]);
        generate_registry(argv[1]);
    } else {
        mor_log("Argc <= 1, aborting....\n");
    }

    // close mysql
    mysql_close(&mysql);
    // we will not use mysql, so free other memory used by sql
    mysql_library_end();

    mor_log("Script completed!\n");

    return 0;

}


// FUNCTIONS


int generate_registry(char *prov_type) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[4000] = "";
    char buff[4000] = "";
    int registrations_found = 0;

	sprintf(sqlcmd,"SELECT devices.username, devices.secret, providers.server_ip, providers.port, providers.reg_extension, providers.reg_line "
        "FROM providers "
        "JOIN devices ON (providers.device_id = devices.id) "
        "JOIN serverproviders ON (serverproviders.provider_id = providers.id) "
        "WHERE providers.register = 1 AND serverproviders.server_id = %i AND providers.tech = '%s'", server_id, prov_type);

	mor_log("%s\n", sqlcmd);

	if (mor_mysql_query(sqlcmd)) {
	    return 1;
	}

	result = mysql_store_result(&mysql);
	if (result) {
		while ((row = mysql_fetch_row(result))) {
		    if (row[5] && strlen(row[5])) {
			    sprintf(buff, "register => %s\n", row[5]);
		    } else {
    			sprintf(buff, "register => %s:%s@%s", row[0], row[1], row[2]);
		        if (row[3] && strlen(row[3])) {
			        sprintf(buff, "%s:%s", buff, row[3]);
			    }
			    // extension
    			if (row[4] && (strlen(row[4]) > 0)) {
    			    sprintf(buff, "%s/%s", buff, row[4]);
    			}
    			sprintf(buff, "%s\n", buff);
		    }
		    printf(buff);
            mor_log("%s\n", buff);
            registrations_found++;
    	}
		mysql_free_result(result);
	}

    mor_log("Total registrations founs: %d\n", registrations_found);

    return 0;

}
