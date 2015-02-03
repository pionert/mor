// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2012
// About:         Script generates queues.conf output


#define SCRIPT_NAME      "mor_queues"
#define IVR_VOICE_PATH   "/home/mor/public/ivr_voices/"

#include "mor_functions.c"

// FUNCTION DECLARATIONS

void get_file_name(char *file);

int main() {

    MYSQL_RES *result, *announce_result, *members_result;
    MYSQL_ROW row, announce_row, members_row;

    char query[4096] = { 0 };
    char coll_list[1024] = { 0 };
    char announce_query[512] = { 0 };
    char members_query[512] = { 0 };
    char announce_buffer[1024] = { 0 };
    char tmp_buffer[256] = { 0 };

    mor_init("Starting 'Queues' script\n");

    // collumn list
    sprintf(coll_list, "queues.name, "
                       "queues.strategy, "
                       "queues.weight, "
                       "queues.autofill, "
                       "queues.ringinuse, "
                       "queues.reportholdtime, "
                       "A.path, "
                       "queues.memberdelay, "
                       "queues.timeout, "
                       "queues.retry, "
                       "queues.wrapuptime, "
                       "queues.maxlen, "
                       "queues.moh_id, "
                       "queues.joinempty, "
                       "queues.leavewhenempty, "
                       "queues.context, "
                       "queues.announce_frequency, "
                       "queues.min_announce_frequency, "
                       "queues.announce_position, "
                       "queues.announce_position_limit, "
                       "queues.announce_holdtime, "
                       "queues.announce_round_seconds, "
                       "queues.periodic_announce_frequency, "
                       "queues.random_periodic_announce, "
                       "queues.relative_periodic_announce, "
                       "queues.servicelevel, "
                       "queues.penaltymemberslimit, "
                       "queues.autopause, "
                       "queues.setinterface, "
                       "queues.setqueueentryvar, "
                       "queues.setqueuevar, "
                       "queues.membermacro, "
                       "queues.membergosub, "
                       "queues.timeoutrestart, "
                       "queues.id, "
                       "ivrs.start_block_id,"
                       "ivr_voices.voice");

    // get all queues info
    sprintf(query, "SELECT %s FROM queues "
                   "LEFT JOIN mohs ON mohs.id = queues.moh_id "
                   "LEFT JOIN ivr_sound_files AS A ON A.id = queues.announce "
                   "INNER JOIN ivr_voices ON ivr_voices.id = A.ivr_voice_id "
                   "LEFT JOIN ivrs ON ivrs.id=queues.context", coll_list);

    if (mor_mysql_query(query)) {
        return 1;
    }

    // get result
    result = mysql_store_result(&mysql);

    if (result == NULL) {
        mor_log("Empty result!\n");
        return 1;
    }

    // generate output
    while (( row = mysql_fetch_row(result) )) {

        printf("[queue_%s]\n", row[0]);
        if (row[1]) printf("strategy=%s\n", row[1]);
        if (row[2]) printf("weight=%s\n", row[2]);
        if (row[3]) printf("autofill=%s\n", row[3]);
        if (row[4]) printf("ringinuse=%s\n", row[4]);
        if (row[5]) printf("reportholdtime=%s\n", row[5]);
        if (row[6]) {
            get_file_name(row[6]);
            printf("announce=%s%s/%s\n", IVR_VOICE_PATH, row[36], row[6]);
        }
        if (row[7]) printf("memberdelay=%s\n", row[7]);
        if (row[8]) printf("timeout=%s\n", row[8]);
        if (row[9]) printf("retry=%s\n", row[9]);
        if (row[10]) printf("wrapuptime=%s\n", row[10]);
        if (row[11]) printf("maxlen=%s\n", row[11]);
        if (row[12]) {
            if (strcmp(row[12], "0") == 0) {
                printf("musicclass=default\n");
            } else {
                printf("musicclass=moh%s\n", row[12]);
            }
        }
        if (row[13]) if (strlen(row[13]) > 0) printf("joinempty=%s\n", row[13]);
        if (row[14]) if (strlen(row[14]) > 0) printf("leavewhenempty=%s\n", row[14]);
        if (row[35]) printf("context=ivr_block%s\n", row[35]);
        if (row[16]) printf("announce-frequency=%s\n", row[16]);
        if (row[17]) printf("min-announce-frequency=%s\n", row[17]);
        if (row[18]) printf("announce-position=%s\n", row[18]);
        if (row[19]) printf("announce-position-limit=%s\n", row[19]);
        if (row[20]) printf("announce-holdtime=%s\n", row[20]);
        if (row[21]) printf("announce-round-seconds=%s\n", row[21]);
        if (row[22]) printf("periodic-announce-frequency=%s\n", row[22]);
        if (row[23]) printf("random-periodic-announce=%s\n", row[23]);
        if (row[24]) printf("relative-periodic-announce=%s\n", row[24]);
        if (row[25]) printf("servicelevel=%s\n", row[25]);
        if (row[26]) printf("penaltymemberslimit=%s\n", row[26]);
        if (row[27]) printf("autopause=%s\n", row[27]);
        if (row[28]) printf("setinterfacevar=%s\n", row[28]);
        if (row[29]) printf("setqueueentryvar=%s\n", row[29]);
        if (row[30]) printf("setqueuevar=%s\n", row[30]);
        if (row[31]) printf("membermacro=%s\n", row[31]);
        if (row[32]) printf("membergosub=%s\n", row[32]);
        if (row[33]) printf("timeoutrestart=%s\n", row[33]);

        sprintf(announce_query, "SELECT ivr_sound_files.path, ivr_voices.voice FROM ivr_sound_files "
                                "INNER JOIN queue_periodic_announcements AS A ON A.ivr_sound_files_id = ivr_sound_files.id "
                                "INNER JOIN ivr_voices ON ivr_voices.id = ivr_sound_files.ivr_voice_id "
                                "WHERE A.queue_id = %s ORDER BY priority ASC", row[34]);

        if (mor_mysql_query(announce_query)) {
            mor_log("Empty result!\n");
            return 1;
        }

        // get queue_periodic_announcements result
        announce_result = mysql_store_result(&mysql);

        memset(announce_buffer, 0, 1024);
        while (( announce_row = mysql_fetch_row(announce_result) )) {
            get_file_name(announce_row[0]);
            sprintf(tmp_buffer, IVR_VOICE_PATH"%s/%s,", announce_row[1], announce_row[0]);
            strcat(announce_buffer, tmp_buffer);
        }

        if (strlen(announce_buffer) > 0) {
            announce_buffer[strlen(announce_buffer) - 1] = 0;
            printf("periodic-announce=%s\n", announce_buffer);
        }

        mysql_free_result(announce_result);

        sprintf(members_query, "SELECT devices.extension, penalty FROM queue_agents "
                               "INNER JOIN devices ON devices.id = queue_agents.device_id "
                               "WHERE queue_id = %s ORDER BY priority ASC", row[34]);

        if (mor_mysql_query(members_query)) {
            mor_log("Empty result!\n");
            return 1;
        }

        // get queue_agents result
        members_result = mysql_store_result(&mysql);

        while (( members_row = mysql_fetch_row(members_result) )) {
            printf("member => Local/%s@mor_local,%s\n", members_row[0], members_row[1]);
        }

        mysql_free_result(members_result);
        printf("\n");

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
