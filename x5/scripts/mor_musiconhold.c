// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2012
// About:         Script generates musiconhold.conf output 


#define SCRIPT_NAME      "mor_musiconhold"
#define IVR_VOICE_PATH   "/home/mor/public/ivr_voices/"

#include "mor_functions.c"

int main() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    mor_init("Starting 'Music on hold' script\n");

    // get all mohs
    if (mor_mysql_query("SELECT mohs.id, ivr_voices.voice, random FROM mohs INNER JOIN ivr_voices ON ivr_voices.id = mohs.ivr_voice_id;")) {
        return 1;
    }

    // get result
    result = mysql_store_result(&mysql);

    if (result == NULL) {
        mor_log("Result is empty!\n");
        return 1;
    }

    // generate output
    while (( row = mysql_fetch_row(result) )) {
        printf("[moh%s]\n", row[0]);
        printf("mode=files\n");
        printf("directory=" IVR_VOICE_PATH "%s\n", row[1]);
        printf("random=%s\n", row[2]);
        printf("\n");
    }

    mysql_free_result(result);
    mysql_close(&mysql);

    mor_log("Script completed\n");

    return 0;
}
