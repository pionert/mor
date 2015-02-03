
/*
*
*    MOR Play Random AGI script
*    Copyright Ričardas Stoma / Kolmisoft 2014
*
*    v0.1
*
*    2014.07.10 v0.1 Release
*
*    This AGI script saves or clears callerid for pinless dialing
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "mor_agi_functions.c"

int main(int argc, char *argv[]) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char buff[1024] = "";
    char log_buff[1024] = "";
    char query[1024] = "";
    char callerid[256] = "";
    int card_id = 0;
    int save = -1;      // 1 - save callerid, 0 - clear callerid, -1 - error

    /* init environment */
    AGITool_Init(&agi);
    AGITool_verbose(&agi, &res, "MOR Pinless control script started", 0);


    if (argc != 2) {
        AGITool_verbose(&agi, &res, "Error - Wrong number of argments", 0);
        return 1;
    }

    if (!strlen(argv[1])) {
        AGITool_verbose(&agi, &res, "Error - Argument is empty", 0);
        return 1;
    } else {
        save = atoi(argv[1]);
    }

    if (save != 1 && save != 0) {
        sprintf(log_buff, "Error - Bad argument value (%d)", save);
        AGITool_verbose(&agi, &res, log_buff, 0);
        return 1;
    }

    // DB connection
    read_config();

    if (!mysql_connect()) {
        AGITool_verbose(&agi, &res, "ERROR! Not connected to database", 0);
        AGITool_Destroy(&agi);
        return 0;
    }

    // get card id

    AGITool_get_variable2(&agi, &res, "MOR_CARD_ID", buff, sizeof(buff));
    if (buff) {
        card_id = atoi(buff);
        if (card_id) {
            sprintf(log_buff, "Card ID: %i", card_id);
            AGITool_verbose(&agi, &res, log_buff, 0);
        } else {
            AGITool_verbose(&agi, &res, "Error - Card ID not found", 0);
            return 1;
        }
    }

    // get callerid

    AGITool_get_variable2(&agi, &res, "MOR_PINLESS_CLI", buff, sizeof(buff));
    if (buff) {
        strcpy(callerid, buff);
        if (strlen(callerid)) {
            sprintf(log_buff, "CallerID: %s", callerid);
            AGITool_verbose(&agi, &res, log_buff, 0);
        } else {
            AGITool_verbose(&agi, &res, "Error - CallerID not found", 0);
            return 1;
        }
    }

    if (save) {
        sprintf(query, "UPDATE cards SET callerid = '%s' WHERE id = %d", callerid, card_id);
    } else {
        sprintf(query, "UPDATE cards SET callerid = '' WHERE id = %d", card_id);
    }

    if (mysql_query(&mysql, query)) {
        sprintf(log_buff, "MySQL error: %s", mysql_error(&mysql));
        AGITool_verbose(&agi, &res, log_buff, 0);
        return 1;
    }

    /* detroy environment */
    AGITool_verbose(&agi, &res, "MOR Pinless control script finished", 0);
    AGITool_Destroy(&agi);
    return 0;

}
