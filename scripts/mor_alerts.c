// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script checks various user call data and alerts if limits are reached


#define SCRIPT_VERSION "1.1"
#define SCRIPT_NAME    "mor_alerts"

#include "mor_functions.c"
#include "mor_alerts.h"

// GLOBAL VARIABLES

// dynamic list
alerts_t *alerts = NULL;
unsigned long int alerts_count = 0;

// dynamic calls list
calls_index_t calls[DATA_PACKETS];

// last call ID
unsigned long long int last_call_id = 0;

// owner email data
email_data_t *email;
int email_count = 0;

// time variables
char date_str[100];
int current_hour;
int current_min;
int current_day;

// get alerts on first start up
int forced_update = 1;

int debug = 0;

// will be set to one on alert/clear
// this variable is used by alert groups
int global_alert_is_changed = 0;

// FUNCTION DECLARATIONS

int get_alerts();
int get_calls_data();
unsigned long long int mysql_last_call_id();
int update_data(int add);
int check_alerts();
int report_alert(alerts_t *alert, data_info_t *data, int report);
int get_email_data(int owner_id);
int get_contacts(alerts_t *alert);
int get_schedules(alerts_t *alert);
int check_if_alerts_need_update();
int before_start();
void initialize_buffers();
int process_buffers();
double calculate_aggregated_data(int alert_type, double data_sum, long int data_count);
int get_email_owner_index(int owner_id);
int update_email_details();
void increment_clear_period();
void check_clear_date();
void *update_time();
void email_action_log(int user_id, char *email, int status, char *error);
void alert_action_log(char *msg, int alert, int alert_id);

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    // error file
    FILE *tmp_errorfile = fopen(LOG_PATH, "a+");

    if (tmp_errorfile == NULL) {
        fprintf(stderr, "Cannot open log file " LOG_PATH);
        return 1;
    }

    if (mor_check_process_lock()) exit(1);

    fclose(tmp_errorfile);

    // Our process ID and Session ID
    pid_t pid, sid;

    // Fork off the parent process
    pid = fork();
    if (pid < 0) {
        exit(1);
    }

    // If we got a good PID, then we can exit the parent process.
    if (pid > 0) {
        exit(0);
    }

    // Change the file mode mask
    umask(0);

    // Create a new SID for the child process
    sid = setsid();
    if (sid < 0) {
        // Log the failure
        exit(EXIT_FAILURE);
    }

    // Change the current working directory
    if ((chdir("/")) < 0) {
        // Log the failure
        exit(EXIT_FAILURE);
    }

    // Close out the standard file descriptors
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);

    if (argc > 1) {
        debug = 1;
    }

    // // create thread with detached state
    pthread_attr_t tattr;
    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_DETACHED);

    // timer that updates current time every second
    // we use separate thread to minimize the execution of time functions
    // lets say we call mor_log 1000 times, then we call time functions 1000 times
    // so updating time every second ir more efficient
    pthread_t timer;
    pthread_create(&timer, &tattr, update_time, NULL);
    sleep(1);

    system("mkdir -p /tmp/mor/alerts");
    system("chmod 777 -R /tmp/mor/alerts");
    system("cd /tmp/mor/alerts && find . -name '*' | xargs rm -fr");

    // just a counter that increments every second
    // it is used for timing
    unsigned int counter = 0;

    // starting sript
    mor_init("Starting Alerts daemon\n");
    // check if everything is ok with database
    if (before_start()) exit(1);
    // get email data
    if (get_email_data(0)) exit(1);
    // initialize calls index table
    memset(&calls[0], 0, DATA_PACKETS * sizeof(calls_index_t));
    // get last call_id
    last_call_id = mysql_last_call_id(&mysql);
    // log message
    mor_log("Last call ID: %llu\n", last_call_id);

    while (1) {

        // get new alerts data
        if ((counter % ((CHECK_IF_UPDATE + 30) / 30)) == 0) if (get_alerts()) exit(1);

        mysql_query(&mysql, "INSERT INTO active_calls_data(time, count) VALUES(NOW(), (SELECT count(id) FROM activecalls))");
        if ((counter % ((DELETE_OLD_AC_DATA + 30) / 30)) == 0) {
            mysql_query(&mysql, "DELETE FROM active_calls_data WHERE time < DATE_SUB(NOW(), INTERVAL 2 DAY)");
        }

        if (alerts_count > 0) {

            // GET, UPDATE AND DELETE DATA
            if (update_data(0)) exit(1); // remove old data
            if (get_calls_data()) exit(1); // get latest calls
            if (update_data(1)) exit(1); // add new data

            // CHECK ALERTS
            if (check_alerts()) exit(1);

            increment_clear_period();
            check_clear_date();

            if ((counter % ((UPDATE_EMAILS_EVERY + 30) / 30)) == 0) {
                update_email_details();
            }

        }  else {
            sleep(DATA_TICK_TIME);
        }

        counter++;

    }

    return 0;

}


/*

    ############  FUNCTIONS #######################################################

*/


/*
    Function checks if alerts need to be updated
    Update is needed if alerts, schedules, contacts or groups are modified in any way
*/

int check_if_alerts_need_update() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // defaul state id 'alerts dont need an update'
    int need_update = 0;

    // lets check if alerts, contact, schedules or groups have been modified
    // gui sets 'alerts_need_update' value to 1 when any of those pages are created/updated/removed
    if (mor_mysql_query("SELECT value FROM conflines WHERE name = 'alerts_need_update'")) {
        return -1;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            // get integer value
            if (row[0]) need_update = atoi(row[0]);
        }
    }

    mysql_free_result(result);

    return need_update;

}

/*
    Convert alert type string value to integer
*/

int alert_get_alert_type(const char *alert_type) {
    int type = 0;

    if (strcmp(alert_type, "calls_total") == 0) {
        type = 1;
    } else if (strcmp(alert_type, "calls_answered") == 0) {
        type = 2;
    } else if (strcmp(alert_type, "calls_not_answered") == 0) {
        type = 3;
    } else if (strcmp(alert_type, "asr") == 0) {
        type = 4;
    } else if (strcmp(alert_type, "acd") == 0) {
        type = 5;
    } else if (strcmp(alert_type, "pdd") == 0) {
        type = 6;
    } else if (strcmp(alert_type, "ttc") == 0) {
        type = 7;
    } else if (strcmp(alert_type, "billsec_sum") == 0) {
        type = 8;
    } else if (strcmp(alert_type, "price_sum") == 0) {
        type = 9;
    } else if (strcmp(alert_type, "sim_calls") == 0) {
        type = 10;
    } else if (strcmp(alert_type, "hgc_absolute") == 0) {
        type = 11;
    } else if (strcmp(alert_type, "hgc_percent") == 0) {
        type = 12;
    } else if (strcmp(alert_type, "group") == 0) {
        type = 13;
    }

    if (type) {
        return type;
    } else {
        mor_log("Alert type can't be 0! (%s)\n", alert_type);
        exit(1);
    }
}

/*
    Convert alert count type string value to integer
*/

int alert_get_alert_count_type(const char *alert_count_type) {
    int type = 0;

    if (strcmp(alert_count_type, "ABS") == 0) type = 1;
    if (strcmp(alert_count_type, "DIFF") == 0) type = 2;

    if (type) {
        return type;
    } else {
        mor_log("Alert count type can't be 0! (%s)\n", alert_count_type);
        exit(1);
    }
}

/*
    Convert check type string value to integer
*/

int alert_get_check_type(const char *check_type) {
    int type = 0;

    if (strcmp(check_type, "user") == 0) type = 1;
    if (strcmp(check_type, "provider") == 0) type = 2;
    if (strcmp(check_type, "device") == 0) type = 3;
    if (strcmp(check_type, "destination") == 0) type = 4;
    if (strcmp(check_type, "destination_group") == 0) type = 5;

    if (type) {
        return type;
    } else {
        mor_log("Alert check type can't be 0! (%s)\n", check_type);
        exit(1);
    }
}

/*
    Convert check type integer value to string
*/

void alert_get_check_type_string(int check_type_integer, char *check_type) {

    strcpy(check_type, "Unknown");

    if (check_type_integer == 1) strcpy(check_type, "USER");
    if (check_type_integer == 2) strcpy(check_type, "PROVIDER");
    if (check_type_integer == 3) strcpy(check_type, "DEVICE");
    if (check_type_integer == 4) strcpy(check_type, "DESTINATION");
    if (check_type_integer == 5) strcpy(check_type, "DESTINATION GROUP");

}

/*
    Convert object id to object name string
*/

void alert_get_object_name_string(alerts_t *alert, int data_id, char *object_name) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";

    if (alert->check_type > 3) {
        sprintf(object_name, "%s", alert->check_data);
        return;
    } else {
        sprintf(object_name, "%d", data_id);
    }

    if (alert->check_type == 1) sprintf(sqlcmd, "SELECT username FROM users WHERE id = %d", data_id);
    if (alert->check_type == 2) sprintf(sqlcmd, "SELECT name FROM providers WHERE id = %d", data_id);
    if (alert->check_type == 3) sprintf(sqlcmd, "SELECT name FROM devices WHERE id = %d", data_id);

    if (mor_mysql_query(sqlcmd)) return;
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) sprintf(object_name, "%s", row[0]);
        }
    }

}

/*
    Log alerts
*/

void show_alerts() {

    int i = 0;

    if (alerts_count > 0) mor_log("Alerts:\n");

    for (i = 0; i < alerts_count; i++) {
        mor_log("id: %d\n", alerts[i].id);
        mor_log("status: %d\n", alerts[i].status);
        mor_log("alert type: %d\n", alerts[i].alert_type);
        mor_log("alert count type: %d\n", alerts[i].alert_count_type);
        mor_log("check type: %d\n", alerts[i].check_type);
        mor_log("check data: %s\n", alerts[i].check_data);
        mor_log("value at alert: %.3f\n", alerts[i].value_at_alert);
        mor_log("alert if less: %.3f\n", alerts[i].alert_if_less);
        mor_log("alert if more: %.3f\n", alerts[i].alert_if_more);
        mor_log("value at clear: %.3f\n", alerts[i].value_at_clear);
        mor_log("clear if less: %.3f\n", alerts[i].clear_if_less);
        mor_log("clear if more: %.3f\n", alerts[i].clear_if_more);
        mor_log("ignore if calls less: %ld\n", alerts[i].ignore_if_calls_less);
        mor_log("ignore if calls more: %ld\n", alerts[i].ignore_if_calls_more);
        mor_log("action alert email: %d\n", alerts[i].action_alert_email);
        mor_log("action alert sms: %d\n", alerts[i].action_alert_sms);
        mor_log("action alert disable: %d\n", alerts[i].action_alert_disable_object);
        mor_log("action alert change lcr id: %u\n", alerts[i].action_alert_change_lcr_id);
        mor_log("action clear email: %d\n", alerts[i].action_clear_email);
        mor_log("action clear sms: %d\n", alerts[i].action_clear_sms);
        mor_log("action clear disable: %d\n", alerts[i].action_clear_enable_object);
        mor_log("action clear change lcr id: %d\n", alerts[i].action_clear_change_lcr_id);
        mor_log("before alert original lcr id: %d\n", alerts[i].before_alert_original_lcr_id);
        mor_log("alert groups id: %u\n", alerts[i].alert_groups_id);
        mor_log("disable clear: %u\n", alerts[i].disable_clear);
        mor_log("disable provider in lcr: %u\n", alerts[i].action_alert_disable_object_in_lcr);
        mor_log("enable provider in lcr: %u\n", alerts[i].action_clear_enable_object_in_lcr);
        mor_log("owner id: %d\n", alerts[i].owner_id);
        mor_log("clear_after: %" PRIu64 "\n", alerts[i].clear_period);
        mor_log("clear_date: %s\n", alerts[i].clear_date);
        mor_log("check_period: %d\n", alerts[i].raw_period);
        mor_log("notify to user: %d\n", alerts[i].notify_to_user);
        mor_log("hgc: %d\n", alerts[i].hgc);

        if (alerts[i].alert_type == 13) {
            mor_log("alert groups: %s\n", alerts[i].alert_group_id_list);
            mor_log("alert if more than: %d\n", alerts[i].alert_if_more_than);
            mor_log("alert if less than: %d\n", alerts[i].clear_if_less_than);
        }

        mor_log("comment: %s\n\n", alerts[i].comment);

        if (alerts[i].alert_groups_id > 0) {
            contact_t *current = alerts[i].group->contact;

            while (current) {
                mor_log("contact email = %s\n", current->email);
                mor_log("contact id = %d\n", current->id);

                schedule_t *current_s = alerts[i].group->schedule;

                while (current_s) {
                    mor_log("daytype = %d\n", current_s->daytype);
                    mor_log("start = %s\n", current_s->start);
                    mor_log("end = %s\n", current_s->end);

                    current_s = current_s->prev;
                }

                current = current->prev;
                mor_log("------------------------\n\n");
            }
        }

    }

}

/*
    Calculates last index of calls array, based on period in minutes
*/

int calculate_period(long long int minutes) {

    // last index is needed for alerts to have different periods
    // lets say we have maximum period of 60 seconds and we get new calls every 15 seconds
    // so we have 60 / 15 = 4 packets in our calls array: [0 1 2 3]
    // if an alerts has a period of 30 seconds, then the last index is 2
    // note: actually we have minutes not seconds

    return ((minutes * 60) / DATA_TICK_TIME) - 1;

}

/*
    Get all alerts from database
*/

int get_alerts() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // check if this is our initial daemon run
    // if so, we need to force alert update, because we dont have anu alerts at the moment
    if (!forced_update) {

        // if this is not initial daemon run, we need to check if alerts have been modified
        int res = check_if_alerts_need_update();

        // res = -1 means error
        // res =  1 means alerts need update
        // res =  0 means alerts dont need update

        if (res == -1) {
            mor_mysql_reconnect();
            return 0;
        } else if (res != 1) {
            return 0;
        }
    }

    mor_log("Alerts updated. Rereading data...\n");

    // for alert groups
    global_alert_is_changed = 1;

    // do not force again
    forced_update = 0;

    if (mor_mysql_query("SELECT alerts.id, alert_type, alert_count_type, check_type, check_data, value_at_alert, "
                        "alert_if_less, alert_if_more, value_at_clear, clear_if_less, clear_if_more, ignore_if_calls_less, "
                        "ignore_if_calls_more, status, action_alert_email, action_alert_sms, "
                        "action_alert_disable_object, action_alert_change_lcr_id, action_clear_email, action_clear_sms, "
                        "action_clear_enable_object, action_clear_change_lcr_id, before_alert_original_lcr_id, "
                        "alert_groups_id, count_period, disable_clear, owner_id, comment, disable_provider_in_lcr, "
                        "enable_provider_in_lcr, clear_after, clear_on_date, 0, -1 "
                        "FROM alerts "
                        "WHERE status = 1 ")) {

        mor_mysql_reconnect();
        return 0;

    }

    // allocate memory to save old data
    // we will save old alerts to preserve aggregated data (like total calls, average billsec, ...)
    // and later delete not existing/disabled alerts
    alerts_tmp_data_t *alerts_tmp = malloc(alerts_count * sizeof(alerts_tmp_data_t));

    int i = 0, j = 0;
    int old_alerts_count = alerts_count;

    // save old alerts IDs and pointers to aggregated data
    for (i = 0; i < alerts_count; i++) {
        alerts_tmp[i].id = alerts[i].id; // old IDs
        alerts_tmp[i].addr = alerts[i].data_info; // old pointers to aggregated data
        alerts_tmp[i].found = 0; // this will be used to match old alerts with new alerts
    }

    // also, we will update all contacts and schedules

    // free old contacts
    for (i = 0; i < alerts_count; i++) {
        if (alerts[i].alert_groups_id > 0) {
            contact_t *current = alerts[i].group->contact;
            contact_t *prev = alerts[i].group->contact;
            while (current != NULL) {
                prev = current->prev;
                free(current);
                current = prev;
            }
        }
    }

    // free old schedules
    for (i = 0; i < alerts_count; i++) {
        if (alerts[i].alert_groups_id > 0) {
            schedule_t *current = alerts[i].group->schedule;
            schedule_t *prev = alerts[i].group->schedule;
            while (current != NULL) {
                prev = current->prev;
                free(current);
                current = prev;
            }
        }
    }

    // clear alerts memory
    memset(alerts, 0, alerts_count * sizeof(alerts_t));
    alerts_count = 0;

    result = mysql_store_result(&mysql);

    // fill alerts list
    while ((row = mysql_fetch_row(result)) != NULL) {

        alerts = realloc(alerts, (alerts_count + 1) * sizeof(alerts_t));
        memset(&alerts[alerts_count], 0, sizeof(alerts_t));

        if (row[0]) alerts[alerts_count].id = atoi(row[0]);
        if (row[1]) alerts[alerts_count].alert_type = alert_get_alert_type(row[1]);
        if (row[2]) {
            alerts[alerts_count].alert_count_type = alert_get_alert_count_type(row[2]);
        } else {
            alerts[alerts_count].alert_count_type = 1;
        }
        if (row[3]) alerts[alerts_count].check_type = alert_get_check_type(row[3]);
        if (row[4]) strcpy(alerts[alerts_count].check_data, row[4]);
        if (row[5]) alerts[alerts_count].value_at_alert = atof(row[5]);
        if (row[6]) alerts[alerts_count].alert_if_less = atof(row[6]);
        if (row[7]) alerts[alerts_count].alert_if_more = atof(row[7]);
        if (row[8]) alerts[alerts_count].value_at_clear = atof(row[8]);
        if (row[9]) alerts[alerts_count].clear_if_less = atof(row[9]);
        if (row[10]) alerts[alerts_count].clear_if_more = atof(row[10]);
        if (row[11]) alerts[alerts_count].ignore_if_calls_less = atol(row[11]);
        if (row[12]) alerts[alerts_count].ignore_if_calls_more = atol(row[12]);
        if (row[13]) if (strcmp("enabled", row[13]) == 0) alerts[alerts_count].status = 1;
        if (row[14]) alerts[alerts_count].action_alert_email = atoi(row[14]);
        if (row[15]) alerts[alerts_count].action_alert_sms = atoi(row[15]);
        if (row[16]) alerts[alerts_count].action_alert_disable_object = atoi(row[16]);
        if (row[17]) alerts[alerts_count].action_alert_change_lcr_id = atoi(row[17]);
        if (row[18]) alerts[alerts_count].action_clear_email = atoi(row[18]);
        if (row[19]) alerts[alerts_count].action_clear_sms = atoi(row[19]);
        if (row[20]) alerts[alerts_count].action_clear_enable_object = atoi(row[20]);
        if (row[21]) alerts[alerts_count].action_clear_change_lcr_id = atoi(row[21]);
        if (row[22]) alerts[alerts_count].before_alert_original_lcr_id = atoi(row[22]);
        if (row[23]) alerts[alerts_count].alert_groups_id = atoi(row[23]);
        if (row[24]) alerts[alerts_count].raw_period = atoi(row[24]);
        if (row[25]) alerts[alerts_count].disable_clear = atoi(row[25]);
        if (row[26]) alerts[alerts_count].owner_id = atoi(row[26]);
        if (row[27]) strcpy(alerts[alerts_count].comment, row[27]);
        if (row[28]) alerts[alerts_count].action_alert_disable_object_in_lcr = atoi(row[28]);
        if (row[29]) alerts[alerts_count].action_clear_enable_object_in_lcr = atoi(row[29]);
        if (row[30]) alerts[alerts_count].clear_period = atoll(row[30])*60;
        if (row[31]) strcpy(alerts[alerts_count].clear_date, row[31]);
        if (row[32]) alerts[alerts_count].notify_to_user = atoi(row[32]);
        if (row[33]) alerts[alerts_count].hgc = atoi(row[33]);

        strcpy(alerts[alerts_count].alert_group_id_list, "");
        alerts[alerts_count].alert_if_more_than = 0;
        alerts[alerts_count].clear_if_less_than = 0;

        // get email data for alert owner
        int email_index = get_email_owner_index(alerts[alerts_count].owner_id);
        if (email_index == -1) get_email_data(alerts[alerts_count].owner_id);

        if (alerts[alerts_count].raw_period > 0) {
            alerts[alerts_count].period = calculate_period(alerts[alerts_count].raw_period);
        } else {
            alerts[alerts_count].period = DATA_PACKETS - 1; // default 1 hour
        }


        // initial aggregated data
        alerts[alerts_count].data_info = malloc(sizeof(data_info_t));
        memset(alerts[alerts_count].data_info, 0, sizeof(data_info_t));
        alerts[alerts_count].data_info->id = -2; // -2 = empty, -1 = prefix
        alerts[alerts_count].data_info->user_id = -2; // -2 = empty, we need to save user_id to prevent SQL JOINS when we have just device ID
        alerts[alerts_count].data_info->data_count = 0; // number of aggregated data
        alerts[alerts_count].data_info->data_sum = 0; // sum of aggregated data
        alerts[alerts_count].data_info->alert_is_set = 0; // indication of alert status (1 = alerts is set, 0 - alert is not set)
        alerts[alerts_count].data_info->clear_period_countdown = 0; // initialization
        alerts[alerts_count].data_info->clear_period_counter = 0; // initialization
        alerts[alerts_count].data_info->next = NULL; // pointer to next data node (only when we have user = all/postpaid/prepaid, otherwise there is only one node)

        if (alerts[alerts_count].check_type == 4) { // is check type = prefix? if so, we dont have an ID
            alerts[alerts_count].data_info->id = -1; // dont have ID
        } else if (!strstr("allpostpaidprepaid", alerts[alerts_count].check_data)) { // is this prefix/prepaid/postpaid/all users? if not, lets take the ID
            alerts[alerts_count].data_info->id = atoi(row[4]);
        }

        alerts_count++;

    }

    mysql_free_result(result);

    // get new contacts
    for (i = 0; i < alerts_count; i++) {
        if (alerts[i].alert_groups_id > 0)
            if (get_contacts(&alerts[i])) return 1;
    }

    // get new schedules
    for (i = 0; i < alerts_count; i++) {
        if (alerts[i].alert_groups_id > 0)
            if (get_schedules(&alerts[i])) return 1;
    }

    // re-assgin data nodes to correct alert
    for (i = 0; i < alerts_count; i++) {
        for (j = 0; j < old_alerts_count; j++) {
            if (alerts[i].id == alerts_tmp[j].id) {
                alerts[i].data_info = alerts_tmp[j].addr;
                alerts_tmp[j].found = 1;
            }
        }
    }

    // free data nodes that do not have matching alert
    for (i = 0; i < old_alerts_count; i++) {
        if (alerts_tmp[i].found == 0) {
            data_info_t *current = alerts_tmp[i].addr, *next = NULL;
            while (current != NULL) {
                next = current->next;
                free(current);
                current = next;
            }
        }
    }

    // get user alerts
    if (mor_mysql_query("UPDATE conflines SET value = '0' WHERE name = 'alerts_need_update'")) {
        return 1;
    };

    free(alerts_tmp);

    show_alerts();

    return 0;

}

/*
    Check if call is answered by comparing disposition
*/

int check_if_call_answered(const char *disposition) {

    int answered = -1;

    if (strcmp(disposition, "ANSWERED") == 0) answered = 1;
    if (strcmp(disposition, "BUSY") == 0) answered = 0;
    if (strcmp(disposition, "FAILED") == 0) answered = 0;
    if (strcmp(disposition, "NO ANSWER") == 0) answered = 0;

    if (answered != -1) {
        return answered;
    } else {
        mor_log("Can't determine disposition: %s\n", disposition);
        exit(1);
    }

}

/*
    Get calls from database
*/

int get_calls_data() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // printf("Get calls!\n");

    char sqlcmd[2048] = "";

    unsigned long int calls_data_count = 0;
    calls_data_t *calls_data = NULL;

    sprintf(sqlcmd, "SELECT calls.id, user_id, provider_id, disposition, duration, billsec, "
                    "call_details.pdd, users.postpaid, calls.prefix, accountcode, destinationgroup_id, user_price, provider_price, users.lcr_id, "
                    "hangupcause, 0 FROM calls "
                    "LEFT JOIN users ON users.id = calls.user_id "
                    "LEFT JOIN destinations ON destinations.prefix = calls.prefix "
                    "LEFT JOIN call_details ON call_details.call_id = calls.id WHERE calls.id > %llu", last_call_id);

    if (mor_mysql_query(sqlcmd)) {
        mor_mysql_reconnect();
        return 0;
    }

    // lets create new node for current calls batch
    calls_data = malloc(sizeof(calls_data_t));
    memset(calls_data, 0, sizeof(calls_data_t));

    result = mysql_store_result(&mysql);

    // fill this node
    while ((row = mysql_fetch_row(result)) != NULL) {

        calls_data = realloc(calls_data, (calls_data_count + 1) * sizeof(calls_data_t));
        memset(&calls_data[calls_data_count], 0, sizeof(calls_data_t));

        if (row[1]) calls_data[calls_data_count].user_id = atoi(row[1]);
        if (row[2]) calls_data[calls_data_count].provider_id = atoi(row[2]);
        if (row[3]) calls_data[calls_data_count].answered = check_if_call_answered(row[3]);
        if (row[4]) calls_data[calls_data_count].duration = atol(row[4]);
        if (row[5]) calls_data[calls_data_count].billsec = atol(row[5]);
        if (row[6]) calls_data[calls_data_count].pdd = atof(row[6]); else calls_data[calls_data_count].pdd = -1;
        if (row[7]) calls_data[calls_data_count].postpaid = atoi(row[7]);
        if (row[8]) strcpy(calls_data[calls_data_count].prefix, row[8]);
        if (row[9]) calls_data[calls_data_count].device_id = atoi(row[9]);
        if (row[10]) calls_data[calls_data_count].destinationgroup_id = atoi(row[10]);
        if (row[11]) calls_data[calls_data_count].user_price = atof(row[11]);
        if (row[12]) calls_data[calls_data_count].provider_price = atof(row[12]);
        if (row[13]) calls_data[calls_data_count].user_lcr_id = atoi(row[13]);
        if (row[14]) calls_data[calls_data_count].hgc = atoi(row[14]);
        if (row[15]) calls_data[calls_data_count].ignore_alert = atoi(row[15]);
        calls_data[calls_data_count].all = 1;

        // printf("answered = %d\npostpaid = %d\nprefix = %s\ndevice_id = %u\n\n", calls_data[calls_data_count].answered, calls_data[calls_data_count].postpaid, calls_data[calls_data_count].prefix, calls_data[calls_data_count].device_id);

        calls_data_count++;
        last_call_id = atoll(row[0]);

    }

    mysql_free_result(result);

    int last_user_id = 0;
    unsigned long int active_calls_data_count = calls_data_count;

    // get active calls
    sprintf(sqlcmd, "SELECT user_id, count(activecalls.id) as active_calls, postpaid, provider_id FROM activecalls "
                    "INNER JOIN users ON users.id = activecalls.user_id "
                    "GROUP BY user_id "
                    "ORDER BY user_id, active_calls DESC");

    if (mor_mysql_query(sqlcmd)) {
        free(calls_data);
        return 1;
    }

    result = mysql_store_result(&mysql);

    while ((row = mysql_fetch_row(result)) != NULL) {

        if (row[0]) {
            if (last_user_id != atoi(row[0])) {
                if (atoi(row[1]) > 1) {

                    calls_data = realloc(calls_data, (active_calls_data_count + 1) * sizeof(calls_data_t));
                    memset(&calls_data[active_calls_data_count], 0, sizeof(calls_data_t));

                    if (row[0]) calls_data[active_calls_data_count].user_id = atoi(row[0]);
                    if (row[1]) calls_data[active_calls_data_count].user_sim_calls = atoi(row[1]);
                    if (row[2]) calls_data[active_calls_data_count].postpaid = atoi(row[2]);
                    if (row[3]) calls_data[active_calls_data_count].provider_id = atoi(row[3]);
                    calls_data[active_calls_data_count].all = 1;

                    last_user_id = calls_data[active_calls_data_count].user_id;
                    active_calls_data_count++;

                }
            }
        }

    }

    mysql_free_result(result);

    time_t uniqueid = time(NULL);
    char file_buffer[256] = "";
    sprintf(file_buffer, "/tmp/mor/alerts/%lu", uniqueid);
    FILE *fp = fopen(file_buffer, "w");
    if (fp == NULL) return 1;
    unsigned long long int i = 0;
    for (i = 0; i < calls_data_count; i++) {
        char line_buffer[512] = "";
        sprintf(line_buffer, "%i,%i,%i,%li,%li,%.3f,%i,%s,%i,%i,%f,%f,%i,%i,%i\n",
                calls_data[i].user_id, calls_data[i].provider_id, calls_data[i].answered,
                calls_data[i].duration, calls_data[i].billsec, calls_data[i].pdd, calls_data[i].postpaid,
                strlen(calls_data[i].prefix) > 0 ? calls_data[i].prefix : "x", calls_data[i].device_id, calls_data[i].destinationgroup_id,
                calls_data[i].user_price, calls_data[i].provider_price, calls_data[i].user_lcr_id, calls_data[i].hgc, calls_data[i].ignore_alert);
        fprintf(fp, line_buffer);
    }
    fprintf(fp, "-- ACTIVE CALLS --\n");
    for (i = calls_data_count; i < active_calls_data_count; i++) {
        char line_buffer[512] = "";
        sprintf(line_buffer, "%i,%i,%i,%i,%i\n", calls_data[i].user_id, calls_data[i].user_sim_calls, calls_data[i].postpaid, calls_data[i].user_lcr_id, calls_data[i].provider_id);
        fprintf(fp, line_buffer);
    }
    fclose(fp);

    free(calls_data);

    // now remove file, containing the very last period
    if (&calls[DATA_PACKETS - 1]) {
        if (calls[DATA_PACKETS - 1].uniqueid) {
            char tmp_buffer[128] = "";
            sprintf(tmp_buffer, "rm -fr /tmp/mor/alerts/%u", calls[DATA_PACKETS - 1].uniqueid);
            system(tmp_buffer);
        }
    }

    // shift memory because we need to hold data that fits a particular period

    // lets say we have this set: [1, 2, 3, 4, 5] (period is 5 nodes)
    // now we have: [1, 2, 3, 4, empty]
    // move memory
    memmove(&calls[1], &calls[0], ((DATA_PACKETS) - 1) * sizeof(calls_index_t));
    // now we have: [1, 1, 2, 3, 4]
    // assign new node
    calls[0].uniqueid = uniqueid;
    // now we have: [new, 1, 2, 3, 4]

    // memory is shifted! this was very fast

    return 0;

}

/*
    Get last call id from calls table
*/

unsigned long long int mysql_last_call_id() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    unsigned long long int last_call_id = 0;

    // we need last ID to get only new calls at every call update
    // lets say last call id is 1542 then next time we will get calls that have id > 1542
    if (mor_mysql_query("SELECT id FROM calls ORDER BY calldate DESC LIMIT 1")) {
        return 0;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) last_call_id = atoll(row[0]);
        }
    }

    mysql_free_result(result);

    return last_call_id;

}

/*
    Function that gets target id based on check type (target id = user id, device id, provider id, destinationgroup id from ALERTS)
*/

long int get_target_id(alerts_t *alert) {

    if (alert->check_type == 1) {
        if (strstr("allpostpaid", alert->check_data)) {
            return 1; // return 1, this indicates postpaid or all users
        } else if (strcmp(alert->check_data, "prepaid") == 0) {
            return 0; // return 0, this indicates that we have prepaid user (prefix also retur n 0, but the cheking is different so we dont care)
        } else {
            return alert->data_info->id; // return real ID
        }
    }
    if (alert->check_type == 2) {
        if (strstr("all", alert->check_data)) {
            return 1; // return 1, this indicates all providers
        } else {
            return alert->data_info->id; // return real ID
        }
    }
    if (alert->check_type == 3) {
        if (strstr("all", alert->check_data)) {
            return 1; // return 1, this indicates all devices
        } else {
            return alert->data_info->id; // return real ID
        }
    }
    if (alert->check_type == 4) return 0;                    // this is prefix, so we dont care abount ID, checking will be different
    if (alert->check_type == 5) {
        if (strstr("all", alert->check_data)) {
            return 1; // return 1, this indicates all providers
        } else {
            return alert->data_info->id; // return real ID
        }
    }

    return -1;
}

/*
    Function that gets offset based on check type (offset is calculated for user id, device id, provider id, destinationgroup id from CALLS)
*/

int get_check_id_offset(alerts_t *alert) {

    // calls data structure is as follows:

    // int user_id;
    // int provider_id;
    // int device_id;
    // int postpaid;
    // int all;
    // int destinationgroup_id;

    // offset starts at user_id (offset = 0)
    // if offset is 1 then we check provider_id and so on

    if (alert->check_type == 1) {
        if (strcmp(alert->check_data, "all") == 0) return 4; // mark that this record will be used for all users
        else if (strstr("postpaidprepaid", alert->check_data)) return 3; // mark that this record will be used for prepaid users only
        else return 0; // just user ID
    }
    if (alert->check_type == 2) {
        if (strcmp(alert->check_data, "all") == 0) return 4;
        else return 1; // just provider ID
    }
    if (alert->check_type == 3) {
        if (strcmp(alert->check_data, "all") == 0) return 4;
        return 2; // device ID
    }
    if (alert->check_type == 4) return 0; // user ID (but we dont care, since this is prefix and the checking will be different)
    if (alert->check_type == 5) {
        if (strcmp(alert->check_data, "all") == 0) return 4;
        return 5; // destinationgroup ID
    }

    return 0;
}

/*
    Function is used to find a particaular data none by traversing the aggregated nodes and comparing IDs
*/

data_info_t *get_data_address(int id, int user_id, alerts_t *alert, int ignore_alert, int update) {

    // !!!!!!!!!!
    // taget = user/device/provider/destination_group
    // !!!!!!!!!!

    data_info_t *current = alert->data_info;
    data_info_t *last = NULL;

    while (current) {
        if (current->id == id) { // does current node have the same ID as target from calls record? (id == target_id)
            if (alert->check_type == 1 || alert->check_type == 3) {
                current->user_id = user_id; // set user_id
            } else {
                current->user_id = 0;
            }
            if (alert->check_type == 1 && update) {
                current->ignore_alert = ignore_alert;
            } else {
                current->ignore_alert = 0;
            }
            if (debug) {
                mor_log("Object found! Object id: %d\n", id);
            }
            return current; // return pointer tho this node
        }
        last = current;
        current = current->next;
    }

    if (debug) {
        mor_log("New object! Adding new object to alerts data. Object id: %d\n", id);
    }

    // we did not find target so we assume this is a new target so we should track him

    // create new node for this target
    data_info_t *new_data = NULL;
    new_data = malloc(sizeof(data_info_t));

    // fill data

    new_data->id = id;
    if (alert->check_type == 1 || alert->check_type == 3) {
        new_data->user_id = id;
    } else {
        new_data->user_id = 0;
    }
    new_data->data_sum = 0;
    new_data->data_count = 0;
    new_data->alert_is_set = 0;
    new_data->clear_period_countdown = 0;
    new_data->clear_period_counter = 0;
    new_data->user_lcr_id = 0;
    if (alert->check_type == 1 && update) {
        new_data->ignore_alert = ignore_alert;
    } else {
        new_data->ignore_alert = 0;
    }
    new_data->next = NULL;
    last->next = new_data;

    // return pointer to this node

    return new_data;

}

/*
    Function checks if user searching is needed
*/

int get_search(alerts_t *alert) {
    if (strstr("allpostpaidprepaid", alert->check_data)) {
        return 1; // search
    } else {
        return 0; // do not search, use first node
    }
}

/*
    Function that updates every node by aggregating data with current calls data
*/

int update_alert_data(alerts_t *alert, int update, int index) {

    // if update = 1 nodes will be updated with current data
    // if update = 0 old data will removed from nodes

    if (!&calls[index]) {
        if (!calls[index].uniqueid) {
            return 0;
        }
    }

    uint i = 0;
    int target_id = 0; // check data id from alerts
    double value = 0; // this value will be added to aggregated data
    unsigned int count = 0; // if count = 1, node will updated
    int offset = 0; // offset to particular ID in calls packet
    int can_pass = 0; // call record can pass
    int search = 0; // indicated that we need to search for users (postpaid/prepaid/all)
    int alert_type = alert->alert_type;
    int check_type = alert->check_type;
    calls_data_t *calls_data = NULL;
    unsigned long long int calls_data_count = 0;
    unsigned long long int active_calls_data_count = 0;

    // gets offset, id and search indicator
    target_id = get_target_id(alert);
    offset    = get_check_id_offset(alert);
    search    = get_search(alert);

    // current calls packet doesn't have any calls, return
    // if (calls[index].count == 0 && calls[index].a_count == 0) goto sim_check;

    // lets create new node for current calls batch
    calls_data = malloc(sizeof(calls_data_t));
    memset(calls_data, 0, sizeof(calls_data_t));

    char file_buffer[256] = "";
    sprintf(file_buffer, "/tmp/mor/alerts/%u", calls[index].uniqueid);
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int continue_reading = 1;

    FILE *fp = fopen(file_buffer, "r");
    if (fp == NULL) return 0;

    while ((read = getline(&line, &len, fp)) != -1) {

        if (strcmp(line, "-- ACTIVE CALLS --\n") != 0 && continue_reading == 1) {

            calls_data = realloc(calls_data, (calls_data_count + 1) * sizeof(calls_data_t));
            memset(&calls_data[calls_data_count], 0, sizeof(calls_data_t));
            calls_data[calls_data_count].all = 1;

            char * pch;
            pch = strtok(line, ",");
            int tok_count = 1;

            while (pch != NULL) {

                if (tok_count == 1) calls_data[calls_data_count].user_id = atoi(pch);
                if (tok_count == 2) calls_data[calls_data_count].provider_id = atoi(pch);
                if (tok_count == 3) calls_data[calls_data_count].answered = atoi(pch);
                if (tok_count == 4) calls_data[calls_data_count].duration = atol(pch);
                if (tok_count == 5) calls_data[calls_data_count].billsec = atol(pch);
                if (tok_count == 6) calls_data[calls_data_count].pdd = atof(pch); else calls_data[calls_data_count].pdd = -1;
                if (tok_count == 7) calls_data[calls_data_count].postpaid = atoi(pch);
                if (tok_count == 8) strcpy(calls_data[calls_data_count].prefix, pch);
                if (tok_count == 9) calls_data[calls_data_count].device_id = atoi(pch);
                if (tok_count == 10) calls_data[calls_data_count].destinationgroup_id = atoi(pch);
                if (tok_count == 11) calls_data[calls_data_count].user_price = atof(pch);
                if (tok_count == 12) calls_data[calls_data_count].provider_price = atof(pch);
                if (tok_count == 13) calls_data[calls_data_count].user_lcr_id = atoi(pch);
                if (tok_count == 14) calls_data[calls_data_count].hgc = atoi(pch);
                if (tok_count == 15) calls_data[calls_data_count].ignore_alert = atoi(pch);

                tok_count++;
                pch = strtok(NULL, ",");

            }

            // printf("answered = %d postpaid = %d prefix = %s device_id = %u\n", calls_data[calls_data_count].answered, calls_data[calls_data_count].postpaid, calls_data[calls_data_count].prefix, calls_data[calls_data_count].device_id);

            calls_data_count++;

        } else {

            // skip first line
            if (continue_reading) {
                active_calls_data_count = calls_data_count;
                continue_reading = 0;
                continue;
            }

            calls_data = realloc(calls_data, (active_calls_data_count + 1) * sizeof(calls_data_t));
            memset(&calls_data[active_calls_data_count], 0, sizeof(calls_data_t));
            calls_data[active_calls_data_count].all = 1;

            calls_data[active_calls_data_count].all = 1;

            char * pch;
            pch = strtok(line, ",");
            int tok_count = 1;

            while (pch != NULL) {

                if (tok_count == 1) calls_data[active_calls_data_count].user_id = atoi(pch);
                if (tok_count == 2) calls_data[active_calls_data_count].user_sim_calls = atoi(pch);
                if (tok_count == 3) calls_data[active_calls_data_count].postpaid = atoi(pch);
                if (tok_count == 4) calls_data[active_calls_data_count].user_lcr_id = atoi(pch);
                if (tok_count == 5) calls_data[active_calls_data_count].provider_id = atoi(pch);

                tok_count++;
                pch = strtok(NULL, ",");

            }

            // printf("user_id = %d postpaid = %d sim_calls = %u\n", calls_data[active_calls_data_count].user_id, calls_data[active_calls_data_count].postpaid, calls_data[active_calls_data_count].user_sim_calls);

            active_calls_data_count++;

        }
    }

    if (line) free(line);

    fclose(fp);

    if (alert_type == 10) goto sim_check;

    // check ever call record for current calls packet
    for (i = 0; i < calls_data_count; i++) {

        // default values
        value = 0;
        count = 0;
        can_pass = 0;

        // if this is not prefix
        if (check_type != 4) {
            // use offset and target id to check if current call record can pass for this alert
            if (*(&calls_data[i].user_id + offset) == target_id) {
                can_pass = 1;
            }
            // skip admin calls
            if (check_type == 1 && calls_data[i].user_id == 0) {
                can_pass = 0;
            }
        } else {
            // this is prefix so we do checking by comparing prefix string
            if (alert->check_data[strlen(alert->check_data) - 1] == '%') {
                if (strncmp(alert->check_data, calls_data[i].prefix, strlen(alert->check_data) - 1) == 0) can_pass = 1;
            } else {
                if (strcmp(alert->check_data, calls_data[i].prefix) == 0) can_pass = 1;
            }
        }

        if (can_pass) {

            if (debug) {
                mor_log("PASS! Alert[%d]: TARGET_ID: %d, user_id: %d, provider_id: %d, answered: %d, duration: %ld, billsec: %ld, pdd: %.3f, postpaid: %d, prefix: %s, "
                        "device_id: %d, destinationgroup_id: %d, user_price: %.3f, provider_price: %.3f, user_lcr: %d, hgc: %d, alert_if_more: %.3f, alert_if_less: %.3f, "
                        "clear_if_more: %.3f, clear_if_less: %.3f\n",
                        alert->id, target_id, calls_data[i].user_id, calls_data[i].provider_id, calls_data[i].answered,
                        calls_data[i].duration, calls_data[i].billsec, calls_data[i].pdd,
                        calls_data[i].postpaid, calls_data[i].prefix, calls_data[i].device_id,
                        calls_data[i].destinationgroup_id, calls_data[i].user_price, calls_data[i].provider_price,
                        calls_data[i].user_lcr_id, calls_data[i].hgc, alert->alert_if_more, alert->alert_if_less, alert->clear_if_more, alert->clear_if_less);
            }

            // check only parameter specified by alert type
            if (alert_type == 1) {
                value = 1;
                count = 1;
            } else if (alert_type == 2) {
                if (calls_data[i].answered) value = 1;
                count = 1;
            } else if (alert_type == 3) {
                if (!calls_data[i].answered) value = 1;
                count = 1;
            } else if (alert_type == 4) {
                if (calls_data[i].answered) value = 1;
                count = 1;
            } else if (alert_type == 5) {
                if (calls_data[i].answered) {
                    value = calls_data[i].duration;
                    count = 1;
                }
            } else if (alert_type == 6) {
                if (calls_data[i].answered) {
                    if (calls_data[i].pdd > -1) { // if pdd = -1, sipchaninfo is disabled
                        value = calls_data[i].pdd;
                        count = 1;
                    }
                }
            } else if (alert_type == 7) {
                if (calls_data[i].answered) {
                    value = calls_data[i].duration - calls_data[i].billsec;
                    count = 1;
                }
            } else if (alert_type == 8) {
                if (calls_data[i].answered) {
                    value = calls_data[i].billsec;
                    count = 1;
                }
            }  else if (alert_type == 9) {
                if (calls_data[i].answered) {
                    if (check_type == 1 || check_type == 3) {
                        value = calls_data[i].user_price;
                    } else if (check_type == 2) {
                        value = calls_data[i].provider_price;
                    }
                    count = 1;
                }
            }  else if (alert_type == 11) {
                if (alert->hgc >= 0) {
                    if (calls_data[i].hgc == alert->hgc) {
                        value = 1;
                        count = 1;
                    }
                }
            }  else if (alert_type == 12) {
                if (alert->hgc >= 0) {
                    if (calls_data[i].hgc == alert->hgc) {
                        value = 1;
                    }
                    count = 1;
                }
            }

        } else {

            if (debug) {
                mor_log("FAIL! Alert[%d]: TARGET_ID: %d, user_id: %d, provider_id: %d, answered: %d, duration: %ld, billsec: %ld, pdd: %.3f, postpaid: %d, prefix: %s, "
                        "device_id: %d, destinationgroup_id: %d, user_price: %.3f, provider_price: %.3f, user_lcr: %d, hgc: %d, alert_if_more: %.3f, alert_if_less: %.3f, "
                        "clear_if_more: %.3f, clear_if_less: %.3f\n",
                        alert->id, target_id, calls_data[i].user_id, calls_data[i].provider_id, calls_data[i].answered,
                        calls_data[i].duration, calls_data[i].billsec, calls_data[i].pdd,
                        calls_data[i].postpaid, calls_data[i].prefix, calls_data[i].device_id,
                        calls_data[i].destinationgroup_id, calls_data[i].user_price, calls_data[i].provider_price,
                        calls_data[i].user_lcr_id, calls_data[i].hgc, alert->alert_if_more, alert->alert_if_less, alert->clear_if_more, alert->clear_if_less);
            }

        }

        // count is not 0 so we need to add this value to aggregated data and increment current count
        if (count) {

            data_info_t *data_node = NULL;

            // search for particular node (by id or type (all/prepaid/postpaid))
            if (search) {
                if (alert->check_type == 1 && calls_data[i].user_id > 0) {
                    data_node = get_data_address(calls_data[i].user_id, calls_data[i].user_id, alert, calls_data[i].ignore_alert, update);
                } else if (alert->check_type == 2 && calls_data[i].provider_id) {
                    data_node = get_data_address(calls_data[i].provider_id, 0, alert, calls_data[i].ignore_alert, update);
                } else if (alert->check_type == 3 && calls_data[i].device_id) {
                    data_node = get_data_address(calls_data[i].device_id, calls_data[i].user_id, alert, calls_data[i].ignore_alert, update);
                } else if (alert->check_type == 4 && calls_data[i].destinationgroup_id) {
                    data_node = get_data_address(calls_data[i].destinationgroup_id, 0, alert, calls_data[i].ignore_alert, update);
                }
            } else {
                alert->data_info->user_id = calls_data[i].user_id;
                data_node = alert->data_info;
            }

            if (data_node != NULL) {

                // update node
                if (update) {
                    data_node->data_sum += value;
                    data_node->data_count += count;
                } else {
                    if (!(data_node->clear_period_countdown > 0)) {
                        data_node->data_sum -= value;
                        data_node->data_count -= count;
                    }
                }
            }
        }

    }

    sim_check:

    if (alert_type == 10) {

        // if call ends, record will not be in activecalls table
        // so we set all sim call record state to default - 0 sim calls
        // later, we will assign a real value of current sim calls

        data_info_t *data = alert->data_info;
        while (data) {
            data->data_sum = 0;
            data->data_count = 0;
            data = data->next;
        }

        // we set sim calls only when updating values
        // if we are deleting old data, then we just set default values and return
        if (!update) {
            free(calls_data);
            return 0;
        }

        for (i = calls_data_count; i < active_calls_data_count; i++) {

            // check if call record target matches alert target (by id or by type)
            if (*(&calls_data[i].user_id + offset) == target_id) {

                data_info_t *data_node = NULL;

                // search for particular target
                if (search) {
                    if (alert->check_type == 1 && calls_data[i].user_id > 0) {
                        data_node = get_data_address(calls_data[i].user_id, calls_data[i].user_id, alert, calls_data[i].ignore_alert, update);
                    } else if (alert->check_type == 2 && calls_data[i].provider_id) {
                        data_node = get_data_address(calls_data[i].provider_id, 0, alert, calls_data[i].ignore_alert, update);
                    } else if (alert->check_type == 3 && calls_data[i].device_id) {
                        data_node = get_data_address(calls_data[i].device_id, calls_data[i].user_id, alert, calls_data[i].ignore_alert, update);
                    } else if (alert->check_type == 4 && calls_data[i].destinationgroup_id) {
                        data_node = get_data_address(calls_data[i].destinationgroup_id, 0, alert, calls_data[i].ignore_alert, update);
                    }
                } else {
                    alert->data_info->user_id = calls_data[i].user_id;
                    data_node = alert->data_info;
                }

                if (data_node != NULL) {

                    // updating to current sim calls
                    if (update) {
                        data_node->data_sum = (float)calls_data[i].user_sim_calls;
                        data_node->data_count = calls_data[i].user_sim_calls;
                    }

                }

            }

        }

    }

    free(calls_data);

    return 0;

}

/*
    Update alerts with current calls packet
*/

int update_data(int add) {

    // alerts will be updated in chunks every second
    // if we have 5 chunks, than alerts data will be updated in 5 seconds
    int chunk_num  = DATA_AGGREGATE_PERIODS;

    // adjust chunk count for small number of alerts
    if (alerts_count < chunk_num) chunk_num = alerts_count;

    // claculate chunk size (alerts are divided equaly into x number of chunks)
    int chunk_size = (int)ceil((double)alerts_count / (double)chunk_num);
    int chunk_start = 0, chunk_end;

    chunk_end = chunk_size;
    uint i = 0;

    for (i = 0; i < chunk_num; i++) {

        // update every chunk

        uint j = 0;
        // printf("update %d %d %ld %d\n", chunk_start, chunk_end, alerts_count, add);
        // update every alert in that chunk
        for (j = chunk_start; j < chunk_end; j++) {

            // index to calls array
            int index = 0;

            if (add == 0) {
                index = alerts[j].period;
            }

            if (alerts[j].alert_type != 13) {
                if (update_alert_data(&alerts[j], add, index)) return 1;
            }

        }

        chunk_start += chunk_size;
        chunk_end += chunk_size;
        if (chunk_end >= alerts_count) chunk_end = alerts_count;

        // little pause to free cpu from work and let do other things
        sleep(1);
    }

    if (chunk_num < DATA_AGGREGATE_PERIODS) {
        for (i = 0; i < DATA_AGGREGATE_PERIODS - chunk_num; i++) {
            sleep(1);
        }
    }

    return 0;
}

/*
    Function that aggregates data based on alert type
*/

double calculate_aggregated_data(int alert_type, double data_sum, long int data_count) {

    double new_data_sum = data_sum;

    if (data_count != 0) {
        if (alert_type == 4 || alert_type == 12) new_data_sum = (data_sum / data_count) * 100; // asr
        if (alert_type == 5) new_data_sum = data_sum / data_count;         // acd
        if (alert_type == 6) new_data_sum = data_sum / data_count;         // average pdd
        if (alert_type == 7) new_data_sum = data_sum / data_count;         // average ttc
    } else {
        new_data_sum = 0;
    }

    return new_data_sum;
}

int action_alert_sms(alerts_t *alert, data_info_t *data, int report) {
    return 0;
}

/*
    Get hour and minutes from time string like '22:18'
*/

void get_schedule_time(char *strtime, int *hour, int *min) {
    char buff[3] = "";
    strncpy(buff, strtime, 2);
    *hour = atoi(buff);
    strncpy(buff, strtime + 3, 2);
    *min = atoi(buff);
}

/*
    Action sends emails by schedule
*/

int action_alert_email(alerts_t *alert, data_info_t *data, int report, char *cause, double data_sum, long int data_count) {

    alert_action_log("Send email to alert group", report, alert->id);

    // we don't have group? return
    if (alert->alert_groups_id < 1) {
        mor_log("Group id is < 1. Alert will not be reported\n");
        email_action_log(0, "", 0, "Group id is < 1. Alert will not be reported");
        return 0;
    }

    // get owner email data
    int email_index = get_email_owner_index(alert->owner_id);

    // we don't have properly configured email? return
    if (email[email_index].enabled == 0 || email_index == -1) {
        char email_error[512] = "";
        sprintf(email_error, "Emails are disabled for owner with id: %d. Email will not be sent", alert->owner_id);
        mor_log("%s\n", email_error);
        email_action_log(0, "", 0, email_error);
        if (email_index >= 0) mor_log("Email data: owner_id: %d, server: %s, login: %s, from: %s, port: %d\n", alert->owner_id, email[email_index].server, email[email_index].login, email[email_index].from, email[email_index].port);
        return 0;
    }

    char alertstr[32] = "CLEAR";

    char subject[1024] = "Alert notification";
    char body[10000] = "";
    char email_to[256] = "";
    char object_type[128] = "";
    char object_name[256] = "";

    alert_get_check_type_string(alert->check_type, object_type);
    alert_get_object_name_string(alert, data->id, object_name);

    if (report) strcpy(alertstr, "ALERT");

    mor_log("Action: Email, Alert: %d, Check type: %d, Alert ID: %d, Data ID: %ld, Group ID: %d, Owner ID: %d\n", report, alert->check_type, alert->id, data->id, alert->alert_groups_id, email[email_index].owner_id);

    // format email body
    sprintf(body, "Reporting: %s\nParameter: %s\nGroup to notify: %s\nObject Type: %s\nObject: %s\nObject name: %s\nAlert ID: %u\n\n"
            "Date: %s\n\n"
            "Current value: %0.2f\n"
            "Data count: %ld\n"
            "Alert if more: %0.2f\n"
            "Alert if less: %0.2f\n"
            "Clear if more: %0.2f\n"
            "Clear if less: %0.2f\n"
            "Ignore if calls more: %ld\n"
            "Ignore if calls less: %ld\n\nComment:\n\n%s\n",
            alertstr, cause, alert->group->name == NULL ? "" : alert->group->name, object_type, alert->check_data, object_name, alert->id, date_str, data_sum, data_count,
            alert->alert_if_more, alert->alert_if_less,
            alert->clear_if_more, alert->clear_if_less,
            alert->ignore_if_calls_more, alert->ignore_if_calls_less, alert->comment);

    contact_t *contact = alert->group->contact;

    // get current minute
    int min = current_min;

    // check ever contact
    while (contact) {

        // shift time by timezone
        time_t shifted_linux_time = time(NULL) + (contact->timezone * 3600);
        struct tm shifted_current_time;

        gmtime_r(&shifted_linux_time, &shifted_current_time);

        int send_email = 0;
        int hour = shifted_current_time.tm_hour;
        int day = shifted_current_time.tm_wday;

        schedule_t *schedule = alert->group->schedule;

        // check if current time is in scheduled period
        while (schedule) {

            // printf("current_day = %d, day = %d\n", day, schedule->daytype);

            if (day == schedule->daytype || schedule->daytype == -1) {

                int start_hour = 0, start_min = 0;
                int end_hour = 0, end_min = 0;

                get_schedule_time(schedule->start, &start_hour, &start_min);
                get_schedule_time(schedule->end, &end_hour, &end_min);

                // printf("current_hour = %d, current_min = %d, current_day = %d\n", current_hour, current_min, current_day);
                // printf("shifted_hour = %d, shifted_min = %d, shifted_day = %d\n", hour, min, day);
                // printf("start_hour = %d, start_min = %d\n", start_hour, start_min);
                // printf("end_hour = %d, end_min = %d\n", end_hour, end_min);

                int calculated_time = hour * 3600 + min;
                int calculated_start_time = start_hour * 3600 + start_min;
                int calculated_end_time = end_hour * 3600 + end_min;

                if (calculated_time >= calculated_start_time && calculated_time < calculated_end_time) send_email = 1; // this period is OK, send email!

            }

            schedule = schedule->prev;

        }

        // should we send email?
        if (send_email) {

            char response[2048] = "";
            char debug_email_output[512] = "";
            strcpy(email_to, contact->email);
            char emailcmd[15000] = "";
            char login_cmd[256] = "";
            char password_cmd[256] = "";

            if (strlen(email[email_index].login)) {
                sprintf(login_cmd, "-xu %s", email[email_index].login);
            }

            if (strlen(email[email_index].password)) {
                sprintf(password_cmd, "-xp %s", email[email_index].password);
            }

            mor_log("Email to: %s\n", contact->email);

            sprintf(emailcmd, "/usr/local/mor/sendEmail -f %s %s %s -t '%s' -u '%s' -s '%s:%d' -m '%s' -o tls='auto'", email[email_index].from, login_cmd, password_cmd, email_to, subject, email[email_index].server, email[email_index].port, body);
            sprintf(debug_email_output, "/usr/local/mor/sendEmail -f %s %s %s -t '%s' -u '%s' -s '%s:%d' -m '%s' -o tls='auto'", email[email_index].from, login_cmd, password_cmd, email_to, subject, email[email_index].server, email[email_index].port, "EMAIL_BODY");
            mor_log("%s\n", debug_email_output);

            FILE *pipe = popen(emailcmd, "r");
            fgets(response, 2040, pipe);
            if (strstr(response, "Email was sent successfully")) {
                mor_log("Email was sent successfully\n");
                email_action_log(0, contact->email, 1, "");
            } else {
                mor_log("Failed to send email: %s\n", response);
                email_action_log(0, contact->email, 0, response);
                mor_log("Emails will be temporary disabled for owner: %d\n", email[email_index].owner_id);
                email[email_index].enabled = 0;
            }
            fclose(pipe);

        } else {
            email_action_log(0, contact->email, 0, "Email will no be sent. Check schedule settings");
            mor_log("Email will no be sent. Check schedule settings\n");
        }

        contact = contact->prev;

    }

    return 0;
}

/*
    Send email to user
*/

int action_alert_email_to_user(alerts_t *alert, data_info_t *data, int report, char *cause, double data_sum, long int data_count) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    alert_action_log("Send email to user", report, alert->id);

    // applies only to users
    if (alert->check_type != 1) return 0;

    // get owner email data
    int email_index = get_email_owner_index(alert->owner_id);

    // we don't have properly configured email? return
    if (email[email_index].enabled == 0 || email_index == -1) {
        char email_error[512] = "";
        sprintf(email_error, "Emails are disabled for owner with id: %d. Email will not be sent", alert->owner_id);
        mor_log("%s\n", email_error);
        email_action_log(data->id, "", 0, email_error);
        if (email_index >= 0) mor_log("Email data: owner_id: %d, server: %s, login: %s, from: %s, port: %d\n", alert->owner_id, email[email_index].server, email[email_index].login, email[email_index].from, email[email_index].port);
        return 0;
    }

    char alertstr[32] = "CLEAR";

    char subject[1024] = "Alert notification";
    char body[10000] = "";
    char email_to[256] = "";
    char object_type[128] = "";
    char object_name[256] = "";

    alert_get_check_type_string(alert->check_type, object_type);
    alert_get_object_name_string(alert, data->id, object_name);

    if (report) strcpy(alertstr, "ALERT");

    mor_log("Action: Email to user, Alert: %d, Check type: %d, Alert ID: %d, Data ID: %ld, Owner ID: %d\n", report, alert->check_type, alert->id, data->id, email[email_index].owner_id);

    // format email body
    sprintf(body, "Reporting: %s\nParameter: %s\nObject Type: %s\nObject: %s\nObject name: %s\nAlert ID: %u\n\n"
            "Date: %s\n\n"
            "Current value: %0.2f\n"
            "Data count: %ld\n"
            "Alert if more: %0.2f\n"
            "Alert if less: %0.2f\n"
            "Clear if more: %0.2f\n"
            "Clear if less: %0.2f\n"
            "Ignore if calls more: %ld\n"
            "Ignore if calls less: %ld\n\nComment:\n\n%s\n",
            alertstr, cause, object_type, alert->check_data, object_name, alert->id, date_str, data_sum, data_count,
            alert->alert_if_more, alert->alert_if_less,
            alert->clear_if_more, alert->clear_if_less,
            alert->ignore_if_calls_more, alert->ignore_if_calls_less, alert->comment);

    char email_query[1024] = "";
    char user_email[256] = "";
    sprintf(email_query, "SELECT noc_email, main_email, billing_email, rates_email FROM users WHERE id = %li LIMIT 1", data->id);

    if (mor_mysql_query(email_query)) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    // fill alerts list
    while ((row = mysql_fetch_row(result)) != NULL) {

        if (row[3]) if (strlen(row[3]) > 0) strcpy(user_email, row[3]);
        if (row[2]) if (strlen(row[2]) > 0) strcpy(user_email, row[2]);
        if (row[1]) if (strlen(row[1]) > 0) strcpy(user_email, row[1]);
        if (row[0]) if (strlen(row[0]) > 0) strcpy(user_email, row[0]);

    }

    if (strlen(user_email) > 0) {

        char response[2048] = "";
        char debug_email_output[512] = "";
        strcpy(email_to, user_email);
        char emailcmd[15000] = "";
        char login_cmd[256] = "";
        char password_cmd[256] = "";

        if (strlen(email[email_index].login)) {
            sprintf(login_cmd, "-xu %s", email[email_index].login);
        }

        if (strlen(email[email_index].password)) {
            sprintf(password_cmd, "-xp %s", "PASSWORD");
        }

        mor_log("Email to: %s\n", email_to);

        sprintf(emailcmd, "/usr/local/mor/sendEmail -f %s %s %s -t '%s' -u '%s' -s '%s:%d' -m '%s' -o tls='auto'", email[email_index].from, login_cmd, password_cmd, email_to, subject, email[email_index].server, email[email_index].port, body);
        sprintf(debug_email_output, "/usr/local/mor/sendEmail -f %s %s %s -t '%s' -u '%s' -s '%s:%d' -m '%s' -o tls='auto'", email[email_index].from, login_cmd, password_cmd, email_to, subject, email[email_index].server, email[email_index].port, "EMAIL_BODY");
        mor_log("%s\n", debug_email_output);

        FILE *pipe = popen(emailcmd, "r");
        fgets(response, 2040, pipe);
        if (strstr(response, "Email was sent successfully")) {
            mor_log("Email was sent successfully\n");
            email_action_log(data->id, user_email, 1, "");
        } else {
            mor_log("Failed to send email: %s\n", response);
            mor_log("Emails will be temporary disabled for owner: %d\n", email[email_index].owner_id);
            email_action_log(data->id, user_email, 0, response);
            email[email_index].enabled = 0;
        }
        fclose(pipe);

    } else {
        mor_log("Option 'notify to user' is enabled, but user's email is empty\n");
        email_action_log(data->id, "", 0, "Option 'notify to user' is enabled, but user's email is empty");
    }

    return 0;
}

/*
    Action disables user or provider
*/

int action_alert_disable_object(alerts_t *alert, data_info_t *data, int report) {

    // only applies to users, providers
    if (!(alert->check_type == 1 || alert->check_type == 2)) return 0;

    // only if we have id
    if (data->id < 0) return 0;

    char target[256] = "";
    char buffer[1024] = "";

    if (alert->check_type == 1) {
        strcpy(target, "user");
    }

    if (alert->check_type == 2) {
        strcpy(target, "provider");
    }

    char alert_msg[512] = "";
    sprintf(alert_msg, "%s %s (id %ld)", report == 1 ? "Disable" : "Enable", target, data->id);
    alert_action_log(alert_msg, report, alert->id);

    mor_log("Action: %s %s, alert_id: %d, %s_id: %ld\n", report == 1 ? "disable" : "enable", target, alert->id, target, data->id);

    // when reporting alert
    if (report) {
        // for users
        if (alert->check_type == 1) {
            sprintf(buffer, "UPDATE users SET blocked = 1 WHERE id = %ld", data->id);
        // for providers
        } else {
            sprintf(buffer, "UPDATE providers SET active = 0 WHERE id = %ld", data->id);
        }
    // when clearing alert
    } else {
        // for users
        if (alert->check_type == 1) {
            sprintf(buffer, "UPDATE users SET blocked = 0 WHERE id = %ld", data->id);
        // for providers
        } else {
            sprintf(buffer, "UPDATE providers SET active = 1 WHERE id = %ld", data->id);
        }
    }

    if (mor_mysql_query(buffer)) {
        return 1;
    }


    return 0;
}

/*
    Action changes LCR for users and devices
*/

int action_alert_change_lcr(alerts_t *alert, data_info_t *data, int report) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // only for users and devices
    if (!(alert->check_type == 1 || alert->check_type == 3)) return 0;

    // only if we have user_id
    if (!data->user_id) return 0;

    char target[256] = "";

    if (alert->check_type == 1) {
        strcpy(target, "user");
    }

    if (alert->check_type == 3) {
        strcpy(target, "device");
    }

    char alert_msg[512] = "";
    sprintf(alert_msg, "Change LCR for %s (id %ld), lcr id: %d, restore lcr id: %d", target, data->id, alert->action_alert_change_lcr_id, alert->action_clear_change_lcr_id);
    alert_action_log(alert_msg, report, alert->id);

    mor_log("Action: change LCR, alert_id: %d, %s_id: %ld, user_id: %ld, change_lcr_id: %d, restore_lcr_id: %d\n",
            alert->id, target, data->id, data->user_id, alert->action_alert_change_lcr_id, alert->action_clear_change_lcr_id);

    char buffer[1024] = "";
    int target_lcr_id = 0;

    if (report) {

        // save current user lcr so we can later restore user's lcr to this lcr (restore original user lcr)
        char sqlcmd[2048] = "";
        sprintf(sqlcmd, "SELECT lcr_id FROM users WHERE id = %ld LIMIT 1", data->user_id);
        if (mor_mysql_query(sqlcmd)) return 1;
        result = mysql_store_result(&mysql);
        if (result) {
            if (mysql_num_rows(result)) {
                row = mysql_fetch_row(result);
                if (row[0]) data->user_lcr_id = atoi(row[0]);
            }
        }
        mysql_free_result(result);

        if (data->user_lcr_id < 1 && alert->action_clear_change_lcr_id == -1) {
            mor_log("Restore LCR option is enabled, but can't determine current user LCR, which will be restored. LCR will not be changed\n");
            alert_action_log("Restore LCR option is enabled, but can't determine current user LCR, which will be restored. LCR will not be changed", report, alert->id);
            return 0;
        }

        target_lcr_id = alert->action_alert_change_lcr_id;
    } else {
        target_lcr_id = alert->action_clear_change_lcr_id;
        if (target_lcr_id == -1) {
            if (data->user_lcr_id > 0) {
                target_lcr_id = data->user_lcr_id;
            } else {
                mor_log("Restore LCR option is enabled, but original LCR id is 0. Something went wrong\n");
                alert_action_log("Restore LCR option is enabled, but original LCR id is 0. Something went wrong", report, alert->id);
                return 0;
            }
        }
    }

    if (target_lcr_id) {
        sprintf(buffer, "UPDATE users SET lcr_id = %d WHERE id = %ld", target_lcr_id, data->user_id);
        if (mor_mysql_query(buffer)) {
            return 1;
        }
    } else {
        mor_log("LRC id = 0. User's LCR will not be changed\n");
        alert_action_log("LRC id = 0. User's LCR will not be changed", report, alert->id);
    }

    return 0;

}

/*
    Action disable object in LCR
*/

int action_alert_disable_object_in_lcr(alerts_t *alert, data_info_t *data, int report) {

    // only for providers
    if (alert->check_type != 2) return 0;

    char alert_msg[512] = "";
    sprintf(alert_msg, "%s provider (id %ld) in LCR (id %d)", report == 1 ? "Disable" : "Enable", data->id, alert->action_alert_disable_object_in_lcr);
    alert_action_log(alert_msg, report, alert->id);

    mor_log("Action: %s provider in LCR, alert_id: %d, provider_id: %ld, lcr_id: %d\n", report == 1 ? "disable" : "enable", alert->id, data->id, alert->action_alert_disable_object_in_lcr);

    char mysql_buffer[1024] = "";

    if (report) {
        sprintf(mysql_buffer, "UPDATE lcrproviders SET active = 0 WHERE lcr_id = %d AND provider_id = %ld", alert->action_alert_disable_object_in_lcr, data->id);
    } else {
        sprintf(mysql_buffer, "UPDATE lcrproviders SET active = 1 WHERE lcr_id = %d AND provider_id = %ld", alert->action_alert_disable_object_in_lcr, data->id);
    }

    if (mor_mysql_query(mysql_buffer)) {
        return 1;
    }

    if (mysql_affected_rows(&mysql) == 0) {
        return 2;
    }

    return 0;

}

/*
    Report about alert and take defined action
*/

int report_alert(alerts_t *alert, data_info_t *data, int report) {

    // we do not report alert if it is not cleared in the first place
    if (report == 1 && data->alert_is_set == 1) return 0;
    // we do not clear alert if if is not reported in the first place
    if (report == 0 && data->alert_is_set == 0) return 0;

    char cause[128] = "UNKNOWN"; // default value
    char alertstr[32] = "CLEAR"; // default value
    double data_sum = calculate_aggregated_data(alert->alert_type, data->data_sum, data->data_count);
    long int data_count = data->data_count;
    int status = 0;

    if (report) strcpy(alertstr, "ALERT");

    // get alert type string from integer value
    if (alert->alert_type == 1) {
        strcpy(cause, "CALLS TOTAL");
    } else if (alert->alert_type == 2) {
        strcpy(cause, "CALLS ANSWERED");
    } else if (alert->alert_type == 3) {
        strcpy(cause, "CALLS NOT ASWERED");
    } else if (alert->alert_type == 4) {
        strcpy(cause, "ASR");
    } else if (alert->alert_type == 5) {
        strcpy(cause, "ACD");
    } else if (alert->alert_type == 6) {
        strcpy(cause, "PDD");
    } else if (alert->alert_type == 7) {
        strcpy(cause, "TCC");
    } else if (alert->alert_type == 8) {
        strcpy(cause, "BILLSEC SUM");
    } else if (alert->alert_type == 9) {
        strcpy(cause, "PRICE SUM");
    } else if (alert->alert_type == 10) {
        strcpy(cause, "SIMULTANEOUS CALLS");
    } else if (alert->alert_type == 11) {
        strcpy(cause, "HANGUPCAUSE ABSOLUTE");
    } else if (alert->alert_type == 12) {
        strcpy(cause, "HANGUPCAUSE PERCENT");
    } else if (alert->alert_type == 13) {
        strcpy(cause, "GROUP");
    }

    if (!((alert->check_type == 1 || alert->check_type == 3) && data->ignore_alert)) {
        // take action
        if (report && alert->action_alert_email) if (action_alert_email(alert, data, report, cause, data_sum, data_count)) return 1;
        if (!report && alert->action_clear_email) if (action_alert_email(alert, data, report, cause, data_sum, data_count)) return 1;
        if (report && alert->notify_to_user) if (action_alert_email_to_user(alert, data, report, cause, data_sum, data_count)) return 1;
        if (!report && alert->notify_to_user) if (action_alert_email_to_user(alert, data, report, cause, data_sum, data_count)) return 1;
        if (report &&alert->action_alert_sms) if (action_alert_sms(alert, data, report)) return 1;
        if (!report && alert->action_clear_sms) if (action_alert_sms(alert, data, report)) return 1;
        if (report && alert->action_alert_disable_object) if (action_alert_disable_object(alert, data, report)) return 1;
        if (!report && alert->action_clear_enable_object) if (action_alert_disable_object(alert, data, report)) return 1;
        if (report && alert->action_alert_change_lcr_id) if (action_alert_change_lcr(alert, data, report)) return 1;
        if (!report && alert->action_clear_change_lcr_id) if (action_alert_change_lcr(alert, data, report)) return 1;
        if (report && alert->action_alert_disable_object_in_lcr) status = action_alert_disable_object_in_lcr(alert, data, report);
        if (!report && alert->action_clear_enable_object_in_lcr) status = action_alert_disable_object_in_lcr(alert, data, report);
    }

    // this is only used with provider disabling in lcr
    // if we can not find provider in specified lcr, action should be created to inform user
    if (status == 1) {
        return 1;
    } else if (status == 2) {
        // just to disable spaming
        data->alert_is_set = 1;
        char mysql_buffer[1024] = "";
        sprintf(mysql_buffer, "INSERT INTO actions(action, data, data2, date) VALUES('alert_warning', 'Alert id: %d', 'Provider (id: %ld) not found in LCR (id: %d)', NOW())", alert->id, data->id, alert->action_alert_disable_object_in_lcr);
        if (mor_mysql_query(mysql_buffer)) {
            return 1;
        }
        mor_log("Provider was not found in selected LCR\n");
        return 0;
    }

    if (report) {
        data->alert_is_set = 1;
        if (!((alert->check_type == 1 || alert->check_type == 3) && data->ignore_alert)) {
            char mysql_buffer[1024] = "";
            sprintf(mysql_buffer, "UPDATE alerts set value_at_alert = %.5f, value_at_clear = 0, alert_raised_at = NOW(), alert_cleared_at = 0 WHERE id = %d", data_sum, alert->id);
            if (mor_mysql_query(mysql_buffer)) {
                return 1;
            }
        }
    } else {
        data->alert_is_set = 0;
        if (!((alert->check_type == 1 || alert->check_type == 3) && data->ignore_alert)) {
            char mysql_buffer[1024] = "";
            sprintf(mysql_buffer, "UPDATE alerts set value_at_alert = 0, value_at_clear = %.5f, alert_raised_at = 0, alert_cleared_at = NOW() WHERE id = %d", data_sum, alert->id);
            if (mor_mysql_query(mysql_buffer)) {
                return 1;
            }
        }
    }

    data->clear_period_counter = 0;
    global_alert_is_changed = 1;

    if (!((alert->check_type == 1 || alert->check_type == 3) && data->ignore_alert)) {
        // log this alert
        mor_log("Reporting [%s] for [%s] to group id [%u], data ID [%ld], alert id [%u], "
                "current value: %0.2f, "
                "data count: %ld, "
                "alert if more: %0.2f, "
                "alert if less: %0.2f, "
                "clear if more: %0.2f, "
                "clear if less: %0.2f, "
                "ignore if calls more: %ld, "
                "ignore ir calls less: %ld\n",
                alertstr, cause, alert->alert_groups_id, data->id, alert->id, data_sum, data_count,
                alert->alert_if_more, alert->alert_if_less,
                alert->clear_if_more, alert->clear_if_less,
                alert->ignore_if_calls_more, alert->ignore_if_calls_less);
    } else {
        char target[128] = "user";
        if (alert->check_type == 3) strcpy(target, "device");
        if (report) {
            mor_log("Alert is triggered, but will be ignored. Alerts are disabled for %s_id = %ld", target, data->id);
        } else {
            mor_log("Clear is triggered, but will be ignored. Alerts are disabled for %s_id = %ld", target, data->id);
        }
    }

    return 0;

}

int check_current_alert(alerts_t *alert) {

    data_info_t *current = alert->data_info;

    while (current) {

        // skip empty objects (id = -2)
        if (current->id != -2) {

            if (debug) {
                mor_log("Alert check #1: checking target: %ld, data sum = %.0f, data count = %llu, alert_is_set: %d\n",
                        current->id, current->data_sum, current->data_count, current->alert_is_set);
            }

            long int data_count = current->data_count;
            double data_sum = calculate_aggregated_data(alert->alert_type, current->data_sum, current->data_count);

            if (debug) {
                mor_log("alert_id = %d\n", alert->id);
                mor_log("current_value = %.2f\n", data_sum);
                mor_log("current_count = %ld\n", data_count);
                mor_log("alert if more = %.2f\n", alert->alert_if_more);
                mor_log("alert if less = %.2f\n", alert->alert_if_less);
                mor_log("clear if more = %.2f\n", alert->clear_if_more);
                mor_log("clear if less = %.2f\n", alert->clear_if_less);
            }

            // check if we need to clear alert
            if (current->alert_is_set && !alert->disable_clear && alert->clear_period == 0) {
                if (alert->clear_if_more > alert->clear_if_less) {
                    if (data_sum >= alert->clear_if_more) if (report_alert(alert, current, 0)) return 1;
                } else {
                    if (data_sum <= alert->clear_if_less) if (report_alert(alert, current, 0)) return 1;
                }
            }

            // check if we should ignore this alert
            if ((data_count >= alert->ignore_if_calls_more) && (alert->ignore_if_calls_more != 0)) goto skip_this;
            if (data_count <= alert->ignore_if_calls_less && alert->ignore_if_calls_less != 0) goto skip_this;

            // check if we need to set alert
            if (!current->alert_is_set) {
                if (alert->alert_if_more > alert->alert_if_less) {
                    if (data_sum >= alert->alert_if_more) if (report_alert(alert, current, 1)) return 1;
                } else {
                    if (data_sum <= alert->alert_if_less) if (report_alert(alert, current, 1)) return 1;
                }
            }

        }

        skip_this:

        current = current->next;

    }

    return 0;

}

int check_current_alert_group(alerts_t *alert) {

    data_info_t *data_node_1 = NULL;
    data_info_t *data_node_2 = NULL;

    int checked_data[500] = { 0 };
    int checked_data_count = 0;

    int data_sum = 0;
    int data_count = 0;

    int i = 0, j = 0, k = 0;
    char alert_id_buffer[64] = "";

    mor_log("Alert group check for alert_id: %u\n", alert->id);

    for (i = 0; i < alerts_count; i++) {
        if (alerts[i].id != alert->id) {
            sprintf(alert_id_buffer, ",%d,", alerts[i].id);
            if (strstr(alert->alert_group_id_list, alert_id_buffer)) {

                if (debug) {
                    mor_log("Checking #1 alert %d in this alert group\n", alerts[i].id);
                }

                data_node_1 = alerts[i].data_info;

                data_sum = 0;
                data_count = 0;

                while (data_node_1) {

                    if (data_node_1->id < -1) goto skip_data;

                    if (checked_data_count < 500) {

                        for (k = 0; k < checked_data_count; k++) {
                            if (checked_data[k] == data_node_1->id) goto skip_data;
                        }

                        checked_data[checked_data_count] = data_node_1->id;
                        checked_data_count++;

                    }

                    data_count++;
                    if (data_node_1->alert_is_set) data_sum++;

                    for (j = 0; j < alerts_count; j++) {
                        if (alerts[j].id != alert->id && alerts[j].id != alerts[i].id) {
                            sprintf(alert_id_buffer, ",%d,", alerts[j].id);
                            if (strstr(alert->alert_group_id_list, alert_id_buffer)) {

                                data_node_2 = alerts[j].data_info;
                                while (data_node_2) {

                                    if (alerts->check_type == 4) {

                                        int min_len1 = strlen(alerts[j].check_data);
                                        int min_len2 = strlen(alerts[i].check_data);
                                        int min_len3 = strlen(alert->check_data);
                                        int min_len = min_len1;
                                        if (alerts[j].check_data[strlen(alerts[j].check_data) - 1] == '%') min_len1--;
                                        if (alerts[i].check_data[strlen(alerts[i].check_data) - 1] == '%') min_len2--;
                                        if (alerts->check_data[strlen(alerts->check_data) - 1] == '%') min_len3--;

                                        if (min_len2 < min_len) {
                                            min_len = min_len2;
                                        }

                                        if (min_len3 < min_len) {
                                            min_len = min_len3;
                                        }

                                        if (strncmp(alerts[j].check_data, alerts->check_data, min_len) == 0) {
                                            if (strncmp(alerts[j].check_data, alerts->check_data, min_len) == 0) {
                                                data_count++;
                                                if (data_node_2->alert_is_set) data_sum++;
                                            }
                                        }

                                    } else {

                                        if (data_node_1->id == data_node_2->id) {
                                            data_count++;
                                            if (data_node_2->alert_is_set) data_sum++;
                                        }

                                    }

                                    // mor_log("data_node_1_id: %ld, data_node_2_id: %ld, is_set_1: %d, is_set_2: %d\n", data_node_1->id, data_node_2->id, data_node_1->alert_is_set, data_node_2->alert_is_set);
                                    data_node_2 = data_node_2->next;
                                }

                            }
                        }
                    }

                    if (debug) {
                        if (alerts->check_type != 4) {
                            mor_log("data_id: %ld, data_count: %d, data_sum: %d\n", data_node_1->id, data_count, data_sum);
                        } else {
                            mor_log("data: %s, data_count: %d, data_sum: %d\n", alert->check_data, data_count, data_sum);
                        }
                    }

                    // update data

                    data_info_t *data_node = NULL;
                    // search for particular node
                    data_node = get_data_address(data_node_1->id, 0, alert, 0, 0);

                    if (data_node != NULL) {
                        data_node->data_sum = data_sum;
                        data_node->data_count = data_count;
                    }

                    skip_data:

                    data_node_1 = data_node_1->next;
                }

            }
        }
    }

    // check if alerts need to be reported

    data_info_t *current = alert->data_info;

    while (current) {

        data_sum = current->data_sum;

        // check if we need to clear alert
        if (current->alert_is_set && !alert->disable_clear && alert->clear_period == 0) {
            if (data_sum < alert->clear_if_less_than) if (report_alert(alert, current, 0)) return 1;
        }

        // check if we need to set alert
        if (!current->alert_is_set) {
            if (data_sum > alert->alert_if_more_than) if (report_alert(alert, current, 1)) return 1;
        }

        current = current->next;

    }

    return 0;

}

int check_current_alert_diff(alerts_t *alert) {

    alert->diff_counter++;

    if (alert->diff_counter >= (alert->period + 1)) {

    }

    return 0;

}

int check_alerts() {

    int chunk_num  = DATA_AGGREGATE_PERIODS;

    if (alerts_count < chunk_num) chunk_num = alerts_count;

    int chunk_size = (int)ceil((double)alerts_count / (double)chunk_num);
    int chunk_start = 0, chunk_end;
    int chunk_group_start = 0, chunk_group_end;

    chunk_end = chunk_size;
    chunk_group_end = chunk_size;

    uint i = 0;
    int alert_group_used = 0;

    // update every record
    for (i = 0; i < chunk_num; i++) {

        uint j = 0;
        // update each record

        // printf("check %d %d %ld\n", chunk_start, chunk_end, alerts_count);

        for (j = chunk_start; j < chunk_end; j++) {
            if (alerts[j].status == 1) {

                if (alerts[j].alert_count_type == 1) {
                    if (alerts[j].alert_type != 13) {
                        if (check_current_alert(&alerts[j])) {
                            mor_log("Error while checking alerts [%d]\n", j);
                            return 1;
                        }
                    }
                } else if (alerts[j].alert_count_type == 2) {
                    if (check_current_alert_diff(&alerts[j])) {
                        mor_log("Error while checking alerts diff [%d]\n", j);
                        return 1;
                    }
                }

            }
        }

        chunk_start += chunk_size;
        chunk_end += chunk_size;
        if (chunk_end >= alerts_count) chunk_end = alerts_count;
        sleep(1);
    }

    // once again for alert groups
    // because first we need to check normal alerts and see if any of then have been alerted/cleared
    // if we have atleast one, then check alert groups

    // update every record

    if (global_alert_is_changed) {

        for (i = 0; i < chunk_num; i++) {

            uint j = 0;
            // update each record

            // printf("check %d %d %ld\n", chunk_group_start, chunk_end, alerts_count);

            for (j = chunk_group_start; j < chunk_group_end; j++) {
                if (alerts[j].status == 1) {

                    if (alerts[j].alert_count_type == 1) {
                        if (alerts[j].alert_type == 13) {
                            mor_log("Checking alert groups\n");
                            alert_group_used = 1;
                            if (check_current_alert_group(&alerts[j])) {
                                mor_log("Error while checking alerts [%d]\n", j);
                                return 1;
                            }
                        }
                    }

                }
            }

            chunk_group_start += chunk_size;
            chunk_group_end += chunk_size;
            if (chunk_group_end >= alerts_count) chunk_group_end = alerts_count;

        }

    }

    if (chunk_num < DATA_AGGREGATE_PERIODS) {
        for (i = 0; i < DATA_AGGREGATE_PERIODS - chunk_num; i++) {
            sleep(1);
        }
    }

    // for alert groups, reset variable that show if alert status changed
    if (alert_group_used) {
        global_alert_is_changed = 0;
    }

    return 0;

}

int update_email_details() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";
    int i = 0;

    for (i = 0; i < email_count; i++) {

        sprintf(sqlcmd, "SELECT (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Smtp_Server'), "
                               "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Login'), "
                               "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Password'), "
                               "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_from'), "
                               "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_port')", email[i].owner_id, email[i].owner_id, email[i].owner_id, email[i].owner_id, email[i].owner_id);

        if (mor_mysql_query(sqlcmd)) {
            mor_mysql_reconnect();
            return 0;
        }

        result = mysql_store_result(&mysql);

        if (result == NULL) {
            mor_log("MySQL error: %s\n", mysql_error(&mysql));
            mor_log("MySQL query: %s\n", sqlcmd);
            return 1;
        }

        if ((row = mysql_fetch_row(result)) == NULL) {
            mor_log("MySQL returned an empty result set\n");
            mor_log("MySQL query: %s\n", sqlcmd);
            return 1;
        }

        if (row[0] && row[1] && row[2] && row[3] && row[4]) {

            email = realloc(email, (i + 1) * sizeof(email_data_t));

            strcpy(email[i].server, row[0]);
            strcpy(email[i].login, row[1]);
            strcpy(email[i].password, row[2]);
            strcpy(email[i].from, row[3]);
            email[i].port = atoi(row[4]);
            email[i].enabled = 1;

            if (!strlen(email[i].server)) { mor_log("Email server is empty\n"); email[i].enabled = 0; }
            if (!strlen(email[i].from)) { mor_log("Email from is empty\n"); email[i].enabled = 0; }
            if (!email[i].port) { mor_log("Email port is empty\n"); email[i].enabled = 0; }

            if (email[i].enabled == 0) mor_log("Emails are disabled for owner with id: %d\n", email[i].owner_id);

            mor_log("Email data updated: owner_id: %d, server: %s, login: %s, from: %s, port: %d\n", email[i].owner_id, email[i].server, email[i].login, email[i].from, email[i].port);

        } else {

            mor_log("Emails are disabled for owner with id: %d. No email data found\n", email[i].owner_id);
            email[i].enabled = 0;

        }

        mysql_free_result(result);

    }

    return 0;

}

int get_email_data(int owner_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Smtp_Server'), "
                            "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Login'), "
                            "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Password'), "
                            "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_from'), "
                            "(SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_port')", owner_id, owner_id, owner_id, owner_id, owner_id);

    if (mor_mysql_query(sqlcmd)) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    if (result == NULL) {
        mor_log("MySQL error: %s\n", mysql_error(&mysql));
        mor_log("MySQL query: %s\n", sqlcmd);
        return 1;
    }

    if ((row = mysql_fetch_row(result)) == NULL) {
        mor_log("MySQL returned an empty result set\n");
        mor_log("MySQL query: %s\n", sqlcmd);
        return 1;
    }

    if (row[0] && row[1] && row[2] && row[3] && row[4]) {

        email = realloc(email, (email_count + 1) * sizeof(email_data_t));

        strcpy(email[email_count].server, row[0]);
        strcpy(email[email_count].login, row[1]);
        strcpy(email[email_count].password, row[2]);
        strcpy(email[email_count].from, row[3]);
        email[email_count].port = atoi(row[4]);
        email[email_count].enabled = 1;
        email[email_count].owner_id = owner_id;

        if (!strlen(email[email_count].server)) { mor_log("Email server is empty\n"); email[email_count].enabled = 0; }
        if (!strlen(email[email_count].from)) { mor_log("Email from is empty\n"); email[email_count].enabled = 0; }
        if (!email[email_count].port) { mor_log("Email port is empty\n"); email[email_count].enabled = 0; }

        if (email[email_count].enabled == 0) mor_log("Emails are disabled for owner with id: %d\n", owner_id);

        mor_log("Email data: owner_id: %d, server: %s, login: %s, from: %s, port: %d\n", owner_id, email[email_count].server, email[email_count].login, email[email_count].from, email[email_count].port);

        email_count++;

    }

    mysql_free_result(result);

    return 0;
}

int get_contacts(alerts_t *alert) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    if (alert->alert_groups_id == 0) return 0;

    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT A.id, A.email, A.timezone, A.phone_number, C.email_schedule_id, C.sms_schedule_id, C.name FROM alert_contacts AS A "
                    "INNER JOIN alert_contact_groups AS B ON A.id = B.alert_contact_id "
                    "INNER JOIN alert_groups AS C ON C.id = B.alert_group_id "
                    "WHERE B.alert_group_id = %d AND A.status = 1 AND C.status = 1", alert->alert_groups_id);

    if (mor_mysql_query(sqlcmd)) {
        return 1;
    }

    group_t *group = malloc(sizeof(group_t));

    alert->group = group;
    group->alert_id = alert->id;

    contact_t *prev_contact = NULL;
    contact_t *current_contact = NULL;

    result = mysql_store_result(&mysql);

    // fill alerts list
    while ((row = mysql_fetch_row(result)) != NULL) {

        current_contact = malloc(sizeof(contact_t));
        memset(current_contact, 0, sizeof(contact_t));

        current_contact->prev = prev_contact;

        if (row[0]) current_contact->id = atoi(row[0]);
        if (row[1]) strcpy(current_contact->email, row[1]);
        if (row[2]) current_contact->timezone = atoi(row[2]);
        if (row[3]) strcpy(current_contact->number, row[3]);
        if (row[4]) group->email_schedule_id = atoi(row[4]);
        if (row[5]) group->sms_schedule_id = atoi(row[5]);
        if (row[6]) strcpy(group->name, row[6]);

        prev_contact = current_contact;

    }

    group->contact = current_contact;

    mysql_free_result(result);

    return 0;

}

int get_daytype(char *daytype) {
    if (strcmp("all days", daytype) == 0) return -1;
    if (strcmp("monday", daytype) == 0) return 1;
    if (strcmp("tuesday", daytype) == 0) return 2;
    if (strcmp("wednesday", daytype) == 0) return 3;
    if (strcmp("thursday", daytype) == 0) return 4;
    if (strcmp("friday", daytype) == 0) return 5;
    if (strcmp("saturday", daytype) == 0) return 6;
    if (strcmp("sunday", daytype) == 0) return 0;
    return -2;
}

int get_schedules(alerts_t *alert) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    if (alert->alert_groups_id == 0) return 0;

    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT A.day_type, A.start, A.end FROM alert_schedule_periods AS A "
                    "INNER JOIN alert_schedules AS B ON A.alert_schedule_id = B.id "
                    "WHERE B.id = %d AND B.status = 1", alert->group->email_schedule_id);

    if (mor_mysql_query(sqlcmd)) {
        return 1;
    }

    schedule_t *prev_schedule = NULL;
    schedule_t *current_schedule = NULL;

    result = mysql_store_result(&mysql);

    // fill alerts list
    while ((row = mysql_fetch_row(result)) != NULL) {

        current_schedule = malloc(sizeof(schedule_t));
        memset(current_schedule, 0, sizeof(schedule_t));

        current_schedule->prev = prev_schedule;

        if (row[0]) current_schedule->daytype = get_daytype(row[0]);
        if (row[1]) strcpy(current_schedule->start, row[1]);
        if (row[2]) strcpy(current_schedule->end, row[2]);

        prev_schedule = current_schedule;

    }

    alert->group->schedule = current_schedule;

    mysql_free_result(result);

    return 0;

}

int before_start() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int count = 0;

    if (mor_mysql_query("SELECT COUNT(*) FROM conflines WHERE name = 'alerts_need_update'")) {
        return 1;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) count = atoi(row[0]);
        }
    }
    mysql_free_result(result);

    if (count < 1) {
        if (mor_mysql_query("INSERT INTO conflines(name, value) VALUES('alerts_need_update', '1')")) {
            return 1;
        }
    }

    return 0;

}

int get_email_owner_index(int owner_id) {

    int index = -1;
    int i;

    for (i = 0; i < email_count; i++) {
        if (email[i].owner_id == owner_id) return i;
    }

    return index;

}

void _increment_clear_period(alerts_t *alert) {

    data_info_t *current = alert->data_info;

    while (current) {
        if (current->clear_period_countdown > 0) current->clear_period_countdown -= DATA_TICK_TIME;
        if (current->alert_is_set == 1) { // is alert set for current data?
            if (current->clear_period_counter >= alert->clear_period) {
                current->clear_period_counter = 0;
                current->clear_period_countdown = (alert->raw_period * 60) + 60;
                current->data_count = 0;
                current->data_sum = 0;
                report_alert(alert, current, 0);
            }
            current->clear_period_counter += DATA_TICK_TIME; // increment clear timer
        }
        current = current->next;
    }

}

void increment_clear_period() {

    int i = 0;

    for (i = 0; i < alerts_count; i++) {

        if (alerts[i].clear_period > 0 && !alerts[i].disable_clear) {
            _increment_clear_period(&alerts[i]);
        }

    }

}


/*
    Set clear on specific date
*/


void check_clear_date() {

    int i = 0;

    for (i = 0; i < alerts_count; i++) {
        if (strlen(alerts[i].clear_date) && !alerts[i].disable_clear) {

            int reported = 0;

            if (mor_compare_dates(date_str, alerts[i].clear_date)) {

                reported = 1;

                data_info_t *current = alerts[i].data_info;
                while (current) {

                    if (current->alert_is_set == 1) { // is alert set for current data?
                        if (mor_compare_dates(date_str, alerts[i].clear_date)) {
                            current->clear_period_counter = 0;
                            current->clear_period_countdown = (alerts[i].raw_period * 60) + 60;
                            current->data_count = 0;
                            current->data_sum = 0;
                            report_alert(&alerts[i], current, 0);
                        }
                    }
                    current = current->next;

                }
            }

            if (reported) {
                strcpy(alerts[i].clear_date, "");
                char sql_buffer[1024] = "";
                sprintf(sql_buffer, "UPDATE alerts SET clear_on_date = NULL WHERE id = %u", alerts[i].id);
                mor_mysql_query(sql_buffer);
            }

        }

    }

}

// update time every sec

void *update_time() {

    while (1) {
        time_t t;
        struct tm *tmp;
        t = time(NULL);
        tmp = localtime(&t);
        strftime(date_str, sizeof(date_str), DATE_FORMAT, tmp);
        time_t linux_time;
        struct tm *current_time;
        time(&linux_time);
        current_time = gmtime(&linux_time);
        current_hour = current_time->tm_hour;
        current_min = current_time->tm_min;
        current_day = current_time->tm_wday;
        sleep(1);
    }

    pthread_exit(NULL);
}



/*
    Create action log for email sending (failed and successful attempts)
*/


void email_action_log(int user_id, char *email, int status, char *error) {

    char sqlcmd[1024] = "";
    char email_to_db[128] = "no email";
    char error_to_db[128] = "unknown reason";

    if (strlen(email)) {
        strcpy(email_to_db, email);
    }

    if (strlen(error)) {
        strcpy(error_to_db, error);
    }

    if (status == 1) {
        sprintf(sqlcmd, "INSERT INTO actions(action, user_id, target_id, data, date, target_type) VALUES('email_send', 0, '%d', '%s', NOW(), 'user')", user_id, email_to_db);
    } else {
        sprintf(sqlcmd, "INSERT INTO actions(action, user_id, target_id, data, data2, data3, date, target_type) VALUES('error', '0', '%d', '%s', \"Can't send email\", '%s', NOW(), 'user')", user_id, error_to_db, email_to_db);
    }

    mor_mysql_query(sqlcmd);

}


/*
    Create action log for alert action
*/


void alert_action_log(char *msg, int alert, int alert_id) {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd, "INSERT INTO actions(action, user_id, target_id, data, data2, date, target_type) VALUES('alerts', 0, '%d', '%s', '%s', NOW(), 'alert')", alert_id, alert == 1 ? "alert" : "clear", msg);
    mor_mysql_query(sqlcmd);

}
