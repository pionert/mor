// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script handles background task creation/execution

#define SCRIPT_VERSION  "1.0"
#define SCRIPT_NAME     "m2_background_tasks"

#include "mor_functions.c"

// path to background_scripts
#define PATH_TO_ARCHIVE_OLD_CALLS  "/usr/local/mor/mor_archive_old_calls"

// FUNCTION DECLARATIONS

void check_background_tasks();
int check_archive_old_calls();

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    mor_init("Starting MOR Background Tasks script\n");

    // check if any background task is in progress at the moment
    check_background_tasks();

    // check if mor_archive_old_calls script should be executed
    if (check_archive_old_calls() == 0) {
        mor_log("Executing script " PATH_TO_ARCHIVE_OLD_CALLS "\n");
        system(PATH_TO_ARCHIVE_OLD_CALLS);
        return 0;
    }

    return 0;
}


void check_background_tasks() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int active_tasks = 0;

    // count how many tasks are running
    if (mor_mysql_query("SELECT count(id) FROM background_tasks WHERE status = 'IN PROGRESS' AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)")) {
        exit(1);
    }

    result = mysql_store_result(&mysql);

    while ((row = mysql_fetch_row(result)) != NULL) {
        if (row[0]) active_tasks = atoi(row[0]);
    }

    mysql_free_result(result);

    if (active_tasks > 0) {
        mor_log("There are recent active background tasks (%d). Scripts will not be executed...\n", active_tasks);
        exit(1);
    }

}

// check if archive_old_calls script should be executed

int check_archive_old_calls() {

    mor_log("Checking Archive old calls...\n");

    MYSQL_RES *result;
    MYSQL_ROW row;
    char buffer[1024] = "";
    int older_than = 0;
    int archive_at_h = -1;
    int archive_at_m = -1;
    int archive_till_h = -1;
    int archive_till_m = -1;
    int waiting_tasks = 0;
    int active_tasks = 0;
    int recently_finished = 0;
    char current_date[20] = "";
    char current_time[20] = "";

    // get current time
    mor_get_current_date(current_date);
    strncpy(current_time, current_date + 11, 8);

    // get older_than and archive_at values
    if (mor_mysql_query("SELECT name, value FROM conflines WHERE name = 'Move_to_old_calls_older_than' OR name = 'Archive_at' OR name = 'Archive_till'")) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    // fetch data
    while ((row = mysql_fetch_row(result)) != NULL) {

        if (row[0] && row[1]) {
            if (strcmp(row[0], "Move_to_old_calls_older_than") == 0) {
                older_than = atoi(row[1]);
            }
        }

        if (row[0] && row[1]) {

            if (strcmp(row[0], "-1") != 0 && strcmp(row[1], "-1") != 0 ) {

                if (strcmp(row[0], "Archive_at") == 0) {
                    char buffer[64] = "";
                    strncpy(buffer, row[1], 2);
                    archive_at_h = atoi(buffer);
                    strncpy(buffer, row[1] + 3, 2);
                    archive_at_m = atoi(buffer);
                }

            }

        }

        if (row[0] && row[1]) {

            if (strcmp(row[0], "-1") != 0 && strcmp(row[1], "-1") != 0 ) {

                if (strcmp(row[0], "Archive_till") == 0) {
                    char buffer[64] = "";
                    strncpy(buffer, row[1], 2);
                    archive_till_h = atoi(buffer);
                    strncpy(buffer, row[1] + 3, 2);
                    archive_till_m = atoi(buffer);
                }

            }
        }

    }

    mysql_free_result(result);

    if (archive_at_h == -1) {
        mor_log("[mor_archive_old_calls] Archive_at = -1. Scripts will not be executed...\n");
        return 1;
    }

    if (older_than == 0) {
        mor_log("[mor_archive_old_calls] Move_to_old_calls_older_than = 0. Scripts will not be executed...\n");
        return 1;
    }

    char hour[3] = "00";
    char minute[3] = "00";
    char minute2[3] = "00";

    if (archive_at_h > 9) {
        sprintf(hour, "%d", archive_at_h);
    } else {
        sprintf(hour, "0%d", archive_at_h);
    }

    if (archive_at_m > 9) {
        sprintf(minute, "%d", archive_at_m);
    } else {
        sprintf(minute, "0%d", archive_at_m);
    }

    if (archive_at_m + 5 > 9) {
        sprintf(minute2, "%d", archive_at_m + 5);
    } else {
        sprintf(minute2, "0%d", archive_at_m + 5);
    }

    // check if current time is between 'archive_at' and 'archive_at' + 5 min
    time_t rawtime = 0, current_time_seconds = 0, limit_time_seconds = 0;
    long long int time_diff = 0;
    struct tm tmmm, tmmm2;
    char time_buffer[20] = "";
    char date_buffer1[20] = "";
    char date_buffer2[20] = "";
    mor_get_current_date(date_buffer1);
    sprintf(time_buffer, "%s:%s:00", hour, minute);
    strncpy(date_buffer1 + 11, time_buffer, 8);
    time(&rawtime);
    localtime_r(&rawtime, &tmmm);
    strptime(date_buffer1, "%Y-%m-%d %H:%M:%S", &tmmm);
    limit_time_seconds = mktime(&tmmm) + 300;
    time(&current_time_seconds);
    time_diff = limit_time_seconds - current_time_seconds;
    localtime_r(&limit_time_seconds, &tmmm2);
    strftime(date_buffer2, 20, "%Y-%m-%d %H:%M:%S", &tmmm2);

    if (time_diff < 0 || time_diff > 300) {
        mor_log("[mor_archive_old_calls] Script can only be executed between %s and %s. Current time is: %s\n", date_buffer1 + 11, date_buffer2 + 11, current_time);
        return 1;

    }

    // check if tasks exist
    if (mor_mysql_query("SELECT (SELECT count(id) FROM background_tasks WHERE task_id = 2 AND status = 'WAITING'), (SELECT count(id) FROM background_tasks WHERE task_id = 2 AND status = 'IN PROGRESS' AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR))")) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    // fetch data
    while ((row = mysql_fetch_row(result)) != NULL) {
        if (row[0]) waiting_tasks = atoi(row[0]);
        if (row[1]) active_tasks  = atoi(row[1]);
    }

    mysql_free_result(result);

    if (active_tasks > 0) {
        mor_log("[mor_archive_old_calls] Active_tasks = %d. Scripts will not be executed...\n", active_tasks);
        return 1;
    }

    if (waiting_tasks > 0) {
        mor_log("[mor_archive_old_calls] Waiting_tasks = %d\n", waiting_tasks);
        return 0;
    }

    // check if task was created recently
    if (mor_mysql_query("SELECT count(id) FROM background_tasks WHERE task_id = 2 AND created_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)")) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    // fetch data
    while ((row = mysql_fetch_row(result)) != NULL) {
        if (row[0]) recently_finished = atoi(row[0]);
    }

    mysql_free_result(result);

    if (recently_finished) {
        mor_log("[mor_archive_old_calls] Another task can not be executed within 5 minutes. Scripts will not be executed...\n");
        return 1;
    }

    char buffer2[64] = "-1:00";
    if (archive_till_h > -1) {
        char hour[3] = "00";
        char minute[3] = "00";

        if (archive_till_h > 9) {
            sprintf(hour, "%d", archive_till_h);
        } else {
            sprintf(hour, "0%d", archive_till_h);
        }

        if (archive_till_m > 9) {
            sprintf(minute, "%d", archive_till_m);
        } else {
            sprintf(minute, "0%d", archive_till_m);
        }

        sprintf(buffer2, "%s:%s", hour, minute);
    }

    // there are no waiting or active tasks, let's create a new one
    sprintf(buffer, "INSERT INTO background_tasks(created_at, task_id, status, data1) VALUES('%s', 2, 'WAITING', '%s')", current_date, buffer2);
    mor_log("[mor_archive_old_calls] Creating task: %s\n", buffer);
    if (mor_mysql_query(buffer)) {
        return 1;
    }

    return 0;

}
