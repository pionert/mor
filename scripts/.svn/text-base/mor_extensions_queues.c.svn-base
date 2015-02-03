// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2012
// About:         Script generates extensions.conf output


#define SCRIPT_NAME      "mor_extensions_queues"
#define IVR_VOICE_PATH   "/home/mor/public/ivr_voices/"

#include "mor_functions.c"

// FUNCTION DECLARATIONS

void get_file_name(char *file); 

int main() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = { 0 };
    char file_path[512] = { 0 };
    char option_list[32] = { 0 };

    mor_init("Starting 'Extensions for queues' script'\n");

    // get all queues
    sprintf(query, "SELECT queues.id, queues.id, queues.name, max_wait_time, ivr_voices.voice, ivr_sound_files.path, queues.allow_caller_hangup, queues.allow_callee_hangup, queues.ringing_instead_of_moh, queues.ring_at_once, queues.failover_action, queues.failover_data, dids.did, devices.name FROM queues "
                   "LEFT JOIN ivr_sound_files ON ivr_sound_files.id = queues.join_announcement "
                   "LEFT JOIN ivr_voices ON ivr_sound_files.ivr_voice_id = ivr_voices.id "
                   "LEFT JOIN dids ON dids.id = queues.failover_data "
                   "LEFT JOIN devices ON devices.id= queues.failover_data");

    if (mor_mysql_query(query)) {
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

        if (row[5]) {
            // get only the name of sound file (remove extension)
            get_file_name(row[5]);
            // format file path
            sprintf(file_path, IVR_VOICE_PATH "%s/%s", row[4], row[5]);
        }

        // get options characters
        if (strcmp(row[6], "yes") == 0) strcat(option_list, "H");
        if (strcmp(row[7], "yes") == 0) strcat(option_list, "h");
        if (strcmp(row[8], "yes") == 0) strcat(option_list, "r");
        if (strcmp(row[9], "yes") == 0) strcat(option_list, "R");

        printf("[queue%s]\n", row[0]);
        printf("exten => s,1,Answer\n");
        if (row[5]) printf("exten => s,n,Background(%s)\n", file_path);
        printf("exten => s,n,Queue(queue_%s,%s,,,%s)\n", row[2], option_list, row[3]);
        if (strcmp(row[10], "hangup") == 0) printf("exten => s,n,Hangup\n");
        if (strcmp(row[10], "extension") == 0) printf("exten => s,n,Goto(mor_local,%s,1)\n", row[11]);
        if (strcmp(row[10], "did") == 0) printf("exten => s,n,Goto(mor_local,%s,1)\n", row[12]);
        if (strcmp(row[10], "device") == 0) printf("exten => s,n,Goto(mor_local,%s,1)\n", row[13]);

        printf("\n");

        memset(option_list, 0, 32);
    }

    mysql_free_result(result);
    mysql_close(&mysql);

    mor_log("Script completed\n");

    return 0;
}

void get_file_name(char *file) {

    int i = 0;
    int len = strlen(file);

    while (i <= len) {
        if (file[len - i] == '.') break;
        i++;
    }

    memset(file + (len - i), 0, i);

}
