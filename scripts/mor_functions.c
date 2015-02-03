
#define _XOPEN_SOURCE      700

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mysql/mysql.h>
#include <mysql/errmsg.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <signal.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <inttypes.h>
#include <dirent.h>
#include <ctype.h>
#include <sys/time.h>

#define CONFPATH      "/var/lib/asterisk/agi-bin/mor.conf"
#define DATE_FORMAT   "%Y-%m-%d %H:%M:%S"
#define SCRIPT_PATH   "/usr/local/mor/"SCRIPT_NAME
#define LOG_PATH      "/var/log/mor/"SCRIPT_NAME".log"

// GLOBAL VARIABLES

// mysql variables
MYSQL mysql;
MYSQL *mysql_multi;

int mysql_reconnect_retries = 0;
int mysql_max_reconnects = 10;
int mysql_connections[8] = { 0 };
pthread_mutex_t mor_mysql_mutex = PTHREAD_MUTEX_INITIALIZER;

// configuration variables
char dbuser[64] = { 0 };
char dbpass[64] = { 0 };
char dbhost[64] = { 0 };
char dbname[64] = { 0 };
int dbport = 0;

// background tasks
int task_id = 0;

// FUNCTION DECLARATIONS

// nice log
#define mor_log(M, ...) {char mor_log_buffer[4096] = ""; sprintf(mor_log_buffer, M, ##__VA_ARGS__); _mor_log(mor_log_buffer, 0); mor_log_buffer[0] = 0;}
#define mor_log_header(M, ...) {char mor_log_buffer[4096] = ""; sprintf(mor_log_buffer, M, ##__VA_ARGS__); _mor_log(mor_log_buffer, 1); mor_log_buffer[0] = 0;}

// general functions
int mor_read_config();
void _mor_log(char *msg, int new_line);
int mor_check_process_lock();
int mor_mysql_connect();
int mor_mysql_connect_multi();
int mor_mysql_query_multi(const char *query, int *connection);
int mor_mysql_query(const char *query);
int mor_get_current_date(char *date);
int mor_compare_dates(char *date1, char *date2);
void mor_escape_string(char *string, char c);
void mor_init(char *header);
int mor_mysql_reconnect();

// for background tasks
int mor_task_get();
int mor_task_lock();
int mor_task_unlock(int status);
int mor_task_get(int task, int *user_id, char *data1, char *data2, char *data3, char *data4, char *data5, char *data6);
int mor_task_finish();


// FUNCTIONS


/*
    Read database configuration
*/


int mor_read_config() {

    FILE *file;
    char var[256] = "";
    char val[256] = "";

    file = fopen(CONFPATH, "r");

    if (!file) {
        mor_log("Cannot read configuration variables from: " CONFPATH "\n");
        return 1;
    }

    // default values
    strcpy(dbhost, "");
    strcpy(dbname, "");
    strcpy(dbuser, "");
    strcpy(dbpass, "");
    dbport = 0;

    // read values from conf file
    while (fscanf(file, "%s = %s", var, val) != EOF) {

        if (!strcmp(var, "host")) {
            strcpy(dbhost, val);
        }
        if (!strcmp(var, "db")) {
            strcpy(dbname, val);
        }
        if (!strcmp(var, "user")) {
            strcpy(dbuser, val);
        }
        if (!strcmp(var, "secret")) {
            strcpy(dbpass, val);
        }
        if (!strcmp(var, "port")) {
            dbport = atoi(val);
        }

    }

    // print db settings to log file
    mor_log("Database configuration: host = %s, database = %s, user = %s, port = %d\n", dbhost, dbname, dbuser, dbport);

    fclose(file);
    return 0;

}


/*
    Log messages to database with current timestamp
*/


void _mor_log(char *msg, int new_line) {

    if (strlen(msg) < 1) return;

    char date_str[20] = "";

    time_t t;
    struct tm tmp;
    t = time(NULL);
    localtime_r(&t, &tmp);
    strftime(date_str, sizeof(date_str), DATE_FORMAT, &tmp);

    // open log file
    FILE *logfile = fopen(LOG_PATH, "a+");

    if (logfile == NULL) {
        perror("error");
        printf("Cannot open " LOG_PATH "\n");
        exit(1);
    }

    if (new_line) {
        fprintf(logfile, "\n[%s] %s", date_str, msg);
    } else {

#ifdef LOG_TO_CONSOLE
        printf("%s\n", msg);
#endif
        fprintf(logfile, "[%s] %s", date_str, msg);
    }

    fclose(logfile);

}


/*
    Check for duplicate processes
*/


int mor_check_process_lock() {

#ifdef ALLOW_MULTIPLE
    return 0;
#endif

    char buffer[128] = "";
    char process_list[4096] = "";

    // count how many processes exists with the same path
    FILE *pipe = popen("ps -ef | grep -v grep | grep -v '/bin/sh -c' | grep -v launcher.sh | grep " SCRIPT_PATH " | wc -l", "r");
    fgets(buffer, 64, pipe);

        // count how many processes exists with the same path
    FILE *pipe_list = popen("ps -ef | grep -v grep | grep -v '/bin/sh -c' | grep -v launcher.sh | grep " SCRIPT_PATH, "r");
    fgets(process_list, 4094, pipe_list);

    // if more than one, exit current process
    if (atoi(buffer) > 1) {
        mor_log("Process locked!\n");
        mor_log("Found the following processes running:\n");
        mor_log("%s\n", process_list);
        fclose(pipe);
        fclose(pipe_list);
        return 1;
    }

    pclose(pipe);
    pclose(pipe_list);

    return 0;

}



int mor_get_connection() {

#ifdef MOR_SQL_CONNECTIONS

    // we are dealing with global variables so we should lock them
    pthread_mutex_lock(&mor_mysql_mutex);
    int connection = 0;
    // search for available connections
    while (mysql_connections[connection] == 1) {;
        connection++;
        if (connection >= MOR_SQL_CONNECTIONS) connection = 0;
    }
    // mark connection as busy
    mysql_connections[connection] = 1;
    pthread_mutex_unlock(&mor_mysql_mutex);

    return connection;

#else
    return 0;
#endif

}



/*
    Initialize MySQL connection
*/


int mor_mysql_connect_multi() {

#ifdef MOR_SQL_CONNECTIONS

    int i;

    // check if we have valid number connections
    if (MOR_SQL_CONNECTIONS > 0 && MOR_SQL_CONNECTIONS < 8) {

        mysql_multi = malloc(sizeof(MYSQL)*MOR_SQL_CONNECTIONS);

        for (i = 0; i < MOR_SQL_CONNECTIONS; i++) {

            if (!mysql_init(&mysql_multi[i])) {
                mor_log("%s\n", mysql_error(&mysql_multi[i]));
                return 1;
            }

            if (!mysql_real_connect(&mysql_multi[i], dbhost, dbuser, dbpass, dbname, dbport, NULL, 0)) {
                mor_log("%s\n", mysql_error(&mysql_multi[i]));
                return 1;
            }
        }
    } else {
        mor_log("MOR_SQL_CONNECTIONS is invalid! Accepted values are [1 8], but got value: %d\n", MOR_SQL_CONNECTIONS);
        mor_log("Aborting script...\n");
        exit(1);
    }

#endif

    return 0;

}

int mor_mysql_connect() {

    if (!mysql_init(&mysql)) {
        mor_log("%s\n", mysql_error(&mysql));
        return 1;
    }

    if (!mysql_real_connect(&mysql, dbhost, dbuser, dbpass, dbname, dbport, NULL, 0)) {
        mor_log("%s\n", mysql_error(&mysql));
        return 1;
    }

    return 0;

}


/*
    Handle MySQL queries
*/


int mor_mysql_query_multi(const char *query, int *connection) {

    *connection = mor_get_connection();

    if (mysql_query(&mysql_multi[*connection], query)) {
        mor_log("SQL ERROR: %s\n", mysql_error(&mysql_multi[*connection]));
        mor_log("SQL ERROR: %s\n", query);
        // mark connection as available
        mysql_connections[*connection] = 0;
        return 1;
    }

    return 0;

}

int mor_mysql_query(const char *query) {

    // try to send query
    // if query fails, log and report error
    if (mysql_query(&mysql, query)) {
        mor_log("SQL ERROR: %s\n", mysql_error(&mysql));
        mor_log("SQL ERROR: %s\n", query);
        return 1;
    } else {
        mysql_reconnect_retries = 0;
    }

    return 0;

}


/*
    Reconnect to MySQL
*/


int mor_mysql_reconnect() {

    int error = mysql_ping(&mysql);

    if (error) {

        int errno = mysql_errno(&mysql);

        switch (errno) {
            case CR_SERVER_GONE_ERROR:
                mor_log("Server has gone away. Attempting to reconnect (#%d)\n", mysql_reconnect_retries + 1);
                mysql_close(&mysql);
                mor_mysql_connect();
                break;
            case CR_SERVER_LOST:
                mor_log("Server lost. Attempting to reconnect (#%d)\n", mysql_reconnect_retries + 1);
                mysql_close(&mysql);
                mor_mysql_connect();
                break;
            default:
                mor_log("Unknown connection error: (%d) %s\n", errno, mysql_error(&mysql));
                exit(1);
        }

        mysql_reconnect_retries++;

        if (mysql_reconnect_retries >= mysql_max_reconnects) {
            mor_log("Retried to connect %d times, giving up...\n", mysql_max_reconnects);
            exit(1);
        }
    } else {
        exit(1);
    }

    return 0;
}


/*
    Get current hour/day/month or just date string
*/


int mor_get_current_date(char *date) {

    time_t t;
    struct tm tmp;
    t = time(NULL);
    localtime_r(&t, &tmp);
    char date_tmp[256] = "";

    if (date) {
        strftime(date_tmp, sizeof(date_tmp), DATE_FORMAT, &tmp);
        strcpy(date, date_tmp);
    }

    return 0;

}


/*
    Date compare function
*/


int mor_compare_dates(char *date1, char *date2) {

    time_t t1, t2;
    struct tm tm1, tm2;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(date1, DATE_FORMAT, &tm1);
    strptime(date2, DATE_FORMAT, &tm2);

    t1 = mktime(&tm1);
    t2 = mktime(&tm2);

    if (t1 > t2) return 1;

    return 0;

}


/*
    Function to escape characters in a string
        from: This is my brother's car
          to: This is my brother\'s car
*/


void mor_escape_string(char *string, char c) {

    int i;
    int len = strlen(string);

    if (!len) return;

    for (i = 0; i < len; i++) {
       if (string[i] == c) {
          memmove(string + i + 1, string + i, strlen(string + 1));
          string[i] = '\\';
          if (i < (len - 1)) i++;
       }
    }

}


/*
    Initialize M2 script
*/


void mor_init(char *header) {

    if (mor_check_process_lock()) exit(1);

    // starting sript
    mor_log_header(header);

#ifdef SCRIPT_VERSION
    mor_log("Script version: " SCRIPT_VERSION "\n");
#endif

    // get config and connect to database
    if (mor_read_config()) exit(1);
    if (mor_mysql_connect() == 1) exit(1);
#ifdef MOR_SQL_CONNECTIONS
    mor_log("Initializing %d MySQL connections\n", MOR_SQL_CONNECTIONS);
    if (mor_mysql_connect_multi() == 1) exit(1);
#endif

}


int mor_task_get(int task, int *user_id, char *data1, char *data2, char *data3, char *data4, char *data5, char *data6) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[1024] = "";
    int task_found = 0;

    sprintf(sqlcmd, "SELECT id, user_id, data1, data2, data3, data4, data5, data6 FROM background_tasks WHERE task_id = %d AND status = 1 ORDER BY created_at LIMIT 1", task);

    if (mor_mysql_query(sqlcmd)) {
        exit(1);
    } else {
        result = mysql_store_result(&mysql);
        if (result) {
            while ((row = mysql_fetch_row(result))) {
                task_found = 1;
                if (row[0]) task_id = atoi(row[0]);
                if (row[1] && user_id) *user_id = atoi(row[1]);
                if (row[2] && data1) strcpy(data1, row[2]);
                if (row[3] && data2) strcpy(data2, row[3]);
                if (row[4] && data3) strcpy(data3, row[4]);
                if (row[5] && data4) strcpy(data4, row[5]);
                if (row[6] && data5) strcpy(data5, row[6]);
                if (row[7] && data6) strcpy(data6, row[7]);
            }
        }

        mysql_free_result(result);

    }

    if (task_found == 0) {
        mor_log("Task not found!\n");
        exit(1);
    }

    mor_log("Task retrieved - id: %i, user_id: %i, data1: %s, data2: %s, data3: %s, data4: %s, data5: %s, data6: %s\n",
            task_id,
            user_id == NULL ? 0 : *user_id,
            data1 == NULL ? "NULL" : data1,
            data2 == NULL ? "NULL" : data2,
            data3 == NULL ? "NULL" : data3,
            data4 == NULL ? "NULL" : data4,
            data5 == NULL ? "NULL" : data5,
            data6 == NULL ? "NULL" : data6);

    return 0;
}


int mor_task_finish() {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd,"UPDATE background_tasks SET status = 2, finished_at = NOW(), expected_to_finish_at = NOW(), percent_completed = 100 WHERE id = %i", task_id);
    if (mor_mysql_query(sqlcmd)) exit(1);
    mor_log("Task finished\n");
    mor_task_unlock(3);
    return 0;

}


int mor_task_lock() {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd,"UPDATE background_tasks SET status = 2, started_at = NOW(), percent_completed = 0 WHERE id = %i", task_id);
    if (mor_mysql_query(sqlcmd)) exit(1);
    mor_log("Task locked\n");
    return 0;

}


/*
    Function to unlock task (change status)

    Status:

    1 - WAITING
    2 - IN PROGRESS
    3 - DONE
    4 - FAILED
*/


int mor_task_unlock(int status) {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd,"UPDATE background_tasks SET status = %i WHERE id = %i", status, task_id);
    if (mor_mysql_query(sqlcmd)) exit(1);
    mor_log("Task unlocked\n");
    return 0;

}
