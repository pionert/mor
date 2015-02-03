// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Blacklisting script updates scores on src/dst/ip

#define _XOPEN_SOURCE 700

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <mysql/mysql.h>

// DEFINITIONS

#define LOG_FILE        "/var/log/mor/blacklist.log"
#define CONFPATH        "/var/lib/asterisk/agi-bin/mor.conf"
#define RULESPATH       "/usr/local/mor/blacklist.conf"
#define DATE_FORMAT     "%Y-%m-%d %H:%M:%S"

// FUNCTION DECLARATIONS

int db_connect(MYSQL *mysql, const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag);
int read_config();
int read_blacklisting_rules();
int check_process_lock();
void mor_log(const char *msg, int new_line);
int mor_mysql_query(MYSQL *mysql, char *query, int fetch);
int update_blacklisted_values(int type);
int create_tmp_table();
int get_blacklisted_values(char *type, int timeval);
int is_valid_number(const char *str);
int load_locationrules();
void localize_dst(char *dst, char *new_dst, int location_id);

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
int dbport      = 0;

// typedef for blacklisting rules
typedef struct blacklist_rules_struct {
    int pos;
    int type;
    int times;
    int period;
    int score;
    char prefix[128];
} blacklist_rules_t;

blacklist_rules_t brules[1000];
int brules_count = 0;

typedef struct lrules_struct {
    int location_id;
    int minlen;
    int maxlen;
    char cut[32];
    char add[32];
} lrules_t;

lrules_t lrules[50000];
int lrules_count = 0;

// blacklisted values (src/dst/ip)
typedef struct blacklisted_value_struct {
    char value[64];
} blacklisted_value_t;

blacklisted_value_t *bval = NULL;
unsigned long long int bval_count = 0;

// max time period
int max_period = 0;

// should we run this script?
int script_enabled = 0;

// MAIN FUNCTION

int main(void) {

    // check for duplicate processes
    if (check_process_lock()) {
        exit(1);
    }

    // read database configuration
    if (read_config()) {
        exit(1);
    }

    // connect to database
    if (db_connect(&mysql, dbhost, dbuser, dbpass, dbname, dbport, NULL, 0) == 1) {
        exit(1);
    }

    // starting sript
    mor_log("Starting Blacklisting script", 1);

    // read 'default_bl_rules' variable from conflines
    mor_log("Reading use_blacklisting_rules variable", 0);
    if (mor_mysql_query(&mysql, "SELECT value FROM conflines WHERE name = 'default_bl_rules'", 1)) {
        exit(1);
    }

    // get value
    if (row[0]) script_enabled = atoi(row[0]);

    // check if script is enabled
    if (script_enabled) {
        mor_log("Blacklisting rules are enabled", 0);
    } else {
        mor_log("Blacklisting rules ar disabled. Aborting...", 0);
        exit(1);
    }

    // load location rules
    mor_log("Reading location rules", 0);
    if (load_locationrules()) {
        exit(1);
    }

    // read rules from blacklist.conf
    mor_log("Reading blacklisting rules", 0);
    if (read_blacklisting_rules()) {
        exit(1);
    }

    // create temporary MySQL table filled with calls that fit max period from blacklisting rules
    mor_log("Creating temporary database", 0);
    if (create_tmp_table()) {
        exit(1);
    }

    // get blacklisted src
    mor_log("Searching and updating blacklisted SRC", 0);
    if (update_blacklisted_values(0)) {
        exit(1);
    }

    // get blacklisted dst
    mor_log("Searching and updating blacklisted DST", 0);
    if (update_blacklisted_values(1)) {
        exit(1);
    }

    // get blacklisted ip
    mor_log("Searching and updating blacklisted IP", 0);
    if (update_blacklisted_values(2)) {
        exit(1);
    }

    // get blacklisted dstsrc
    mor_log("Searching and updating blacklisted DSTSRC", 0);
    if (update_blacklisted_values(3)) {
        exit(1);
    }

    // get blacklisted dstduration
    mor_log("Searching and updating blacklisted DSTDURATION", 0);
    if (update_blacklisted_values(4)) {
        exit(1);
    }

    // get blacklisted srcduration
    mor_log("Searching and updating blacklisted SRCDURATION", 0);
    if (update_blacklisted_values(5)) {
        exit(1);
    }

    // get blacklisted dstlength
    mor_log("Searching and updating blacklisted DSTLENGTH", 0);
    if (update_blacklisted_values(6)) {
        exit(1);
    }

    // get blacklisted srclength
    mor_log("Searching and updating blacklisted SRCLENGTH", 0);
    if (update_blacklisted_values(7)) {
        exit(1);
    }

    // get blacklisted srcbldst
    mor_log("Searching and updating blacklisted SRCBLDST", 0);
    if (update_blacklisted_values(8)) {
        exit(1);
    }

    mysql_close(&mysql);
    exit(0);

}

// check for duplicate processes

int check_process_lock() {

    char buffer[128] = { 0 };

    FILE *pipe = popen("ps -ef | grep -v grep | grep /usr/local/mor/mor_blacklisting_script | wc -l", "r");
    fgets(buffer, 64, pipe);

    if (atoi(buffer) > 1) {
        printf("[mor_blacklisting_script] Process locked!\n");
        mor_log("Process locked!", 0);
        fclose(pipe);
        return 1;
    }

    fclose(pipe);

    return 0;

}

// get database configuration

int read_config() {

    FILE *file = NULL;

    char var[256] = "";
    char val[256] = "";

    file = fopen(CONFPATH, "r");

    if (!file) {
        mor_log("Cannot read configuration variables from: " CONFPATH, 0);
        return 1;
    }

    // Default values
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;

    // Read values from conf file
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

// log messages to database with current timestamp

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

// get rules from config file

int read_blacklisting_rules() {

    FILE *file = NULL;
    char val[512] = "";
    char *buffer = NULL;

    file = fopen(RULESPATH, "r");

    if (!file) {
        mor_log("Cannot properly read blacklisting rules from: " RULESPATH, 0);
        return 1;
    }

    // Read values from conf file
    while (fgets(val, sizeof val, file) != NULL ) {

        if (val[0] == ';') continue;

        if (strlen(val) < 5) continue;

        brules[brules_count].pos = brules_count;

        // get rules type (src/dst/ip) variable
        buffer = strtok(val, ",");
        brules[brules_count].type = -1;
        if (buffer) {
            if (strcmp(buffer, "src") == 0) brules[brules_count].type = 0;
            if (strcmp(buffer, "dst") == 0) brules[brules_count].type = 1;
            if (strcmp(buffer, "ip") == 0) brules[brules_count].type = 2;
            if (strcmp(buffer, "dstsrc") == 0) brules[brules_count].type = 3;
            if (strcmp(buffer, "dstduration") == 0) brules[brules_count].type = 4;
            if (strcmp(buffer, "srcduration") == 0) brules[brules_count].type = 5;
            if (strcmp(buffer, "dstlength") == 0) brules[brules_count].type = 6;
            if (strcmp(buffer, "srclength") == 0) brules[brules_count].type = 7;
            if (strcmp(buffer, "srcbldst") == 0) brules[brules_count].type = 8;
        }
        // if type is unknow, skip this rule and check next one
        if (brules[brules_count].type == -1) continue;

        // get prefix
        buffer = strtok(NULL, ",");
        if (buffer) strcpy(brules[brules_count].prefix, buffer);

        // get occurrences variable
        buffer = strtok(NULL, ",");
        if (buffer) brules[brules_count].times = atoi(buffer);

        // get time period variable
        buffer = strtok(NULL, ",");
        if (buffer) {
            brules[brules_count].period = atoi(buffer);
            if (brules[brules_count].period > max_period) max_period = brules[brules_count].period;
        }

        // get score variable
        buffer = strtok(NULL, ",");
        if (buffer) brules[brules_count].score = atoi(buffer);

        brules_count++;

    }

    if (brules_count == 0) {

        mor_log("Cannot properly read blacklisting rules from: " RULESPATH, 0);
        return 1;

    } else {

        // print rules table

        int i = 0;
        char log_buffer[4096] = "";
        char tmp_buffer[512]  = "";
        char type_buffer[32]  = "";

        sprintf(log_buffer, "Blacklisting rules:\n");

        for (i = 0; i < brules_count; i++) {

            if (brules[i].type == 0) strcpy(type_buffer, "src");
            if (brules[i].type == 1) strcpy(type_buffer, "dst");
            if (brules[i].type == 2) strcpy(type_buffer, "ip");
            if (brules[i].type == 3) strcpy(type_buffer, "dstsrc");
            if (brules[i].type == 4) strcpy(type_buffer, "dstduration");
            if (brules[i].type == 5) strcpy(type_buffer, "srcduration");
            if (brules[i].type == 6) strcpy(type_buffer, "dstlength");
            if (brules[i].type == 7) strcpy(type_buffer, "srclength");
            if (brules[i].type == 8) strcpy(type_buffer, "srcbldst");

            sprintf(tmp_buffer, "#%d %s %s %d %d %d\n", i, type_buffer, brules[i].prefix, brules[i].times, brules[i].period, brules[i].score);
            strcat(log_buffer, tmp_buffer);

        }

        log_buffer[strlen(log_buffer) - 1] = 0;
        mor_log(log_buffer, 0);

    }

    fclose(file);

    return 0;

}

// fetch blacklisted value from bl_x_scoring table

int update_blacklisted_values(int type) {

    int i = 0;
    char query[1024] = "";
    char type_buffer[1024] = "";
    char number[64] = "";
    char number_tmp[64] = "";
    char tmp_buffer[128] = "";

    if (type == 0 || type == 5 || type == 7 || type == 8) {
        strcpy(type_buffer, "src");
    } else if (type == 1 || type == 4 || type == 6) {
        strcpy(type_buffer, "dst");
    } else if (type == 2) {
        strcpy(type_buffer, "ip");
    } else if (type == 3) {
        strcpy(type_buffer, "src");
        strcpy(tmp_buffer, ", dst");
    } else {
        mor_log("Unknown type", 0);
        return 1;
    }

    for (i = 0; i < brules_count; i++) {

        // check if this is correct type
        if (brules[i].type == type) {

            // get blacklisted values
            if (type == 3) {
                get_blacklisted_values("dst", brules[i].period);
            } else {
                get_blacklisted_values(type_buffer, brules[i].period);
            }

            if (bval_count == 0) {
                char buffer[256] = "";
                sprintf(buffer, "Blacklisted values not found for rule #%d", i);
                mor_log(buffer, 0);
                continue;
            }

            sprintf(query, "SELECT %s, Count(%s), location_id, billsec, dst, score FROM calls_blacklisting_tmp WHERE calldate > DATE_SUB(NOW(), INTERVAL %d MINUTE) GROUP BY %s%s", type_buffer, type_buffer, brules[i].period, type_buffer, tmp_buffer);

            if (mor_mysql_query(&mysql, query, 0)) {
                return 1;
            }

            while ((row = mysql_fetch_row(result)) != NULL) {

                if (row[0] && row[1] && row[2] && row[3] && row[4]) {

                    // localize dst
                    if (type == 1) {
                        localize_dst(row[0], number, atoi(row[2]));
                    } else {
                        strcpy(number, row[0]);
                    }

                    int empty_number = 0;
                    int billsec = 0;
                    int length = 0;
                    int score = 0;

                    if (row[5]) {
                        score = atoi(row[5]);
                    }

                    if (row[3]) billsec = atoi(row[3]);

                    if (type == 3 && row[4]) {
                        localize_dst(row[4], number_tmp, atoi(row[2]));
                    }

                    length = strlen(number);

                    // find matching values (calls <--> bl_x_scoring)

                    int found = 0, j = 0;

                    if (type == 3) {
                        for (j = 0; j < bval_count; j++) {
                            if (strcmp(number_tmp, bval[j].value) == 0) {
                                found = 1;
                                break;
                            }
                        }
                    } else {
                        for (j = 0; j < bval_count; j++) {
                            if (strcmp(number, bval[j].value) == 0) {
                                found = 1;
                                break;
                            }
                        }
                    }

                    if (brules[i].type == 3 && strcmp(brules[i].prefix, "EMPTY") == 0 && strlen(number) == 0) {
                        empty_number = 1;
                        found = 1;
                    }

                    if (found == 0) continue;

                    int result = 0;

                    if (type == 1 || type == 2 || type == 3) {
                        result = (atoi(row[1]) >= brules[i].times);
                    } else if (type == 4 || type == 5) {
                        result = (billsec <= brules[i].times && billsec > 0);
                    } else if (type == 6 || type == 7) {
                        result = (length <= brules[i].times);
                    } else if (type == 8) {
                        result = (score >= brules[i].times);
                    }

                    if (result) {

                        char log_buffer[1024] = "";
                        char sql_buffer[1024] = "";

                        // check if rule applies to all targets or prefix is used
                        if (strcmp(brules[i].prefix, "*") != 0) {
                            if (!empty_number) {
                                // check if prefix is a valid number
                                if (is_valid_number(brules[i].prefix) || (brules[i].type != 0 && brules[i].type != 5 && brules[i].type != 7)) {
                                    int j = 0;
                                    if (strlen(brules[i].prefix) > strlen(number)) {
                                        goto skip_record;
                                    }
                                    for (j = 0; j < strlen(brules[i].prefix); j++) {
                                        if (brules[i].prefix[j] != number[j]) goto skip_record;
                                    }
                                } else {
                                    if (strstr(number, brules[i].prefix) == NULL) goto skip_record;
                                }
                            }
                        }

                        if (type == 3) {
                            strcpy(type_buffer, "dst");
                            strcpy(number, number_tmp);
                        }

                        sprintf(log_buffer, "Updating score (+%d) by rule (#%d) for %s (%s) prefix used (%s)", brules[i].score, i, type_buffer, number, brules[i].prefix);
                        mor_log(log_buffer, 0);

                        sprintf(sql_buffer, "UPDATE bl_%s_scoring SET score = score + %d, updated_at = NOW() WHERE value = '%s' AND updated_at < DATE_SUB(NOW(), INTERVAL %d MINUTE)", type_buffer, brules[i].score, number, brules[i].period);
                        if (mysql_query(&mysql, sql_buffer)) {
                            char error_buffer[1024] = "";
                            sprintf(error_buffer, "%s", mysql_error(&mysql));
                            mor_log(error_buffer, 0);
                            return 1;
                        }

                        skip_record: ;

                    }

                } else {

                    char log_buffer[1024] = "";

                    if (!row[0]) {
                        sprintf(log_buffer, "%s is NULL", type_buffer);
                        mor_log(log_buffer, 0);
                    }

                    if (!row[1]) {
                        sprintf(log_buffer, "COUNT(%s) is NULL", type_buffer);
                        mor_log(log_buffer, 0);
                    }

                    if (!row[2]) mor_log("location_id is NULL", 0);
                    if (!row[3]) mor_log("billsec is NULL", 0);
                    if (!row[4]) mor_log("dst is NULL", 0);
                    if (!row[5]) mor_log("score is NULL", 0);

                    return 1;

                }

            }

            mysql_free_result(result);

        }

    }

    return 0;

}

// create temporary MySQL table filled with calls that fit max period from blacklisting rules

int create_tmp_table() {

    char sqlcmd[2048] = "";
    char log_buffer[2048] = "";

    char create_table_sql[1024] = "CREATE TEMPORARY TABLE calls_blacklisting_tmp ("
                                  "src VARCHAR(80) NOT NULL,"
                                  "dst VARCHAR(80) NOT NULL,"
                                  "ip VARCHAR(80) NULL,"
                                  "calldate datetime NOT NULL,"
                                  "location_id INT NOT NULL,"
                                  "billsec INT DEFAULT 0,"
                                  "score INT DEFAULT 0);";

    if (mysql_query(&mysql, create_table_sql)) {
        sprintf(log_buffer, "%s", mysql_error(&mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    sprintf(sqlcmd, "INSERT INTO calls_blacklisting_tmp SELECT src, dst, INET_NTOA(call_details.recvip), calldate, devices.location_id, calls.billsec, bl_dst_scoring.score FROM calls JOIN devices ON devices.id = calls.accountcode LEFT JOIN call_details ON calls.id = call_details.call_id LEFT JOIN bl_dst_scoring ON bl_dst_scoring.value = calls.localized_dst WHERE calls.calldate > DATE_SUB(NOW(), INTERVAL %d MINUTE)", max_period);

    if (mysql_query(&mysql, sqlcmd)) {
        sprintf(log_buffer, "%s", mysql_error(&mysql));
        mor_log(log_buffer, 0);
        return 1;
    }

    return 0;

}

// check if string is a valid number

int is_valid_number(const char *str) {

    // Handle empty string
    if (!*str) return 0;

    // Check for non-digit chars in the rest of the stirng.
    while (*str) {
        if (!isdigit(*str)) {
            return 0;
        } else {
            ++str;
        }
    }

    return 1;
}

// load location rules from database

int load_locationrules() {

    // send query, handle errors and do not fetch results
    if (mysql_query(&mysql, "SELECT locationrules.location_id, locationrules.cut, locationrules.add, minlen, maxlen FROM locationrules WHERE enabled = 1 AND lr_type = 'dst' ORDER BY location_id, LENGTH(cut) DESC;")) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    while (( row = mysql_fetch_row(result) )) {

        if (row[0]) lrules[lrules_count].location_id = atoi(row[0]);
        if (row[1]) strcpy(lrules[lrules_count].cut, row[1]); else lrules[lrules_count].cut[0] = 0;
        if (row[2]) strcpy(lrules[lrules_count].add, row[2]); else lrules[lrules_count].add[0] = 0;
        if (row[3]) lrules[lrules_count].minlen = atoi(row[3]); else lrules[lrules_count].minlen = -1;
        if (row[4]) lrules[lrules_count].maxlen = atoi(row[4]); else lrules[lrules_count].maxlen = -1;

        lrules_count++;

        if (lrules_count == 50000) {
            mor_log("Too many location rules", 0);
            exit(1);
        }
    }

    mysql_free_result(result);

    return 0;
}

// localize destination

void localize_dst(char *dst, char *new_dst, int location_id) {

    int i = 0;
    int str_len = strlen(dst);
    char tmp[256] = "";

    strcpy(new_dst, dst);

    if (lrules_count == 0) return;

    for (i = 0; i < lrules_count; i++) {
        if (location_id == lrules[i].location_id) {
            if (str_len >= lrules[i].minlen && str_len <= lrules[i].maxlen) {
                strncat(tmp, dst, strlen(lrules[i].cut));
                if (strcmp(tmp, lrules[i].cut) == 0) {
                    sprintf(new_dst, "%s%s", lrules[i].add, dst + strlen(lrules[i].cut));
                    return;
                }
                memset(tmp, 0, 256);
            }
        }
    }

}

// get blacklisted src/dst/ip

int get_blacklisted_values(char *type, int timeval) {

    char sqlcmd[1024] = "";

    // clear structure
    memset(bval, 0, bval_count * sizeof(blacklisted_value_t));
    bval_count = 0;

    sprintf(sqlcmd, "SELECT value FROM bl_%s_scoring WHERE updated_at < DATE_SUB(NOW(), INTERVAL %d MINUTE)", type, timeval);

    // send query, handle errors and do not fetch results
    if (mor_mysql_query(&mysql, sqlcmd, 0)) {
        return 1;
    }

    // fill structure
    while ((row = mysql_fetch_row(result))) {

        if (row[0]) {
            bval = realloc(bval, (bval_count + 1) * sizeof(blacklisted_value_t));
            strcpy(bval[bval_count].value, row[0]);
            bval_count++;
        }

    }

    mysql_free_result(result);

    return 0;

}
