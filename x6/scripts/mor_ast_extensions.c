// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2014
// About:         Script generates extensions_mor.conf output


#define SCRIPT_NAME  "mor_ast_extensions"

#include "mor_functions.c"

void generate_extensions_for_pbx_pools();

int main() {

    mor_init("Starting MOR extensions script\n");

    // pbx pools
    generate_extensions_for_pbx_pools();

    mor_log("Script completed\n");

    return 0;
}


/*
    For PBX pools
*/


void generate_extensions_for_pbx_pools() {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char query[2048] = "";

    // get all pbx pools
    sprintf(query, "SELECT id, name FROM pbx_pools WHERE id > 1");

    if (mor_mysql_query(query)) {
        return;
    }

    // get result
    result = mysql_store_result(&mysql);

    if (result == NULL) {
        mor_log("Result is empty!\n");
        return;
    }

    // generate output
    while (( row = mysql_fetch_row(result) )) {
        if (row[0]) {
            if (row[1]) printf("; PBX pool '%s'\n", row[1]);
            printf("[pool_%s_mor_local]\n", row[0]);
            printf("exten => _+.,1,Goto(${EXTEN:1},1)\n");
            printf("exten => fax, 1, Goto(mor_fax2email,${EXTEN},1)\n");
            printf("switch => Realtime/pool_%s_mor_local@extensions\n", row[0]);
            printf("\n");
        }
    }

    mysql_free_result(result);
    mysql_close(&mysql);

}
