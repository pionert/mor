// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script searches for tickets that haven't been solved for X hours and reports them via email

// USAGE:
//
//      normal execution:
//              escalation
//
//      execution in debug mode:
//              escalation --debug

// CONFIG FILE EXAMPLE:
//
// # stmp
//
// server smtp.gmail.com:587
// username mail@mail.com
// password mypass
// 
// # rules
// 
// 0 0 1 support@kolmisoft.com engineer@kolmisoft.com info@kolmisoft.com end
// 0 1 2 support@kolmisoft.com engineer@kolmisoft.com end
// 0 1 3 info@kolmisoft.com end
//

// CONFIG FILE EXPLANATION:
//
// # stmp - SMTP configuration

// server   - address of SMTP server
// username - SMTP username (if username is blank put - symbol instead)
// password - SMTP password (if password is blank put - symbol instead)

// # rules - rules of how tickets are reported

// column 1 - support plan (0 - Platinum; 1 - With Support; 2 - Without support)
// column 2 - ticket priority (0 - blocker; 1 - high; 2 - medium; 3 - low)
// column 3 - time (in hours) required to pass for ticket to be reported
// all other columns - list of emails to which notifications will be sent (list must end with a word "end")

// for example if the rule is:

// 0 1 24 support@kolmisoft.com engineer@kolmisoft.com end

// then if Platinum ticket with a high priority is not solved for more than 24 hours,
// it will be reported to support@kolmisoft.com and engineer@kolmisoft.com

#define _XOPEN_SOURCE 700

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <mysql/mysql.h>
#include <time.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

// DFINITIONS

#define DATE_FORMAT "%Y-%m-%d %H:%M:%S"
#define CONFPATH "escalation.conf"
#define REPORTEDPATH "reported.txt"
#define DBCONFPATH "/home/tickets/config/database.yml"
#define DEBUGPATH "debug.txt"

// VARIABLES

MYSQL mysql;
MYSQL_RES *result;
MYSQL_ROW row;

// configuration
typedef struct conf_struct {
    char host[64];
    char database[64];
    char username[64];
    char password[64];
} conf_t;

// default values
conf_t conf = { "localhost", "tickets", "root", "" };

// escalation rules
typedef struct rules_struct {
    int splan;              // support plan
    int priority;           // ticket priority
    int hours;              // how many hours should pass since email is sent
    int email_count;        
    char emails[256][256];
} rules_t;
rules_t *rules = NULL;
int rules_count = 0;

// sorted data
typedef struct data_struct {
    char email[256];
    int rules[256][3];
    int rules_count;
} data_t;
int data_count = 0;
data_t data[256];

// reported tickets
typedef struct reported_struct {
    int id;
    char email[256];
} reported_t;
reported_t *reported = NULL;
int reported_count = 0;

// cURL variables
typedef char text_t[2048];
text_t *payload_text = NULL;
 
struct upload_status {
    int lines_read;
};

char from[256] = "";
char pass[256] = "";
char server[256] = "";

// debug variables
int DEBUG = 0;
FILE *debug = NULL;

// FUNCTION DECLARATIONS

int db_connect(const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag);
int my_mysql_query(MYSQL *mysql, char *query, int fetch);
void get_current_time(char *datetime);
int compare_splan (const void *pa, const void *pb);
int compare_priority (const void *pa, const void *pb);
int send_email(char *to, char *text);
int get_conf(conf_t *conf);
int time_diff(char *t1, char *t2);

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    char current_date[20] = "";
    char query[1024] = "";
    int diff = 0;
    int splan = 0;
    int priority = 0;
    int i = 0, j = 0, k = 0;
    int last_splan = -1;
    int last_priority = -1;
    char line_buffer[256] = { 0 };
    char email_buffer[96000] = { 0 };
    int sql_rows = 0;
    int ticket_rows = 0;

    get_current_time(current_date);

    debug = fopen(DEBUGPATH, "w");
    fprintf(debug, "************* Escalation debug (%s) *************\n\n", current_date);

    freopen(DEBUGPATH, "a", stderr);

    // check if debug is ON
    if(argc > 1) {
        if(strcmp(argv[1], "--debug") == 0) {
            DEBUG = 1;
        }
    }

    // initialize structures
    memset(&data, 0, 256*sizeof(data_t));

    if(get_conf(&conf)) {
        return 1;
    }

    fprintf(debug, "\nConnecting to database\n");
    // connect to database
    if(db_connect(conf.host, conf.username, conf.password, conf.database, 0, NULL, 0) == 1) {
        if(DEBUG) fprintf(debug, "Connection to database failed.\n");
        return 1;
    }
    fprintf(debug, "Connected successfully\n");

    // get all active tickets
    sprintf(query, "SELECT tickets.ticket_add, ticket_priority, with_supportplan, supportplans.name, tickets.id FROM tickets "
                   "LEFT JOIN plansubscriptions ON tickets.user_id=plansubscriptions.user_id "
                   "LEFT JOIN supportplans ON supportplans.id=plansubscriptions.supportplan_id "
                   "WHERE resolution = 'new' AND custom_development = 0 AND public = 0;");

    fprintf(debug, "Sending query to database\n\n%s\n\n", query);

    if(my_mysql_query(&mysql, query, 0)) {
        exit(1);
    }

    fprintf(debug, "Parsing tickets:\n\n");

    while(( row = mysql_fetch_row(result) )) {

        // check for ticket priority
        priority = 0;
        if(strcmp(row[1], "blocker") == 0) {
            priority = 0;
        } else if(strcmp(row[1], "high") == 0) {
            priority = 1;
        } else if(strcmp(row[1], "medium") == 0) {
            priority = 2;
        } else {
            priority = 3;
        }

        // check for ticket support plan
        splan = 0;
        if(row[3] && strstr(row[3], "Support Plan \"Platinum\"")) {
            splan = 0;
        } else if(strcmp(row[2], "1") == 0) {
            splan = 1;
        } else if(strcmp(row[2], "0") == 0) {
            splan = 2;
        }

        fprintf(debug, "[%s] %s  %s  (%s)", row[4], row[0], row[3], row[1]);

        // calculate time difference since ticket was created (in hours)
        diff = time_diff(current_date, row[0]);

        int will_be_reported = 0;

        // check if tickets fits any rule
        for(i = 0; i < rules_count; i++) {
            if(rules[i].splan == splan && rules[i].priority == priority && diff >= rules[i].hours) {
                for(j = 0; j < data_count; j++) {
                    for(k = 0; k < rules[i].email_count; k++) {
                        if(strcmp(data[j].email, rules[i].emails[k]) == 0) {
                            int l, found = 0;

                            for(l = 0; l < data[j].rules_count; l++) {
                                if(data[j].rules[l][2] == atoi(row[4])) found = 1;
                            }

                            if(found == 0) {
                                sql_rows = 1;
                                will_be_reported = 1;
                                data[j].rules[data[j].rules_count][0] = i;
                                data[j].rules[data[j].rules_count][1] = diff;
                                data[j].rules[data[j].rules_count][2] = atoi(row[4]);
                                data[j].rules_count++;
                            }
                        }
                    }
                }
            }
        }

        if(will_be_reported) {
            fprintf(debug, "   [Ticket will be reported]\n");
        } else {
            fprintf(debug, "\n");
        }
    }

    if(sql_rows) {

        // sort by splan and priority
        for(i = 0; i < data_count; i++) {
            qsort(data[i].rules, data[i].rules_count, 3*sizeof(int), compare_priority);
            qsort(data[i].rules, data[i].rules_count, 3*sizeof(int), compare_splan);
        }

        fprintf(debug, "\nConstructing emails:\n\n");

        // construct email text
        for(i = 0; i < data_count; i++) {
            if(data[i].rules_count > 0) {

                for(j = 0; j < data[i].rules_count; j++) {
                    int rule_id = data[i].rules[j][0];
                    int found = 0;

                    for(k = 0; k < reported_count; k++) {
                        if(reported[k].id == data[i].rules[j][2] && strcmp(reported[k].email, data[i].email) == 0)  found = 1;
                    }

                    if(found == 0) {
                        ticket_rows = 1;
                        if(last_splan != rules[rule_id].splan || last_priority != rules[rule_id].priority) {

                            switch(rules[rule_id].splan) {
                                case 0: strcat(email_buffer, "\nPlatinum "); break;
                                case 1: strcat(email_buffer, "\nWith Support "); break;
                                case 2: strcat(email_buffer, "\nWithout Support "); break;
                                case 3: strcat(email_buffer, "\nCustom Development "); break;
                                default: strcat(email_buffer, "\nUnknown ");
                            }
                            last_splan = rules[rule_id].splan;

                            switch(rules[rule_id].priority) {
                                case 0: strcat(email_buffer, "[Blocker]\n"); break;
                                case 1: strcat(email_buffer, "[High]\n"); break;
                                case 2: strcat(email_buffer, "[Medium]\n"); break;
                                case 3: strcat(email_buffer, "[Low]\n"); break;
                                default: strcat(email_buffer, "[Unknown]\n");
                            }
                            last_priority = rules[rule_id].priority;
                        }
                        sprintf(line_buffer, "\tNot solved for %d hours - https://support.kolmisoft.com/tickets/ticket_show/%d\n", data[i].rules[j][1], data[i].rules[j][2]);
                        strcat(email_buffer, line_buffer);

                        reported = (reported_t *)realloc(reported, (reported_count + 1)*sizeof(reported_t));
                        reported[reported_count].id = data[i].rules[j][2];
                        strcpy(reported[reported_count].email, data[i].email);
                        reported_count++;
                    } else {
                        fprintf(debug, "\t[%d] Already reported. Skipping this ticket\n", data[i].rules[j][2]);
                    }
                }

                if(strlen(email_buffer) > 1) {
                    fprintf(debug, "\n\n-------------------------------------------------------------------------------------\n");
                    fprintf(debug, "Email to: %s\n", data[i].email);
                    fprintf(debug, "-------------------------------------------------------------------------------------\n");
                    fprintf(debug, "%s", email_buffer);
                    if(!DEBUG) {
                        fprintf(debug, "\nSending email:\n\n");
                        send_email(data[i].email, email_buffer);
                    }
                }

                memset(line_buffer, 0, 256);
                memset(email_buffer, 0, 9048);
                last_splan = -1;
                last_priority = -1;
            }
        }

        if(ticket_rows == 0) {
            fprintf(debug, "\nNo tickets to report\n");
        }

        if(DEBUG == 0) {
            FILE *rfp = fopen(REPORTEDPATH, "w");

            // mark emails as 'reported' (same ticket is not sent twice)
            for(i = 0; i < reported_count; i++) {
                int found = 0;
                for(j = 0; j < data_count; j++) {
                    for(k = 0; k < data[j].rules_count; k++) {
                        if(reported[i].id == data[j].rules[k][2]) {
                            found = 1;
                        }
                    }
                }
                if(found) {
                    fprintf(rfp, "%d %s\n", reported[i].id, reported[i].email);
                }
            }

            fclose(rfp);
        }
    } else {
        fprintf(debug, "\nNo tickets to report\n");
    }

    fclose(debug);

    mysql_free_result(result);

    mysql_close(&mysql);

    return 0;
}

int db_connect(const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag) {
    if(!mysql_init(&mysql)) {
        if(DEBUG)  fprintf(debug, "MySQL error: %s\n", mysql_error(&mysql));
        return 1;
    }

    if(!mysql_real_connect(&mysql, host, user, pass, db, port, socket, cflag)) {
        if(DEBUG) fprintf(debug, "MySQL error: %s\n", mysql_error(&mysql));
        return 1;
    }

    return 0;
}

int my_mysql_query(MYSQL *mysql, char *query, int fetch) {

    if(mysql_query(mysql, query)) {
        fprintf(debug, "MySQL query cannot be sent to database: %s\n", mysql_error(mysql));
        return 1;
    }

    result = mysql_store_result(mysql);

    if(result == NULL) {
        fprintf(debug, "mysql_store_result error: %s\n", mysql_error(mysql));
        return 1;
    }
    
    if(fetch) {
        if((row = mysql_fetch_row(result)) == NULL) {
            fprintf(debug, "MySQL returned an empty result set\n");
            return 1;
        }
    }

    return 0;
}

int get_conf(conf_t *conf) {

    fprintf(debug, "\nReding configuration file: " CONFPATH "\n");

    char var1[256] = { 0 };
    char var2[256] = { 0 };

    int pos = 0;
    int found = 0;
    int i = 0, j = 0;

    FILE *fp = fopen(CONFPATH, "r");
    FILE *rfp = fopen(REPORTEDPATH, "a+");
    FILE *dfp = fopen(DBCONFPATH, "r");

    if(dfp == NULL) {
        fprintf(debug, "Cannot open debug file: " DBCONFPATH "\n");
        exit(1);
    }

    if(fp == NULL) {
        fprintf(debug, "Cannot open configuration file: " CONFPATH "\n");
        exit(1);
    }

    if(rfp == NULL) {
        fprintf(debug, "Cannot open reported ticket file: " REPORTEDPATH "\n");
        exit(1);
    }

    // read reported tickets
    while(( fscanf(rfp, "%s %s", var1, var2) != EOF )) {
        reported = (reported_t *)realloc(reported, (reported_count + 1)*sizeof(reported_t));
        reported[reported_count].id = atoi(var1);
        strcpy(reported[reported_count].email, var2);
        reported_count++;
    }

    int end_of_comments = 0;
    // read conf file
    while(( fscanf(fp, "%s %s", var1, var2) != EOF )) {

        if(end_of_comments == 0) {
            while(( fscanf(fp, "%s", var1) != EOF )) {
                if(strcmp(var1, "--------------------------------------------") == 0) {
                    end_of_comments = 1;
                    fscanf(fp, "%s %s", var1, var2);
                    break;
                }
            }
        }

        fprintf(debug, "\nReading SMTP settings\n");
        // get smtp
        if((strcmp(var1, "#") == 0) && (strcmp(var2, "smtp") == 0 )) {
            fscanf(fp, "%s %s", var1, var2);
            strcpy(server, var2);
            fscanf(fp, "%s %s", var1, var2);
            if(strcmp(var2, "-") != 0) {
                strcpy(from, var2);
            } else {
                strcpy(from, "escalation@kolmisoft.com");
            }
            fscanf(fp, "%s %s", var1, var2);
            if(strcmp(var2, "-") != 0) {
                strcpy(pass, var2);
            } else {
                strcpy(pass, "");
            }
            while(( fscanf(fp, "%s %s", var1, var2) != EOF)) {
                if(strcmp(var1, "#") == 0) break;
            }
        }

        fprintf(debug, "SMTP server - %s\n", server);
        fprintf(debug, "Username - %s\n", from);
        fprintf(debug, "Password - %s\n", pass);
        fprintf(debug, "\nReading levels\n");

        fprintf(debug, "\nReading rules\n");

        // get rules
        if((strcmp(var1, "#") == 0) && (strcmp(var2, "rules") == 0 )) {
            while(( fscanf(fp, "%s", var1) != EOF )) {
                if(strcmp(var1, "end") == 0) {
                    pos = 0;
                    continue;
                }

                if(pos == 0) {
                    rules_count++;
                    rules = (rules_t *)realloc(rules, (rules_count)*sizeof(rules_t));
                    rules[rules_count - 1].email_count = 0;
                    rules[rules_count - 1].splan = atoi(var1);
                }

                if(pos == 1) rules[rules_count - 1].priority = atoi(var1);
                if(pos == 2) rules[rules_count - 1].hours = atoi(var1);

                if(pos > 2) {
                    strcpy(rules[rules_count - 1].emails[pos - 3], var1);
                    rules[rules_count - 1].email_count++;

                    // get unique emails
                    if(data_count == 0) {
                        strcpy(data[data_count].email, var1);
                        data_count++;
                    } else {
                        int i, found = 0;
                        for(i = 0; i < data_count; i++) {
                            if(strcmp(var1, data[i].email) == 0) found = 1;
                        }

                        if(found == 0) {
                            strcpy(data[data_count].email, var1);
                            data_count++;
                        }
                    }
                }

                pos++;
            }
        }


        for(i = 0; i < rules_count; i++) {
            fprintf(debug, "%d %d %d ", rules[i].splan, rules[i].priority, rules[i].hours);
            for(j = 0; j < rules[i].email_count; j++) {
                fprintf(debug, "%s ", rules[i].emails[j]);
            }
            fprintf(debug, "\n");
        }
    }

    fprintf(debug, "\nReading database settings\n");

    found = 0;
    // get database conf
    while(fscanf(dfp, "%s", var1) != EOF) {
        if(strcmp(var1, "production:") && !found) continue;
        found = 1;
        if(strcmp(var1, "host:") == 0) {
            fscanf(dfp, "%s", var2);
            strcpy(conf->host, var2);
        }
        if(strcmp(var1, "username:") == 0) {
            fscanf(dfp, "%s", var2);
            strcpy(conf->username, var2);
        }
        if(strcmp(var1, "password:") == 0) {
            fscanf(dfp, "%s", var2);
            if(var2[strlen(var2) - 1] == ':') strcpy(var2, "");
            strcpy(conf->password, var2);
        }
        if(strcmp(var1, "database:") == 0) {
            fscanf(dfp, "%s", var2);
            strcpy(conf->database, var2);
        }
    }

    fprintf(debug, "Host - %s\n", conf->host);
    fprintf(debug, "Username - %s\n", conf->username);
    fprintf(debug, "Password - %s\n", conf->password);
    fprintf(debug, "Database - %s\n", conf->database);

    fclose(fp);
    fclose(rfp);
    fclose(dfp);

    return 0;
}

void get_current_time(char *datetime) {
    time_t t;
    struct tm *tmp;
    char tmp_str[100];

    t = time(NULL);
    tmp = localtime(&t);

    strftime(tmp_str, sizeof(tmp_str), DATE_FORMAT, tmp);
    strcpy(datetime, tmp_str);
}

// calculate time difference between two dates
int time_diff(char *t1, char *t2) {
    time_t tt1, tt2;
    struct tm tmm1, tmm2;
    int diff = 0;

    memset(&tmm1, 0, sizeof(struct tm));
    memset(&tmm2, 0, sizeof(struct tm));

    strptime(t1, DATE_FORMAT, &tmm1);
    strptime(t2, DATE_FORMAT, &tmm2);

    tt1 = mktime(&tmm1);
    tt2 = mktime(&tmm2);

    diff = tt1 - tt2;

    return round(diff/3600);
}

// splan compare function
int compare_splan (const void *pa, const void *pb) {
    int *a = (int *)pa;
    int *b = (int *)pb;

    if ( rules[a[0]].splan < rules[b[0]].splan ) return -1;
    if ( rules[a[0]].splan > rules[b[0]].splan ) return +1;

    return 0;
}

// priority compare function
int compare_priority (const void *pa, const void *pb) {
    int *a = (int *)pa;
    int *b = (int *)pb;

    if ( rules[a[0]].priority < rules[b[0]].priority ) return -1;
    if ( rules[a[0]].priority > rules[b[0]].priority ) return +1;

    return 0;
}

int send_email(char *to, char *text) {
    
    char emailcmd[96000] = "";

    fprintf(debug, "echo -e 'To: %s\nFrom: %s\nSubject: Escalation notification\nThis is message body\n' | sendmail -t '%s' \n", to, from, to);
    sprintf(emailcmd, "echo -e 'To: %s\nFrom: %s\nSubject: Escalation notification\n%s\n' | sendmail -t '%s'", to, from, text, to);

    system(emailcmd); 

    return 0;
}
