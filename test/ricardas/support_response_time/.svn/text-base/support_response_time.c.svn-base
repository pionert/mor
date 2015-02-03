// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2012
// About:         Script calculates average support response time

// Arguments:
//      --start <date>          - count tickets since this date
//      --end <date>            - count tickets to this date
//      --debug                 - show URLs to tickets and comments
//      --sort                  - show URLs to tickets and comments sorted by response time
//      --id <ID>               - count response time only for ticket specified by ID
//
//      if any of these arguments is used, calculated response time will not be updated to database

// Usage:
//      ./support_response_time --start 2012-01-01 --end 2012-01-30
//      ./support_response_time --start 2012-01-01 --end 2012-01-30 --debug
//      ./support_response_time --start 2012-01-01 --end 2012-01-30 --sort
//      ./support_response_time --start 2012-01-01 --end 2012-01-30 --sort --id 15462
//      ./support_response_time

#define _XOPEN_SOURCE 700

#include <stdlib.h>
#include <stdio.h>
#include <mysql/mysql.h>
#include <string.h>
#include <time.h>
#include <math.h>

#define CONFPATH    "/home/tickets/config/database.yml"
#define DATEFORMAT  "%Y-%m-%d %H:%M:%S"

#define WORK_HOURS_START 9
#define WORK_HOURS_END   18

MYSQL mysql;
MYSQL_RES *result;
MYSQL_ROW row;

typedef struct conf_struct {
    char host[64];
    char database[64];
    char username[64];
    char password[64];
} conf_t;

// default values
conf_t conf = { "", "", "", "" };

// structure for fickets
typedef struct tickets_struct {
    int ticket_id;
    int comment_id;
    int type; // 0 - ticket, 1 - ticket status, 2 - comment
    char usertype[20]; 
    char comment_time[20];
    char resolution[20];
} tickets_t;

// structure for sorted tickets
typedef struct sorted_tickets_struct {
    int user_ticket_id;
    int user_comment_id;
    int user_type;
    char user_comment_time[20];
    char user_resolution[20];
    int support_ticket_id;
    int support_comment_id;
    int support_type;
    char support_comment_time[20];
    char support_resolution[20];
    int time_diff_minutes;
} sorted_tickets_t;

tickets_t *ticket = NULL;
int tickets = 0;

tickets_t user_ticket = { 0, 0, 0, { 0 }, { 0 } };

sorted_tickets_t *sorted_ticket = NULL;
int sorted_tickets = 0;

typedef int (*compfn)(const void*, const void*);

int db_connect(const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag);
int compare_time_diff(sorted_tickets_t *a, sorted_tickets_t *b);
int time_diff_in_seconds(char *user_date, char *support_date);
int compare_ticket_id(tickets_t *a, tickets_t *b);
int compare_time(tickets_t *a, tickets_t *b);
int count_weekends(char *user_date, int day_diff);
int get_days_in_month(int month);
int get_conf(conf_t *conf);

int main(int argc, char *argv[]) {

    char query[4096] = { 0 }, client[32] = "userprospectorother";
    int time_diff = 0, user = 0, count = 0;
    float avgtime = 0;
    int i = 0;

    int  specified_id    = 0;
    int  custom_end_time = 0;
    int  custom_period   = 0;
    char start_time[20]  = { 0 };
    char end_time[20]    = { 0 };

    unsigned long int total_tickets          = 0;
    unsigned long int total_tickets_used     = 0;
    unsigned long int total_comments         = 0;
    unsigned long int total_comments_used    = 0;
    unsigned long int total_resolutions      = 0;
    unsigned long int total_resolutions_used = 0;

    char period_sql[1024] = { 0 };

    int debug = 0;
    int sort = 0;

    if (get_conf(&conf)) {
        return 1;
    }

    if (db_connect(conf.host, conf.username, conf.password, conf.database, 0, NULL, 0) == 1) {
        printf("Connection to database failed.\n");
        return 1;
    }

    // set default custom period

    strcpy(start_time, "1900-01-01");
    strcpy(end_time, "2045-01-01");

    // get custom period, sort and debug

    for (i = 1; i < argc; i++) {

        if (strcmp(argv[i], "--sort") == 0) {
            sort = 1;
        }

        if (strcmp(argv[i], "--id") == 0) {
            specified_id = atoi(argv[i + 1]);
        }

        if (strcmp(argv[i], "--debug") == 0) {
            debug = 1;
        }

        if (strcmp(argv[i], "--start") == 0) {
            custom_period = 1;
            strcpy(start_time, argv[i + 1]);
        }

        if (strcmp(argv[i], "--end") == 0) {
            custom_period = 1;
            custom_end_time = 1;
            strcpy(end_time, argv[i + 1]);
        }

    }

    // add hours

    strcat(start_time, " 00:00:00");
    strcat(end_time, " 23:59:59");

    sprintf(period_sql, "> DATE_SUB(NOW(), INTERVAL 1 WEEK)");

    if (custom_period) {
        sprintf(period_sql, "BETWEEN '%s' AND '%s'", start_time, end_time);
    }

    // get tickets
    sprintf(query, "SELECT ticket_add, usertype, tickets.id FROM tickets INNER JOIN users ON users.id = tickets.user_id LEFT JOIN plansubscriptions ON plansubscriptions.user_id = users.id WHERE (ticket_add %s) AND ((ticket_add BETWEEN active_from AND active_till) AND users.usertype IN ('user', 'prospect', 'other')) AND users.id != 15 AND tickets.public = 0;", period_sql);

    if(mysql_query(&mysql, query)) {
        printf("%s\n", mysql_error(&mysql));
        return 1;
    }

    if((result = mysql_store_result(&mysql)) == NULL) {
        return 1;
    }

    while(( row = mysql_fetch_row(result) )) {
        ticket = (tickets_t *)realloc(ticket, (tickets + 1)*sizeof(tickets_t));
        strcpy(ticket[tickets].resolution, "null");
        strcpy(ticket[tickets].comment_time, row[0]);
        strcpy(ticket[tickets].usertype, row[1]);
        ticket[tickets].ticket_id = atoi(row[2]);
        ticket[tickets].comment_id = atoi(row[2]);
        ticket[tickets].type = 0;
        tickets++;
        total_tickets++;
    }

    mysql_free_result(result);

    // get comments
    sprintf(query, "SELECT comment_time, usertype, ticket_id, comments.id FROM comments INNER JOIN users ON users.id = comments.owner_id LEFT JOIN plansubscriptions ON plansubscriptions.user_id = users.id WHERE (comment_time %s) AND private = 0 AND ((comment_time BETWEEN active_from AND active_till) OR users.usertype IN ('admin', 'engineer', 'manager'))", period_sql);

    if(mysql_query(&mysql, query)) {
        printf("%s\n", mysql_error(&mysql));
        return 1;
    }

    if((result = mysql_store_result(&mysql)) == NULL) {
        return 1;
    }

    while(( row = mysql_fetch_row(result) )) {
        ticket = (tickets_t *)realloc(ticket, (tickets + 1)*sizeof(tickets_t));
        strcpy(ticket[tickets].resolution, "null");
        strcpy(ticket[tickets].comment_time, row[0]);
        strcpy(ticket[tickets].usertype, row[1]);
        ticket[tickets].ticket_id = atoi(row[2]);
        ticket[tickets].comment_id = atoi(row[3]);
        ticket[tickets].type = 1;
        tickets++;
        total_comments++;
    }

    mysql_free_result(result);

    // get status
    sprintf(query, "SELECT date, usertype, target_id, actions.data2, actions.action FROM actions INNER JOIN users ON users.id = actions.user_id INNER JOIN tickets ON (tickets.id = actions.target_id AND tickets.public = 0) LEFT JOIN plansubscriptions ON plansubscriptions.user_id = users.id WHERE (date %s) AND ((date BETWEEN date AND active_till) OR users.usertype IN ('admin', 'manager', 'engineer')) AND actions.action IN ('Ticket_change_resolution', 'Ticket_change_owner')", period_sql);

    if (mysql_query(&mysql, query)) {
        printf("%s\n", mysql_error(&mysql));
        return 1;
    }

    if ((result = mysql_store_result(&mysql)) == NULL) {
        return 1;
    }

    while (( row = mysql_fetch_row(result) )) {
        ticket = (tickets_t *)realloc(ticket, (tickets + 1)*sizeof(tickets_t));
        strcpy(ticket[tickets].comment_time, row[0]);
        strcpy(ticket[tickets].usertype, row[1]);
        if (row[2]) ticket[tickets].ticket_id = atoi(row[2]); else ticket[tickets].ticket_id = -1;
        strcpy(ticket[tickets].resolution, "null");
        if (row[3]) if (strlen(row[3]) > 1) strcpy(ticket[tickets].resolution, row[3]);
        if (strcmp(row[4], "Ticket_change_resolution") == 0) ticket[tickets].type = 2;
        if (strcmp(row[4], "Ticket_change_owner") == 0) {
            ticket[tickets].type = 3;
            strcpy(ticket[tickets].resolution, "invalid");
        }
        total_resolutions++;
        ticket[tickets].comment_id = 0;
        tickets++;
    }

    mysql_free_result(result);

    qsort((void *)ticket, tickets, sizeof(tickets_t), (compfn)compare_time);
    qsort((void *)ticket, tickets, sizeof(tickets_t), (compfn)compare_ticket_id);

    for (i = 0; i < tickets; i++) {

        // find first user comment
        if (user == 0) {
            if (strstr(client, ticket[i].usertype) == 0) {
                continue; // skip support comments
            } else {
                user = 1; // first user comment found
                user_ticket.type       = ticket[i].type;
                user_ticket.ticket_id  = ticket[i].ticket_id;
                user_ticket.comment_id = ticket[i].comment_id;
                strcpy(user_ticket.comment_time, ticket[i].comment_time);
                strcpy(user_ticket.usertype, ticket[i].usertype);
                strcpy(user_ticket.resolution, ticket[i].resolution);
            }
        }

        if (ticket[i].type == 2 && (strcmp(ticket[i].resolution, "new") == 0 || strcmp(ticket[i].resolution, "fixed") == 0)) {
            user = 0;
            continue;
        }

        // find first support comment
        if (user == 1 && strstr(client, ticket[i].usertype) != 0) {
            continue; // skip non support comments
        } else if (user == 1) {
            user = 0; // reset user

            // if it is the same ticket
            if (user_ticket.ticket_id == ticket[i].ticket_id) {

                time_diff = time_diff_in_seconds(user_ticket.comment_time, ticket[i].comment_time); // get time difference in seconds

                // calculate average response time
                if (time_diff > 0 && ticket[i].ticket_id > 0 && (specified_id == 0 || specified_id == ticket[i].ticket_id)) {

                    if (user_ticket.type == 0 ) total_tickets_used++;
                    if (ticket[i].type == 0) total_tickets_used++;
                    if (user_ticket.type == 1) total_comments_used++;
                    if (ticket[i].type == 1) total_comments_used++;
                    if (user_ticket.type == 2) total_resolutions_used++;
                    if (ticket[i].type == 2) total_resolutions_used++;

                    if (sort) {
                        sorted_ticket = (sorted_tickets_t *)realloc(sorted_ticket, (sorted_tickets + 1)*sizeof(sorted_tickets_t));
                        strcpy(sorted_ticket[sorted_tickets].support_comment_time, ticket[i].comment_time);
                        sorted_ticket[sorted_tickets].support_ticket_id = ticket[i].ticket_id;
                        sorted_ticket[sorted_tickets].support_comment_id = ticket[i].comment_id;
                        sorted_ticket[sorted_tickets].support_type = ticket[i].type;
                        strcpy(sorted_ticket[sorted_tickets].user_comment_time, user_ticket.comment_time);
                        sorted_ticket[sorted_tickets].user_ticket_id = user_ticket.ticket_id;
                        sorted_ticket[sorted_tickets].user_comment_id = user_ticket.comment_id;
                        sorted_ticket[sorted_tickets].user_type = user_ticket.type;
                        sorted_ticket[sorted_tickets].time_diff_minutes = ceil(time_diff/60.0);
                        sorted_tickets++;
                    } else if (debug) {
                        if (user_ticket.type == 0) {
                            printf("https://support.kolmisoft.com/tickets/ticket_show/%d [\e[1;32m%0.0f\e[0m]\n", user_ticket.ticket_id, ceil(time_diff/60.0));
                        } else {
                            printf("https://support.kolmisoft.com/tickets/ticket_show/%d#comment_%d [\e[1;32m%0.0f\e[0m]\n", user_ticket.ticket_id, user_ticket.comment_id, ceil(time_diff/60.0));
                        }
                    }

                    avgtime += ceil(time_diff/60.0); // average time in minutes
                    count++;
                }
            } else {
                continue;
            }

        }
    }

    // sort by time diff
    if (sort) qsort((void *)sorted_ticket, sorted_tickets, sizeof(sorted_tickets_t), (compfn)compare_time_diff);

    if (sort) {
        for (i = 0; i < sorted_tickets; i++) {
            if (sorted_ticket[i].user_type == 0) {
                printf("https://support.kolmisoft.com/tickets/ticket_show/%d [\e[1;32m%d\e[0m]\n", sorted_ticket[i].user_ticket_id, sorted_ticket[i].time_diff_minutes);
            } else {
                printf("https://support.kolmisoft.com/tickets/ticket_show/%d#comment_%d [\e[1;32m%d\e[0m]\n", sorted_ticket[i].user_ticket_id, sorted_ticket[i].user_comment_id, sorted_ticket[i].time_diff_minutes);
            }
        }
    }

    // calculate average time
    if (count > 0) {
        avgtime = ceil(avgtime/count);
    } else {
        avgtime = 0;
    }

    // insert 'avg_support_response_time' into conflines if not exists
    if (mysql_query(&mysql, "INSERT INTO conflines (name, value, owner_id) SELECT * FROM (SELECT 'avg_support_response_time', '1', '0') AS tmp WHERE NOT EXISTS (SELECT name FROM conflines WHERE name = 'avg_support_response_time') LIMIT 1;")) {
        printf("%s\n", mysql_error(&mysql));
    }

    // update average time value
    sprintf(query, "UPDATE conflines SET value='%.0f' WHERE name='avg_support_response_time';", avgtime);

    if (custom_period || debug || sort) {
        if ((debug || sort) && custom_period) printf("\n\n");
        if (custom_period) printf("Period: %s - %s\n", start_time, custom_end_time ? end_time : "now");
        printf("Total tickets: %ld (%ld)\n", total_tickets, total_tickets_used);
        printf("Total comments: %ld (%ld)\n", total_comments, total_comments_used);
        printf("Total resolutions: %ld (%ld)\n", total_resolutions, total_resolutions_used);
        printf("Average response time: %.0f minutes\n", avgtime);
    } else {
        printf("Average response time for last week is %.0f minutes\n", avgtime);
        printf("Sending data to database...\n");
        if (mysql_query(&mysql, query)) {
            printf("%s\n", mysql_error(&mysql));
            exit(1);
        } else {
            printf("Done.\n");
        }
    }

    mysql_close(&mysql);

    return 0;
}

int db_connect(const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag) {
    if (!mysql_init(&mysql)) {
        printf("MySQL error: %s", mysql_error(&mysql));
        return 1;
    }

    if (!mysql_real_connect(&mysql, host, user, pass, db, port, socket, cflag)) {
        printf("MySQL error: %s", mysql_error(&mysql));
        return 1;
    }

    return 0;
}

int time_diff_in_seconds(char *user_date, char *support_date) {
    int weekends = 0;
    int adjust_weekend = 0;
    int day_diff = 0;
    int day_jump = 0;
    int user_total_seconds, support_total_seconds;
    struct tm tmm;
    int user_daytype = 0;    // day of the week (0 - workweek; 1 - weekend)
    int support_daytype = 0; // day of the week (0 - workweek; 1 - weekend)

    // check if user comment was made during a weekend or a workweek
    strptime(user_date, DATEFORMAT, &tmm);
    if (tmm.tm_wday == 0 || tmm.tm_wday == 6) user_daytype = 1;
    strptime(support_date, DATEFORMAT, &tmm);
    if (tmm.tm_wday == 0 || tmm.tm_wday == 6) support_daytype = 1;

    // get user time
    int user_days    = (user_date[8] - 48)*10 + user_date[9] - 48;
    int user_hours   = (user_date[11] - 48)*10 + user_date[12] - 48;
    int user_minutes = (user_date[14] - 48)*10 + user_date[15] - 48;
    int user_seconds = (user_date[17] - 48)*10 + user_date[18] - 48;

    // get support time
    int support_months  = (support_date[5] - 48)*10 + support_date[6] - 48;
    int support_days    = (support_date[8] - 48)*10 + support_date[9] - 48;
    int support_hours   = (support_date[11] - 48)*10 + support_date[12] - 48;
    int support_minutes = (support_date[14] - 48)*10 + support_date[15] - 48;
    int support_seconds = (support_date[17] - 48)*10 + support_date[18] - 48;

    // do not calculate time difference if both user and support responded on weekend
    if (user_daytype == 1 && support_daytype == 1) {
        return 0;
    }

    // do not calculate time difference if both user and support responded after work hours
    if ((user_hours >= WORK_HOURS_END || user_hours < WORK_HOURS_START) && (support_hours >= WORK_HOURS_END || support_hours < WORK_HOURS_START)) {
        return 0;
    }

    // user posted comment on workweek and support answered on weekend
    if (user_daytype == 0 && support_daytype == 1) {
        adjust_weekend = 1;
    // user posted comment on weekend and support answered on workweek
    } else if (user_daytype == 1 && support_daytype == 0) {
        adjust_weekend = 1;
        day_jump = 1;
    }

    // adjust time if user posted comment after work hours and support responded next day during work hours
    if ((user_hours >= WORK_HOURS_END || user_hours < WORK_HOURS_START) && (support_hours < WORK_HOURS_END && support_hours >= WORK_HOURS_START)) {
        user_hours   = WORK_HOURS_START;
        user_minutes = 0;
        user_seconds = 0;
        day_jump = 1;
    } else if ((support_hours >= WORK_HOURS_END || support_hours < WORK_HOURS_START) && (user_hours < WORK_HOURS_END && user_hours >= WORK_HOURS_START)) { // adjust time if user posted comment during work hours and support responded after work hours
        support_hours   = WORK_HOURS_END - 1;
        support_minutes = 59;
        support_seconds = 59;
        day_jump = 1;
    }

    if (support_days > user_days) {
        day_diff = support_days - user_days;
    } else if (user_days > support_days) {

        int month_days = 0;

        // how many days in support month?
        month_days = get_days_in_month(support_months);

        day_diff = (month_days - user_days) + support_days;

    } else {
        day_diff = 0;
    }

    if (adjust_weekend) day_diff = 1;
    if (adjust_weekend) day_diff = 1;

    if (day_diff > 2) {
        weekends = count_weekends(user_date, day_diff);
    }

    // calculate total time in seconds
    user_total_seconds    = user_hours*3600 + user_minutes*60 + user_seconds;
    support_total_seconds = support_hours*3600 + support_minutes*60 + support_seconds - (weekends*(WORK_HOURS_END - WORK_HOURS_START)*3600);

    // calculate time difference
    if(day_diff) {
        
        if (day_jump == 0) {
            return (support_total_seconds - WORK_HOURS_START*3600) + (WORK_HOURS_END*3600 - user_total_seconds) + (day_diff - 1)*(WORK_HOURS_END - WORK_HOURS_START)*3600;
        } else {
            return support_total_seconds - user_total_seconds + (day_diff - 1)*(WORK_HOURS_END - WORK_HOURS_START)*3600;
        }

    } else {

        return support_total_seconds - user_total_seconds;

    }

}

int get_conf(conf_t *conf) {

    char val[64], var[64];
    int found = 0;

    FILE *file = fopen(CONFPATH, "r");

    if (file == NULL) {
        fprintf(stderr, "Cannot openconfiguration file %s\n", CONFPATH);
        return 1;
    }

    while (fscanf(file, "%s", var) != EOF) {
        if (strcmp(var, "production:") && !found) continue;
        found = 1;
        if (strcmp(var, "host:") == 0) {
            fscanf(file, "%s", val);
            strcpy(conf->host, val);
        }
        if (strcmp(var, "username:") == 0) {
            fscanf(file, "%s", val);
            strcpy(conf->username, val);
        }
        if (strcmp(var, "password:") == 0) {
            fscanf(file, "%s", val);
            if (val[strlen(val) - 1] == ':') strcpy(val, "");
            strcpy(conf->password, val);
        }
        if (strcmp(var, "database:") == 0) {
            fscanf(file, "%s", val);
            strcpy(conf->database, val);
        }
    }

    fclose(file);

    return 0;
}

// ticket_id compare function
int compare_ticket_id(tickets_t *a, tickets_t *b) {
  return a->ticket_id - b->ticket_id;
}

// time_difff compare function
int compare_time_diff(sorted_tickets_t *a, sorted_tickets_t *b) {
  return a->time_diff_minutes - b->time_diff_minutes;
}

// fast time compare function (for qsort)
int compare_time(tickets_t *a, tickets_t *b) {
    int i;

    for (i = 0; i < 20; i++) {
        if (a->comment_time[i] > b->comment_time[i]) {
            return 1;
        } else if (a->comment_time[i] < b->comment_time[i]) {
            return -1;
        }
    }

    return 1;
}

int count_weekends(char *user_date, int day_diff) {
    struct tm tmm_user;
    int weekends = 0;
    int i = 0;
    char new_user_date[20] = { 0 };

    int user_years   = (user_date[0] - 48)*1000 + (user_date[1] - 48)*100 + (user_date[2] - 48)*10 + (user_date[3] - 48);
    int user_months  = (user_date[5] - 48)*10 + user_date[6] - 48;
    int user_days    = (user_date[8] - 48)*10 + user_date[9] - 48;
    int user_hours   = (user_date[11] - 48)*10 + user_date[12] - 48;
    int user_minutes = (user_date[14] - 48)*10 + user_date[15] - 48;
    int user_seconds = (user_date[17] - 48)*10 + user_date[18] - 48;

    for (i = 1; i < day_diff; i++) {

        user_days += 1;

        if (user_days > get_days_in_month(user_months)) {
            user_days = 1;
            user_months++;
            if (user_months > 12) {
                user_months = 0;
                user_years++;
            }
        }

        sprintf(new_user_date, "%d-%d-%d %d:%d:%d", user_years, user_months, user_days, user_hours, user_minutes, user_seconds);

        strptime(new_user_date, DATEFORMAT, &tmm_user);
        if (tmm_user.tm_wday == 0 || tmm_user.tm_wday == 6) weekends++;
    }

    return weekends;
}

int get_days_in_month(int month) {

    int month_days = 0;

    if (month == 1) month_days = 31;
    if (month == 2) {
        if (month % 400 == 0) {
           month_days = 29;
        } else if (month % 100 == 0) {
           month_days = 28;
        } else if (month % 4 == 0) {
           month_days = 29;
        } else {
           month_days = 28;
       }
    }
    if (month == 3) month_days = 31;
    if (month == 4) month_days = 30;
    if (month == 5) month_days = 31;
    if (month == 6) month_days = 30;
    if (month == 7) month_days = 31;
    if (month == 8) month_days = 31;
    if (month == 9) month_days = 30;
    if (month == 10) month_days = 31;
    if (month == 11) month_days = 30;
    if (month == 12) month_days = 31;

    return month_days;
}
