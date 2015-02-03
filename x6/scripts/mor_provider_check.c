// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script checks provider availability

#define _XOPEN_SOURCE 700

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mysql/mysql.h>
#include <unistd.h>
#include <time.h>
#include <pthread.h>

// DEFINITIONS

// database config path
#define SERVERCONFPATH "/etc/asterisk/mor.conf"
#define CONFPATH       "/var/lib/asterisk/agi-bin/mor.conf"
#define LOG_FILE       "/var/log/mor/provider_check.log"
#define TMP_FILE       "/tmp/mor_provider_check.txt"
#define DATE_FORMAT    "%Y-%m-%d %H:%M:%S"
#define SIPSAK_TIMEOUT 5

// FUNCTION DECLARATIONS

int db_connect(MYSQL *mysql, const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag);
int read_config();
int get_providers();
int mor_mysql_query(MYSQL *mysql, char *query, int fetch);
void mor_log(const char *msg, int new_line);
int check_process_lock();
int check_provider_status(int id);
int update_provider_status(int id, int status);
int get_server_id(const char *path);
void *check_provider_status_thread(void *arg);
void *timeout_thread();

// GLOBAL VARIABLES

// mysql variables
MYSQL mysql;
MYSQL_RES *result;
MYSQL_ROW row;

// configuration variables
char dbuser[64] = { 0 };
char dbpass[64] = { 0 };
char dbhost[64] = { 0 };
char dbname[64] = { 0 };
int dbport = 0;

typedef struct providers_struct {
    int id;
    char server_ip[128];
    int port;
} providers_t;

providers_t *prov;
int prov_count = 0;

int server_id = 0;

int prov_status = 0;

pthread_t timeout;
pthread_t pcheck;

// MAIN FUNCTION

int main() {

    // create thread as 'joinable'
    pthread_attr_t tattr;
    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_JOINABLE);

    // set thread cancel state and type
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL);

    int i = 0;
    char buffer[1024] = "";

    if (check_process_lock()) exit(1);

    // read database configuration
    if (read_config()) {
        exit(1);
    }

    // connect to database
    if (db_connect(&mysql, dbhost, dbuser, dbpass, dbname, dbport, NULL, 0) == 1) {
        exit(1);
    }

    // try another location
    if (get_server_id(SERVERCONFPATH)) {
        mor_log("Cannot read server configuration from: " SERVERCONFPATH " or server_id is not set", 0);
        exit(1);
    }

    // just to be sure
    if (server_id == 0) {
        mor_log("server_id is not set", 0);
        exit(1);
    }

    // starting sript
    mor_log("Starting Provider Check script", 1);

    // get provider data
    mor_log("Fetching provider data from database", 0);
    if (get_providers()) {
        exit(1);
    }

    if (prov_count == 0) {
        mor_log("No suitable providers were found", 0);
        exit(1);
    }

    mor_log("Checking provider availability", 0);
    for (i = 0; i < prov_count; i++) {

        prov_status = 0;

        pthread_create(&timeout, &tattr, timeout_thread, NULL);
        pthread_create(&pcheck, NULL, check_provider_status_thread, (void *)(intptr_t)i);
        pthread_join(timeout, NULL);

        if (prov_status == 0) {
            printf("Updating provider: [%d] %s:%d ALIVE = 0\n", prov[i].id, prov[i].server_ip, prov[i].port);
            sprintf(buffer, "Updating provider: [%d] %s:%d ALIVE = 0", prov[i].id, prov[i].server_ip, prov[i].port);
            mor_log(buffer, 0);
            if (update_provider_status(i, 0)) {
                exit(1);
            }
        } else {
            printf("Updating provider: [%d] %s:%d ALIVE = 1\n", prov[i].id, prov[i].server_ip, prov[i].port);
            sprintf(buffer, "Updating provider: [%d] %s:%d ALIVE = 1", prov[i].id, prov[i].server_ip, prov[i].port);
            mor_log(buffer, 0);
            if (update_provider_status(i, 1)) {
                exit(1);
            }
        }

    }

    unlink(TMP_FILE);

    return 0;

}

// read database configuration

int read_config() {

    FILE *file;
    char var[256] = "";
    char val[256] = "";

    file = fopen(CONFPATH, "r");

    if (!file) {
        mor_log("Cannot read configuration variables from: " CONFPATH "\n", 0);
        return 1;
    }

    // default values
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;

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

    fclose(file);

    return 0;

}

// connecto to MySQL

int db_connect(MYSQL *mysql, const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag) {

    char log_buffer[1024] = "";

    if (!mysql_init(mysql)) {
        sprintf(log_buffer, "MySQL error: %s", mysql_error(mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    if (!mysql_real_connect(mysql, host, user, pass, db, port, socket, cflag)) {
        sprintf(log_buffer, "MySQL error: %s", mysql_error(mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    return 0;

}

// process query and handle errors

int mor_mysql_query(MYSQL *mysql, char *query, int fetch) {

    char log_buffer[1024] = "";

    if (mysql_query(mysql, query)) {
        sprintf(log_buffer, "MySQL query cannot be sent to database: %s", mysql_error(mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    result = mysql_store_result(mysql);

    if (result == NULL) {
        sprintf(log_buffer, "mysql_store_result error: %s", mysql_error(mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    if (fetch) {
        if ((row = mysql_fetch_row(result)) == NULL) {
            sprintf(log_buffer, "MySQL returned an empty result set");
            mor_log(log_buffer, 0);
            return 1;
        }
    }

    return 0;

}

// get provider data from database

int get_providers() {

    // get all providers that are checked for monitoring
    char sqlcmd[2048] = "";
    sprintf(sqlcmd, "SELECT providers.id, providers.server_ip, providers.port FROM providers JOIN devices ON devices.id = providers.device_id WHERE providers.periodic_check = 1 AND devices.server_id = %d AND providers.server_ip != 'dynamic' AND providers.hidden = 0 AND tech = 'SIP'", server_id);
    if (mor_mysql_query(&mysql, sqlcmd, 0)) {
        return 1;
    }

    while ((row = mysql_fetch_row(result)) != NULL) {

        if (row[0] && row[1] && row[2]) {

            prov = realloc(prov, (prov_count + 1) * sizeof(providers_t));
            prov[prov_count].id = atoi(row[0]);
            prov[prov_count].port = atoi(row[2]);
            strcpy(prov[prov_count].server_ip, row[1]);
            prov_count++;

        }

    }

    mysql_free_result(result);

    return 0;

}

// log messages to file

void mor_log(const char *msg, int new_line) {

    time_t t;
    struct tm tmp;
    char date_str[100];

    t = time(NULL);
    localtime_r(&t, &tmp);

    strftime(date_str, sizeof(date_str), DATE_FORMAT, &tmp);

    // open log file
    FILE *logfile = fopen(LOG_FILE, "a+");

    if (logfile == NULL) {
        printf("Cannot open " LOG_FILE "\n");
        exit(1);
    }

    if (new_line) {
        fprintf(logfile, "\n[%s] %s\n", date_str, msg);
    } else {
        fprintf(logfile, "[%s] %s\n", date_str, msg);
    }

    fclose(logfile);

}

// check for duplicate processes

int check_process_lock() {

    char buffer[128] = { 0 };

    FILE *pipe = popen("ps -ef | grep -v grep | grep /usr/local/mor/mor_provider_check | wc -l", "r");
    fgets(buffer, 64, pipe);

    if (atoi(buffer) > 1) {
        printf("[mor_provider_check] Process locked!\n");
        mor_log("Process locked!", 0);
        fclose(pipe);
        return 1;
    }

    pclose(pipe);

    return 0;

}

int check_provider_status(int id) {

    int i = 0;
    char buffer[64] = "";
    char cmd[1024] = "";
    FILE *pipe = NULL;

    sprintf(cmd, "echo '' > " TMP_FILE " && sipsak -H localhost -s sip:101@%s:%d -v > " TMP_FILE, prov[id].server_ip, prov[id].port);

    pipe = popen(cmd, "r");

    if (pipe == NULL) {
        return 1;
    }

    for (i = 0; i < SIPSAK_TIMEOUT*2; i++) {

        struct timespec time1, time2;

        time1.tv_sec  = 0;
        time1.tv_nsec = 500000000L;

        nanosleep(&time1 , &time2);

        long int size = 0;
        FILE *tmp_file = fopen(TMP_FILE, "r");

        if (tmp_file == NULL) {
            mor_log("Cannot open " TMP_FILE, 0);
            return 1;
        }

        fseek(tmp_file, 0L, SEEK_END);
        size = ftell(tmp_file);
        pclose(tmp_file);

        if (size > 3) {
            pclose(pipe);

            pipe = popen("cat " TMP_FILE " | grep 'SIP/2.0' | wc -l", "r");

            if (tmp_file == NULL) {
                mor_log("Cannot open " TMP_FILE, 0);
                return 1;
            }

            fgets(buffer, 64, pipe);

            if (atoi(buffer) > 0) {
                pclose(pipe);
                return 0;
            } else {
                pclose(pipe);
                return 1;
            }
        }

    }

    pclose(pipe);

    pipe = popen("killall -9 sipsak &> /dev/null", "r");

    if (pipe == NULL) {
        mor_log("Cannot execute 'killall -9 sipsak'", 0);
        return 1;
    }

    pclose(pipe);

    return 1;

}

int update_provider_status(int id, int status) {

    char sqlcmd[1024] = "";
    char log_buffer[1024] = "";

    if (status != 1) {
        status = 0;
    }

    sprintf(sqlcmd, "UPDATE providers SET alive = %d WHERE id = %d", status, prov[id].id);

    if (mysql_query(&mysql, sqlcmd)) {
        sprintf(log_buffer, "%s", mysql_error(&mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    return 0;

}

// get server ID

int get_server_id(const char *path) {

    FILE *pipe;
    char buffer[256] = "";
    char cmd[1024] = { 0 };

    sprintf(cmd, "cat %s | grep 'server_id' | tr '=' '\\n' | tail -n 1", path);

    pipe = popen(cmd, "r");

    if (!pipe) {
        return 1;
    }

    fgets(buffer, 256, pipe);
    buffer[strlen(buffer) - 1] = 0;
    server_id = atoi(buffer);

    pclose(pipe);

    if (server_id == 0) return 1;

    return 0;
}

// this thread kill another thread (check_provider_status_thread) after timeout

void *timeout_thread() {
    sleep(SIPSAK_TIMEOUT);
    // kill check_provider_status_thread
    pthread_cancel(pcheck);
    pthread_exit(NULL);
}

// check provider availability

void *check_provider_status_thread(void *arg) {
    // check provider status
    if (check_provider_status((intptr_t)arg)) {
        prov_status = 0;
    } else {
        prov_status = 1;
    }
    // kill timeout thread so the main program doesn't have to wait
    pthread_cancel(timeout);
    pthread_exit(NULL);
}
