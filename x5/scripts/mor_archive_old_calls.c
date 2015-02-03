// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2012
// About:         Script moves records from one table to another

#define SCRIPT_VERSION      "1.2"
#define SCRIPT_NAME         "mor_archive_old_calls"
#define SKIPPED_RECORDS     "/tmp/mor_archive_old_calls_skipped_records.sql"
#define IDS_BUFFER_SIZE     BATCH_SIZE*20 + 256
#define DATA_INFILE_PATH    "/tmp/mor_records_old_table.txt"
#define SQL_LIMIT           1000
#define BATCH_SIZE          250
#define PROGRESS_TIMER      1
#define MOR_SQL_CONNECTIONS 2   // use multiple sql connections

#include "mor_functions.c"

// VARIABLES

// SQL variables
char sql_file_buffer[2048] = "";
char sql_delete_statement[64] = "";
char sql_count_statement[64] = "";
char buffer[4096] = "";
long long unsigned int total_records = 0;
long long unsigned int transfered_records = 0;

// call ids stored in array for future deletion
char ids_buffer[IDS_BUFFER_SIZE] = "";
char check_ids_buffer[IDS_BUFFER_SIZE] = "";
long long unsigned int ids[SQL_LIMIT] = { 0 };

// list of column names
char colnames[4096] = "";
char colnames_table_name[4096] = "";
int colnames_count = 0;

// task variables
int time_limit_h = 0;
int time_limit_m = 0;
int task_failed = 0;
int forced_stop = 0;
int finished = 1;
int time_started_h = 0;
int time_started_m = 0;

// other variables
int older_than = 0;
long long int time_limit_seconds = 0;
char datetime[20] = "";

int DEBUG_PROGRESS = 0;

// FUNCTION DECLARATIONS

void *set_timer();
void my_strcat(char *str1, char *str2);
int delete_records_from_database(int records);
int get_records_from_database(FILE *infile, int *records, int *done, char *db_from, char *condition);
void error_handle();
int transfer_records(char *db_from, char *db_to, char *condition);

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char condition[512] = "";

    // initialize thread attributes
    pthread_t timer;
    pthread_attr_t tattr;
    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_DETACHED);

    // mark task as failed on segmentation fault
    struct sigaction sa;
    memset(&sa, 0, sizeof(struct sigaction));
    sigemptyset(&sa.sa_mask);
    sa.sa_sigaction = error_handle;
    sa.sa_flags = SA_SIGINFO;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    atexit(error_handle);

    // check if debug is ON
    if (argc > 1) {
        if(strcmp(argv[1], "--debug") == 0) {
            DEBUG_PROGRESS = 1;
        }
    }

    // starting the script
    mor_init("Starting 'MOR X5 Archive Old Calls' script\n");

    struct tm tmm;
    strptime(datetime, DATE_FORMAT, &tmm);

    time_started_h = tmm.tm_hour;
    time_started_m = tmm.tm_min;

    char time_limit_str[256] = "";

    if (mor_task_get(2, NULL, time_limit_str, NULL, NULL, NULL, NULL, NULL)) {
        return 1;
    }

    // parse hours and minutes
    if (strlen(time_limit_str)) {
        char buffer[64] = "";
        strncpy(buffer, time_limit_str, 2);
        time_limit_h = atoi(buffer);
        strncpy(buffer, time_limit_str + 3, 2);
        time_limit_m = atoi(buffer);
    }

    task_failed = 1;

    mor_log("Reading conflines\n");

    // get Move_to_old_calls_older_than value
    if (mor_mysql_query("SELECT value FROM conflines WHERE name='Move_to_old_calls_older_than'")) {
        return 1;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            // check if we get result
            if (row[0]) {
                older_than = atoi(row[0]);
            } else {
                mor_log("Move_to_old_calls_older_than is not set\n");
                return 1;
            }
        }
    }

    // nothing to do
    if (older_than == 0) {
        mor_log("Move_to_old_calls_older_than is 0\n");
        return 0;
    }

    mysql_free_result(result);

    if (!(time_limit_h <= 24 || time_limit_h >= -1)) {
        mor_log("Time limit must be between -1 and 24\n");
        return 1;
    }

    if (!(time_limit_m <= 59 || time_limit_m >= -1)) {
        mor_log("Time limit must be between -1 and 59\n");
        return 1;
    }

    // convert time limit to second
    // (archive_till - archive_at) * 360
    if (time_started_h <= time_limit_h) {
        time_limit_seconds = (time_limit_h * 3600 + time_limit_m * 60) - (time_started_h * 3600 + time_started_m * 60);
    } else {
        time_limit_seconds = 24*3600 - (time_started_h * 3600 + time_started_m * 60) + (time_limit_h * 3600 + time_limit_m * 60);
    }

    mor_log("Transfering calls older then %d days\n", older_than);

    // mark as 'IN PROGRESS'
    mor_task_lock();

    pthread_create(&timer, &tattr, set_timer, NULL);

    sprintf(condition, "WHERE calldate < DATE_SUB(NOW(), INTERVAL %d DAY)", older_than);
    if (transfer_records("calls", "calls_old", condition)) {
        return 1;
    }

    sprintf(condition, "JOIN calls_old ON calls_old.id = call_details.call_id WHERE calldate < DATE_SUB(NOW(), INTERVAL %d DAY)", older_than);
    if (transfer_records("call_details", "call_details_old", condition)) {
        return 1;
    }

    if (total_records == 0) {
        mor_log("Nothing to transfer...\n");
    }

    task_failed = 0;

    // terminate timer
    pthread_cancel(timer);
    pthread_attr_destroy(&tattr);

    if (finished && forced_stop == 0) mor_task_finish();
    if (finished && forced_stop == 1) mor_task_unlock(3);

    int i;

    for (i = 0; i < MOR_SQL_CONNECTIONS; i++) {
        mysql_close(&mysql_multi[i]);
    }

    mysql_close(&mysql);
    mysql_library_end();

    task_failed = 0;

    return 0;
}

int get_records_from_database(FILE *infile, int *records, int *done, char *db_from, char *condition) {

    int i = 0;
    MYSQL_RES *result;
    MYSQL_ROW row;

    // get records according to condition
    sprintf(buffer, "SELECT %s FROM %s %s LIMIT %d", colnames_table_name, db_from, condition, SQL_LIMIT);

    if (mor_mysql_query(buffer)) {
        exit(1);
    }

    result = mysql_store_result(&mysql);

    // format sql data file
    while ((row = mysql_fetch_row(result)) != NULL) {
        *done = 0;
        // get each field
        for(i = 0; i < colnames_count; i++) {
            if(row[i]) {
                my_strcat(sql_file_buffer, row[i]);
            } else {
                my_strcat(sql_file_buffer, "NULL");
            }
        }
        sql_file_buffer[strlen(sql_file_buffer) - 1] = 0;
        // write to data infile
        fprintf(infile, "%s\n", sql_file_buffer);
        // reset buffer
        *sql_file_buffer = 0;
        // save ids
        ids[*records] = atoll(row[0]);
        *records = *records + 1;
    }

    mysql_free_result(result);

    return 0;
}

int delete_records_from_database(int records) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int i = 0;
    int batch_counter = 0;

    // initialize ids_buffer
    strcpy(ids_buffer, sql_delete_statement);
    strcpy(check_ids_buffer, sql_count_statement);
    long long unsigned int check_records = 0;

    // delete from 'db_from' table
    for (i = 0; i < records; i++) {

        sprintf(buffer, "%llu,", ids[i]);
        strcat(ids_buffer, buffer);
        strcat(check_ids_buffer, buffer);
        batch_counter++;

        // batch is full, send query
        if (batch_counter == BATCH_SIZE) {

            ids_buffer[strlen(ids_buffer) - 1] = 0;
            check_ids_buffer[strlen(check_ids_buffer) - 1] = 0;
            strcat(ids_buffer, ");");
            strcat(check_ids_buffer, ");");

            if (mor_mysql_query(ids_buffer)) {
                exit(1);
            }

            // check if records with those ids are delete
            if (mor_mysql_query(check_ids_buffer)) {
                exit(1);
            }

            check_records = -1;

            result = mysql_store_result(&mysql);
            if (result) {
                if (mysql_num_rows(result)) {
                    row = mysql_fetch_row(result);
                    if (row[0]) check_records = atoll(row[0]);
                }
            }

            mysql_free_result(result);

            if (check_records == -1) {
                mor_log("Can't determine if records where deleted correctly\n");
                mor_log("%s\n", check_ids_buffer);
                return 1;
            } else if (check_records) {
                mor_log("Tried to delete %d records, but there are still %llu records left. Check why some records where not deleted!\n", BATCH_SIZE, check_records);
                mor_log("%s\n", check_ids_buffer);
                return 1;
            }

            *ids_buffer = 0;
            *check_ids_buffer = 0;
            strcpy(ids_buffer, sql_delete_statement);
            strcpy(check_ids_buffer, sql_count_statement);
            batch_counter = 0;

        }
    }

    // if batch is not full, send query anyway
    if (strlen(ids_buffer) > strlen(sql_delete_statement)) {
        ids_buffer[strlen(ids_buffer) - 1] = 0;
        strcat(ids_buffer, ")");
        if (mysql_query(&mysql, ids_buffer)) {
            mor_log("%s", mysql_error(&mysql));
            return 1;
        }
    }

    return 0;
}

void calculate_expected_time(char *datetime, int seconds) {

    time_t t;
    struct tm tmp;
    char tmp_str[100];

    t = time(NULL) + seconds;
    localtime_r(&t, &tmp);

    strftime(tmp_str, sizeof(tmp_str), DATE_FORMAT, &tmp);
    strcpy(datetime, tmp_str);

}

void check_time_limit() {

    char datetime[20] = "";
    char time_limit_buffer1[10] = "";
    char time_limit_buffer2[10] = "";
    int i = 0;
    int stop_h = 1;
    int stop_m = 1;

    if (time_limit_h > -1) {

        if (time_limit_h < 10) {
            sprintf(time_limit_buffer1, "0%d", time_limit_h);
        } else {
            sprintf(time_limit_buffer1, "%d", time_limit_h);
        }

        if (time_limit_m < 10) {
            sprintf(time_limit_buffer2, "0%d", time_limit_m);
        } else {
            sprintf(time_limit_buffer2, "%d", time_limit_m);
        }

        mor_get_current_date(datetime);

        for (i = 0; i < 2; i++) {
            if (datetime[i + 11] != time_limit_buffer1[i]) stop_h = 0;
        }

        for (i = 0; i < 2; i++) {
            if (datetime[i + 14] != time_limit_buffer2[i]) stop_m = 0;
        }

        if (stop_h && stop_m) forced_stop = 1;

    }
}

int is_date(char *date) {

    int i = 0;

    if (strlen(date) != 19) return 0;

    for (i = 0; i < 19; i++) {
        if (i == 4 || i == 7 || i == 10 || i == 13 || i == 16) continue;
        if (date[i] > '9' || date[i] < '0') {
            return 0;
        }
    }

    return 1;
}

void *set_timer() {

    long long int counter = 0;
    long long int time_left = 0;
    double records_per_sec = 0;
    double progress_percent = 0;
    char datetime[20] = "";
    char progress_buffer[1024] = "";
    int connection = 0;

    if (DEBUG_PROGRESS && total_records > 0) {
        printf("--------------------------------------------------------------------------------\n");
        printf("     Progress    | Completed | Calls per sec | Time left | Expected to finish at\n");
        printf("--------------------------------------------------------------------------------\n");
    }

    while (1) {
        sleep(PROGRESS_TIMER);
        counter++;

        if (transfered_records > 0) {
            progress_percent = (double)((double)transfered_records/total_records)*100;
            records_per_sec = (double)transfered_records/counter;
            time_left = ceil((double)(total_records - transfered_records) / records_per_sec);
        } else {
            progress_percent = 0;
            records_per_sec = 0;
            time_left = 9999;
        }

        if (time_limit_seconds < time_left) {
            calculate_expected_time(datetime, time_limit_seconds);
        } else {
            calculate_expected_time(datetime, time_left);
        }

        if (!is_date(datetime)) {
            strcpy(datetime, "0000-00-00 00:00:00");
        }

        // mor_mysql_query_multi is used here to have another sql connection
        // we are doing queries in a thread, so another sql connection is required to prevent crashes
        sprintf(progress_buffer, "UPDATE background_tasks SET percent_completed = %.3f, expected_to_finish_at = '%s' WHERE id = %i", progress_percent, datetime, task_id);
        if (mor_mysql_query_multi(progress_buffer, &connection)) {
            mor_log("Query failed: %s\n", progress_buffer);
        }

        // free connection
        mysql_connections[connection] = 0;

        if (DEBUG_PROGRESS) printf(" %07lld/%07lld | %6.2f %%  |  %9.2f    | %4lld sec  |  %s\n", transfered_records, total_records, progress_percent, records_per_sec, time_left, datetime);

        // check if we should stop this script due to time limit
        check_time_limit();

        time_limit_seconds -= 1;
        if (time_limit_seconds < 0) time_limit_seconds = 0;
    }

    pthread_exit(NULL);
}

void my_strcat(char *str1, char *str2) {
    strcat(str1, "\"");
    strcat(str1, str2);
    strcat(str1, "\"");
    strcat(str1, ",");
}

void error_handle() {
    static int marked = 0;

    if (marked == 0) {
        if(task_failed) {
            if (!DEBUG_PROGRESS) mor_task_unlock(4);
            mor_log("Task failed\n");
        }
        marked = 1;
    }

    forced_stop = 1;
    finished = 0;
}

int transfer_records(char *db_from, char *db_to, char *condition) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[4096] = "";
    long long unsigned int records_old_total1 = 0;
    long long unsigned int records_old_total2 = 0;
    long long unsigned int local_total_records = 0;
    int records = 0;
    int done = 0;

    // initialize buffers
    memset(sql_file_buffer, 0, sizeof(sql_file_buffer));
    sprintf(sql_delete_statement, "DELETE FROM %s WHERE id IN (", db_from);
    sprintf(sql_count_statement, "SELECT COUNT(id) FROM %s WHERE id IN (", db_from);
    memset(ids_buffer, 0, sizeof(ids_buffer));
    memset(check_ids_buffer, 0, sizeof(check_ids_buffer));
    memset(ids, 0, sizeof(ids));
    memset(colnames, 0, sizeof(colnames));
    memset(colnames_table_name, 0, sizeof(colnames_table_name));
    colnames_count = 0;

    // get collumn names from 'db_from' table that matches 'db_to' table columns
    sprintf(sqlcmd, "SELECT DISTINCT column_name FROM information_schema.columns WHERE table_name = '%s' AND column_name IN (SELECT DISTINCT column_name FROM information_schema.columns WHERE table_name = '%s')", db_from, db_to);
    if (mor_mysql_query(sqlcmd)) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    // construct string from column names like 'id,calldate,dst....'
    while ((row = mysql_fetch_row(result)) != NULL) {
        char tmp_buffer[256] = "";
        sprintf(tmp_buffer, "%s.%s", db_from, row[0]);
        strcat(colnames, row[0]);
        strcat(colnames_table_name, tmp_buffer);
        strcat(colnames, ",");
        strcat(colnames_table_name, ",");
        colnames_count++;
    }
    colnames[strlen(colnames) - 1] = 0;
    colnames_table_name[strlen(colnames_table_name) - 1] = 0;

    mysql_free_result(result);

    if (DEBUG_PROGRESS) {
        sprintf(buffer, "LOAD DATA LOCAL INFILE '" DATA_INFILE_PATH "' INTO TABLE %s FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n' (%s);", db_to, colnames);
        mor_log("%s\n", buffer);
        printf("%s\n", buffer);
        exit(0);
    }

    sprintf(buffer, "SELECT count(*) FROM %s %s", db_from, condition);
    mor_log("%s\n", buffer);

    if (mor_mysql_query(buffer)) {
        return 1;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) {
                local_total_records = atoll(row[0]);
            }
        }
    }

    mysql_free_result(result);

    if (local_total_records == 0) {
        mor_log("No records found in table %s\n", db_from);
        return 0;
    }

    total_records += local_total_records;

    mor_log("%llu records will be transfered from %s to %s table\n", local_total_records, db_from, db_to);
    mor_log("Starting transfer...\n");

    // count records from 'db_to' table
    sprintf(sqlcmd, "SELECT count(*) FROM %s", db_to);
    if (mor_mysql_query(sqlcmd)) {
        exit(1);
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) records_old_total1 = atoll(row[0]);
        }
    }

    mysql_free_result(result);

    while (done == 0 && forced_stop == 0) {

        // delete old file
        unlink(DATA_INFILE_PATH);

        // MySQL DATA INFILE
        FILE *infile = fopen(DATA_INFILE_PATH, "w");

        if (infile == NULL) {
            fprintf(stderr, "Cannot open: " DATA_INFILE_PATH "\n");
            mor_log("Cannot create: " DATA_INFILE_PATH "\n");
            exit(1);
        }

        // default state is 'done'
        done = 1;
        // reset records
        records = 0;

        // get records from database and prepare data to be imported to another database
        if (get_records_from_database(infile, &records, &done, db_from, condition)) return 1;

        fclose(infile);

        if (done) {
            // remove data file
            unlink(DATA_INFILE_PATH);
            // job is done
            break;
        }

        // insert records using data infile
        sprintf(sqlcmd, "LOAD DATA LOCAL INFILE '" DATA_INFILE_PATH "' INTO TABLE %s FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' (%s);", db_to, colnames);
        if (mor_mysql_query(sqlcmd)) {
            exit(1);
        }

        // get the number of skipped records

        char skipped_buffer[512] = "";
        int skipped_records = 0;
        char tmp_buffer[128] = "";

        strcpy(skipped_buffer, mysql_info(&mysql));

        if (strstr(skipped_buffer, "Skipped")) {
            int i = 0;
            char *poz = strstr(skipped_buffer, "Skipped") + 9;
            int min = 128;
            if (strlen(poz) < 128) min = strlen(poz);
            for (i = 0; i < min; i++) {
                if (isdigit(poz[i])) {
                    tmp_buffer[i] = poz[i];
                } else {
                    break;
                }
            }
        }

        skipped_records = atoi(tmp_buffer);

        // count records from 'db_to' table and calculate difference
        sprintf(sqlcmd, "SELECT count(*) FROM %s", db_to);
        if (mor_mysql_query(sqlcmd)) {
            exit(1);
        }

        result = mysql_store_result(&mysql);
        if (result) {
            if (mysql_num_rows(result)) {
                row = mysql_fetch_row(result);
                if (row[0]) records_old_total2 = atoll(row[0]);
            }
        }

        mysql_free_result(result);

        int records_diff = SQL_LIMIT;

        if (records < SQL_LIMIT) {
            records_diff = records;
        }

        if (records_old_total2 - records_old_total1 != records_diff) {
            char buffer[1024] = "";
            mor_log("Some records could not be inserted into table '%s'. Check " SKIPPED_RECORDS " query. Records before insert: %llu, records after insert: %llu, tried to insert records: %d, skipped records: %d\n", db_to, records_old_total1, records_old_total2, records, skipped_records);
            sprintf(buffer, "echo '\n-- %s\n' >> " SKIPPED_RECORDS " && cat " DATA_INFILE_PATH " >> " SKIPPED_RECORDS, datetime);
            FILE *tmp = popen(buffer, "r");
            if (tmp == NULL) {
                mor_log("Failed to: cat " DATA_INFILE_PATH " >> " SKIPPED_RECORDS "\n");
            }
            if ((records_old_total2 + skipped_records) - records_old_total1 != records_diff) {
                mor_log("Something is wrong, aborting script...\n");
            }
            pclose(tmp);
            exit(1);
        }

        records_old_total1 = records_old_total2;

        // remove temporary data file
        unlink(DATA_INFILE_PATH);

        // delete records from database
        if (delete_records_from_database(records)) return 1;

        transfered_records += records;
    }

    return 0;

}
