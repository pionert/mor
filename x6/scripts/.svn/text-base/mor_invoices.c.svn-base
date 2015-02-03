// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2014
// About:         Script generates invoices


#define _GNU_SOURCE
#define SCRIPT_VERSION "1.0"
#define SCRIPT_NAME    "mor_invoices"
#define GUICONFPATH    "/home/mor/config/environment.rb"

#include "mor_functions.c"
#include "mor_invoices.h"

// MAIN FUNCTION

int main(int argc, char const *argv[]) {

    // mark task as failed on segmentation fault
    struct sigaction sa;
    memset(&sa, 0, sizeof(struct sigaction));
    sigemptyset(&sa.sa_mask);
    sa.sa_sigaction = error_handle;
    sa.sa_flags = SA_SIGINFO;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    int i = 0;

    if (argc > 1 && argv[1] && strcmp(argv[1], "recalculate") == 0) {
        recalculate = 1;
    }

    // mark task as failed on returns
    atexit(error_handle);

    // starting sript
    mor_init("Starting MOR X6 Invoices script\n");

    if (recalculate) {
        // recalculate invoice
        if (mor_task_get(4, &user_id, &owner_id, date_from, date_till, user_type, NULL, NULL, NULL)) return 1;
    } else {
        // generate invoice
        if (mor_task_get(3, &user_id, &owner_id, date_from, date_till, user_type, issue_date, currency, NULL)) return 1;
    }

    strncpy(date_from_date_only, date_from, 10);
    strncpy(date_till_date_only, date_till, 10);

    if (!strlen(date_from) || !strlen(date_till)) {
        mor_log("Got empty invoice dates!\n");
        exit(1);
    }

    if (!strlen(user_type)) {
        mor_log("Can't determine invoice user type\n");
        exit(1);
    }

    if (!recalculate && strlen(currency) != 3) {
        mor_log("Can't determine currency (%s)\n", currency);
        exit(1);
    }

    if (!recalculate) {
        exchange_rate = get_exchange_rate(currency);
    }

    // set time for date_from and date_till
    strcpy(date_from + 10, " 00:00:00");
    strcpy(date_till + 10, " 23:59:59");
    mor_log("Date from: %s\n", date_from);
    mor_log("Date till: %s\n", date_till);

    if (recalculate) {
        mor_log("Invoices will be recalculated in period %s - %s\n", date_from, date_till);
    }

    if (get_invoice_settings()) exit(1);
    if (get_web_config()) exit(1);

    // get initial variables
    mor_get_current_date(current_date);
    mor_log("Current server time: %s\n", current_date);
    get_server_gmt_offset();

    if (!recalculate) {
        // do the job
        if (get_users_data(-1)) exit(1);
        if (check_completed_invoices()) exit(1);
        if (get_invoice_data()) exit(1);
    } else {
        if (get_recalculate_invoices()) exit(1);
        for (i = 0; i < recalculate_invoices_count; i++) {
            mor_log("\n");
            mor_log("<<<<<<<<<<<<< Recalculating invoice (%lld) >>>>>>>>>>>> \n", recalculate_invoices[i].id);
            mor_log("\n");
            // set known invoice data for user
            strcpy(currency, recalculate_invoices[i].invoice_currency);
            exchange_rate = get_exchange_rate(currency);
            strcpy(date_from, recalculate_invoices[i].date_from);
            strcpy(date_till, recalculate_invoices[i].date_till);
            strcpy(issue_date, recalculate_invoices[i].issue_date);
            strcpy(date_from + 10, " 00:00:00");
            strcpy(date_till + 10, " 23:59:59");
            mor_log("Date from: %s\n", date_from);
            mor_log("Date till: %s\n", date_till);
            if (get_users_data(recalculate_invoices[i].user_id)) exit(1);
            // set known invoice data for user
            strcpy(users[0].invoice_number, recalculate_invoices[i].invoice_number);
            users[0].invoice_id = recalculate_invoices[i].id;
            if (get_invoice_data()) exit(1);
        }
    }

    mor_log("\n");
    mor_task_finish();

    // close mysql connection
    mysql_close(&mysql);
    mysql_library_end();
    if (users) free(users);
    if (invoice_details) free(invoice_details);
    if (invoices) free(invoices);

    mor_log("Script completed!\n");
    task_failed = 0;

    return 0;

}


/*

    ############  FUNCTIONS #######################################################

*/


/*
    Get users and calculate billing periods
*/


int get_users_data(int user_id_parameter) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[1024] = "";
    char user_sql[256] = "";

    if (user_id_parameter == -1) {
        if (strcmp(user_type, "user") == 0) {
            sprintf(user_sql, "users.id = %d", user_id);
        } else if (strcmp(user_type, "postpaid") == 0) {
            sprintf(user_sql, "users.postpaid = 1");
        } else if (strcmp(user_type, "prepaid") == 0) {
            sprintf(user_sql, "users.postpaid = 0");
        }
    } else {
        sprintf(user_sql, "users.id = %d", user_id_parameter);
    }

    sprintf(query, "SELECT users.id, username, currencies.exchange_rate, currencies.name, users.time_zone, NULL, addresses.address, "
        "addresses.city, addresses.postcode, addresses.state, addresses.direction_id, addresses.phone, timezones.offset, users.postpaid, users.tax_id, "
        "owner_id, compound_tax, tax1_enabled, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value "
        "FROM users "
        "JOIN currencies ON currencies.id = users.currency_id "
        "LEFT JOIN addresses ON addresses.id = users.address_id "
        "LEFT JOIN timezones ON timezones.zone = users.time_zone "
        "LEFT JOIN taxes ON taxes.id = users.tax_id "
        "WHERE users.generate_invoice = 1 AND users.owner_id = %d AND %s", owner_id, user_sql);

    // get user data
    if (mor_mysql_query(query)) {
        return 1;
    }

    users_count = 0;

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                if (row[0]) {

                    users = realloc(users, (users_count + 1) * sizeof(users_t));
                    memset(&users[users_count], 0, sizeof(users_t));

                    if (row[0]) users[users_count].id = atoi(row[0]);
                    if (row[1]) strcpy(users[users_count].name, row[1]);
                    // why should we use user's currency if currency is passed to background tasks?
                    // if (row[2]) users[users_count].exchange_rate = atof(row[2]);
                    // if (row[3]) strcpy(users[users_count].currency, row[3]);
                    users[users_count].exchange_rate = exchange_rate;
                    strcpy(users[users_count].currency, currency);
                    if (row[4]) strcpy(users[users_count].timezone, row[4]);
                    // row[5] NULL
                    if (row[6]) strcpy(users[users_count].address, row[6]);
                    if (row[7]) strcpy(users[users_count].city, row[7]);
                    if (row[8]) strcpy(users[users_count].postcode, row[8]);
                    if (row[9]) strcpy(users[users_count].state, row[9]);
                    if (row[10]) users[users_count].direction_id = atoi(row[10]);
                    if (row[11]) strcpy(users[users_count].phone, row[11]);
                    if (row[12]) users[users_count].timezone_offset = ((float)atoi(row[12]) / 60.0 / 60.0);
                    if (row[13]) users[users_count].postpaid = atoi(row[13]);
                    if (row[14]) users[users_count].tax_id = atoi(row[14]);
                    if (row[15]) users[users_count].owner_id = atoi(row[15]);
                    if (row[16]) users[users_count].tax_compound = atoi(row[16]);
                    if (row[17]) users[users_count].tax1 = atoi(row[17]);
                    if (row[18]) users[users_count].tax2 = atoi(row[18]);
                    if (row[19]) users[users_count].tax3 = atoi(row[19]);
                    if (row[20]) users[users_count].tax4 = atoi(row[20]);
                    if (row[21]) users[users_count].tax1_value = atof(row[21]);
                    if (row[22]) users[users_count].tax2_value = atof(row[22]);
                    if (row[23]) users[users_count].tax3_value = atof(row[23]);
                    if (row[24]) users[users_count].tax4_value = atof(row[24]);

                    if (users[users_count].exchange_rate == 0) {
                        users[users_count].exchange_rate = 1;
                    }

                    users_count++;

                }

            }
        }
    }

    mysql_free_result(result);

    if (users_count == 0) {
        mor_log("No suitable users found...\n");
        return 1;
    } else {

        int i;

        mor_log("\n");
        mor_log("Users found:\n");
        for (i = 0; i < users_count; i++) {

            // calculate period start and period end according to user's timezone
            if (server_offset != users[i].timezone_offset) {
                adjust_to_target_time(date_from, users[i].server_period_start, users[i].timezone_offset, 0);
                adjust_to_target_time(date_till, users[i].server_period_end, users[i].timezone_offset, 0);
            } else {
                strcpy(users[i].server_period_start, date_from);
                strcpy(users[i].server_period_end, date_till);
            }

            mor_log("id: %d, username: %s, currency: %s, exchange_rate: %f, timezone: %s, offset: %.1f, postpaid: %d, "
                "server period start: %s, server period end: %s\n",
                users[i].id, users[i].name, users[i].currency, users[i].exchange_rate, users[i].timezone,
                users[i].timezone_offset, users[i].postpaid, users[i].server_period_start, users[i].server_period_end);
        }
        mor_log("\n");

    }

    return 0;

}

/*
    Adjust datetime to to server time or to user time

    for example:

    if user time is 2014-01-22 16:00:33 and GMT offset is +2 and server GMT offset is -1
    then adjusted datetime to server time is 2014-01-22 13:00:33

    same with server time to user time
*/


void adjust_to_target_time(char *date, char *buffer, float offset, int target) {

    char *tz;
    tz = getenv("TZ");
    if (tz) tz = strdup(tz);
    setenv("TZ", "UTC", 1);
    tzset();

    // convert user time to server time
    // calculate user period time in server offset
    time_t user_time;
    struct tm user_tm, server_ptm;

    // adjust period_start according to server time
    memset(&user_tm, 0, sizeof(struct tm));
    strptime(date, DATE_FORMAT, &user_tm);

    // target = 1, adjust to user time
    // target = 0, adjust to server time
    if (target) {
        user_time = mktime(&user_tm) - (time_t)round((server_offset - offset) * 60.0 * 60.0);
    } else {
        user_time = mktime(&user_tm) - (time_t)round((offset - server_offset) * 60.0 * 60.0);
    }

    gmtime_r(&user_time, &server_ptm);
    strftime(buffer, 20, DATE_FORMAT, &server_ptm);

    // restore timezone sessions variable
    if (tz) {
        setenv("TZ", tz, 1);
        free(tz);
    } else {
        unsetenv("TZ");
    }
    tzset();

}


/*
    Compare two date strings
*/


int compare_dates(const char *date1, const char *date2, int mode) {

    time_t t1, t2;
    struct tm tm1, tm2;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(date1, DATE_FORMAT, &tm1);
    strptime(date2, DATE_FORMAT, &tm2);

    t1 = mktime(&tm1);
    t2 = mktime(&tm2);

    if (mode == 0) {
        if (t1 >= t2) return 1;
    } else if (mode == 1) {
        if (t1 > t2) return 1;
    } else if (mode == 2) {
        if (t1 < t2) return 1;
    } else if (mode == 3) {
        if (t1 <= t2) return 1;
    }

    return 0;

}


/*
    Check if invoice already exists for user previous user billing period
    these users will be skipped to prevent duplicate insertions to invoices
*/


int check_completed_invoices() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int i;

    for (i = 0; i < users_count; i++) {

        if (!users[i].skip) {

            // get invoices for previous billing period
            char query[1024] = "";
            sprintf(query, "SELECT id FROM invoices WHERE user_id = %d AND period_start = '%s' AND period_end = '%s'", users[i].id, date_from_date_only, date_till_date_only);

            // send query
            if (mor_mysql_query(query)) {
                return 1;
            }

            // get results
            result = mysql_store_result(&mysql);
            if (result) {
                if (mysql_num_rows(result)) {
                    row = mysql_fetch_row(result);
                    if (row[0]) {
                        mor_log("Invoice for user %s and date %s - %s already exists. Invoice will not be generated for this period\n", users[i].name, date_from, date_till);
                        users[i].skip = 1;
                    }
                }
            }

            mysql_free_result(result);

        }

    }

    return 0;

}


/*
    Insert new record into invoices table and get that record id
*/


int insert_new_invoices(int index) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int i = 0;
    char query[1024] = "";

    // when we have specific index of users structure
    // then skip iterations and go straight to that user
    if (index > -1) {
        i = index;
        goto single_user;
    }

    for (i = 0; i < users_count; i++) {

        if (!users[i].skip) {

            single_user:;

            // calculate invoice number
            if (!recalculate) {
                generate_invoice_number(&users[i]);
            }

            // insert new invoice
            if (!recalculate) {
                mor_log("Inserting new invoice for %s (%d), period_start: %s, period_end: %s\n", users[i].name, users[i].id, date_from, date_till);
                sprintf(query, "INSERT INTO invoices(user_id, period_start, period_end, timezone, client_name, invoice_currency, client_details1, "
                    "client_details2, client_details3, client_details4, client_details5, client_details6, number, issue_date, invoice_type, tax_id, "
                    "invoice_precision, number_type) "
                    "VALUES(%d, '%s', '%s', '%s (GMT %s%g)', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%s', '%s', '%s', '%s', '%d', '%d', '%d')",
                    users[i].id, date_from_date_only, date_till_date_only, users[i].timezone, users[i].timezone_offset >= 0 ? "+" : "", users[i].timezone_offset,
                    users[i].name, currency, users[i].address, users[i].city, users[i].postcode, users[i].state, users[i].direction_id,
                    users[i].phone, users[i].invoice_number, issue_date, users[i].postpaid == 1 ? "postpaid" : "prepaid", users[i].tax_id, users[i].precision, users[i].number_type);
            } else {
                // update invoice
                mor_log("Updating invoice for %s (%d), period_start: %s, period_end: %s\n", users[i].name, users[i].id, date_from, date_till);
                sprintf(query, "UPDATE invoices set timezone = '%s (GMT %s%g)', client_name = '%s', client_details1 = '%s', "
                    "client_details2 = '%s', client_details3 = '%s', client_details4 = '%s', client_details5 = %d, client_details6 = '%s', "
                    "issue_date = '%s', tax_id = %d WHERE id = %lld",
                    users[i].timezone, users[i].timezone_offset >= 0 ? "+" : "", users[i].timezone_offset, users[i].name, users[i].address,
                    users[i].city, users[i].postcode, users[i].state, users[i].direction_id, users[i].phone, issue_date,
                    users[i].tax_id, users[i].invoice_id);
            }

            if (mor_mysql_query(query)) {
                return 1;
            }

            // now get its id
            if (!recalculate) {
                sprintf(query, "SELECT id FROM invoices WHERE user_id = %d AND period_start = '%s' and period_end = '%s'", users[i].id, date_from_date_only, date_till_date_only);

                if (mor_mysql_query(query)) {
                    return 1;
                }

                // get results
                result = mysql_store_result(&mysql);
                if (result) {
                    if (mysql_num_rows(result)) {
                        row = mysql_fetch_row(result);
                        if (row[0]) {
                            users[i].invoice_id = atoll(row[0]);
                            mor_log("Inserted invoice_id: %lld, invoice number: %s\n", users[i].invoice_id, users[i].invoice_number);
                        }
                    }
                }
                mysql_free_result(result);

                // check if we got inserted invoice id
                if (users[i].invoice_id == 0) {
                    mor_log("Can't determine inserted invoice_id\n");
                    exit(1);
                }
            }

        } else {
            mor_log("Invoice already exist or it is too early to generate new one\n");
            mor_log("New invoice will not be created for for user %s (%d), period_start: %s, period_end: %s\n", users[i].name, users[i].id, date_from, date_till);
        }

        // when we have specific index of users structure
        // then break the loop
        if (index > -1) goto exit_single_user;

    }

    exit_single_user:

    return 0;

}


/*
    Get aggregates call details for calls in previous billing period
*/


int get_invoice_data() {

    char query[2048] = "";
    int i = 0;

    // total price/calls
    double total_price = 0;
    double total_price_with_tax = 0;

    for (i = 0; i < users_count; i++) {
        if (!users[i].skip) {

            if (!recalculate) {
                mor_log("\n");
                mor_log("<<<<<<<<<<<<< Checking invoice data for user %s (%d) >>>>>>>>>>>>\n", users[i].name, users[i].id);
            }

            // reset variables for each user
            invoice_details_count = 0;
            total_price = 0;
            total_price_with_tax = 0;

            // get outgoing calls for user
            mor_log("\n");
            mor_log("*** Checking outgoing calls for user %s (%d) ***\n", users[i].name, users[i].id);
            if (calculate_outgoing_calls_price(i, &total_price, &total_price_with_tax)) {
                continue;
            }

            // get did owner price for user
            mor_log("\n");
            mor_log("*** Checking DID owner price for user %s (%d) ***\n", users[i].name, users[i].id);
            if (calculate_did_price(i, &total_price, &total_price_with_tax, 1)) {
                continue;
            }

            // get did incoming price for user
            mor_log("\n");
            mor_log("*** Checking DID incoming price for user %s (%d) ***\n", users[i].name, users[i].id);
            if (calculate_did_price(i, &total_price, &total_price_with_tax, 0)) {
                continue;
            }

            // get sms
            mor_log("\n");
            mor_log("*** Checking sms for user %s (%d) ***\n", users[i].name, users[i].id);
            calculate_sms_price(i, &total_price, &total_price_with_tax);

            // subscriptions
            mor_log("\n");
            mor_log("*** Checking subscriptions for user %s (%d) ***\n", users[i].name, users[i].id);
            calculate_subscription_price(i, &total_price, &total_price_with_tax);

            // insert invoice lines to invoice_lines table
            // insert will be in batches to improve performance
            mor_log("\n");
            mor_log("Total invoice price: %f, price with tax: %f\n", total_price, total_price_with_tax);
            if (insert_new_invoices(i)) exit(1);
            if (recalculate) {
                delete_invoicedetails(users[i].invoice_id);
            }
            insert_invoicedetails(users[i].invoice_id);
            // update invoices with calculated amount and amount_with_taxes
            sprintf(query, "UPDATE invoices SET price = %f, price_with_vat = %f WHERE id = %lld", total_price, total_price_with_tax, users[i].invoice_id);
            // send query
            if (mor_mysql_query(query)) {
                return 1;
            }
            if (strlen(web_url) && strlen(web_dir)) {
                // send API to GUI to generate XLSX invoice file
                char wgetcmd[1024] = "";
                sprintf(wgetcmd, "wget --spider -q %s%s/api/invoice_xlsx_generate?invoice_id=%lld&test=1", web_url, web_dir, users[i].invoice_id);
                mor_log("Sending API request to generate XLSX file: %s\n", wgetcmd);
                system(wgetcmd);
                // wait
                sleep(1);
            } else {
                mor_log("Web URL or Web DIR variable is not set, XLSX file will not be created\n");
            }
        }
    }

    return 0;

}


/*
    Insert aggregated call data to invoice_lines
*/


int insert_invoicedetails(long long int invoice_id) {

    int i;
    char query[9000] = "";
    char buffer[8800] = "";

    mor_log("Total invoice lines for this user and billing period: %d\n", invoice_details_count);

    // query header
    sprintf(query, "INSERT INTO invoicedetails(invoice_id, prefix, name, price, total_time, quantity, invdet_type) VALUES ");

    // format batches
    for (i = 0; i < invoice_details_count; i++) {

        char tmp_buffer[1024] = "";

        sprintf(tmp_buffer, "(%lld, '%s', '%s', %f, %d, %d, %d),",
            invoice_id, invoice_details[i].prefix, invoice_details[i].service, invoice_details[i].price,
            invoice_details[i].billsec, invoice_details[i].units, invoice_details[i].invdet_type);

        // check buffer overflow
        if (strlen(buffer) > 8700) {

            // remove last comma separator
            buffer[strlen(buffer) - 1] = ' ';
            strcat(query, buffer);
            // send query
            if (mor_mysql_query(query)) {
                return 1;
            }

            // query header
            sprintf(query, "INSERT INTO invoice_lines(invoice_id, destination, service, price, total_time, units) VALUES ");
            strcpy(buffer, "");

        }

        strcat(buffer, tmp_buffer);

    }

    if (strlen(buffer)) {
        // remove last comma separator
        buffer[strlen(buffer) - 1] = ' ';
        strcat(query, buffer);

        // send query
        if (mor_mysql_query(query)) {
            exit(1);
        }
    }

    return 0;

}


/*
    Get timestamp (time in seconds since 1970) from date string
*/


time_t get_timestamp(char *date) {

    time_t timestamp;
    struct tm time_tm;

    // convert date to seconds
    memset(&time_tm, 0, sizeof(struct tm));
    strptime(date, DATE_FORMAT, &time_tm);
    timestamp = mktime(&time_tm);

    return timestamp;

}


/*
    Get date string from timestamp (time in seconds since 1970)
*/


void timestamp_to_string(time_t timestamp, char *date) {
    // current time variables
    struct tm ptm;
    gmtime_r(&timestamp, &ptm);
    strftime(date, 20, DATE_FORMAT, &ptm);
}


/*
    Format time_periods sql from given date
*/


void get_time_periods_sql(char *user_start_time, char *user_end_time, char *time_periods_sql) {

    char *tz;
    // set UTC time zone to avoid daylight saving
    tz = getenv("TZ");
    if (tz) tz = strdup(tz);
    setenv("TZ", "UTC", 1);
    tzset();

    char start_time[20] = "";
    char end_time[20] = "";

    strcpy(start_time, user_start_time);
    strcpy(end_time, user_end_time);

    if (strcmp(start_time + 14, "00:00") != 0) {
        strcpy(start_time + 14, "00:00");
    }

    time_t start_time_timestamp, end_time_timestamp;

    mor_log("Checking calls for date: %s - %s\n", start_time, end_time);

    if (compare_dates(start_time, end_time, 1)) {
        mor_log("Time periods start_time > end_time\n");
        return;
    }

    start_time_timestamp = get_timestamp(start_time);
    end_time_timestamp = get_timestamp(end_time);

    int start_time_hour = get_date_param(start_time, 1);
    int end_time_hour = get_date_param(end_time, 1);
    char hours_from_start[20] = "";
    char hours_from_end[20] = "";
    char hours_till_start[20] = "";
    char hours_till_end[20] = "";

    if (start_time_hour > 0) {
        time_t missing_hours = start_time_timestamp + (24 - start_time_hour)*60*60;
        strcpy(hours_from_start, start_time);
        timestamp_to_string(missing_hours - 1, hours_from_end);
        timestamp_to_string(missing_hours, start_time);
        start_time_timestamp = missing_hours;
    } else {
        strcpy(hours_from_start, start_time);
        strcpy(hours_from_end, start_time);
    }

    if (compare_dates(end_time, hours_from_end, 1)) {
        if (end_time_hour < 23) {
            time_t missing_hours = end_time_timestamp - (end_time_hour + 1)*60*60;
            timestamp_to_string(missing_hours + 1, hours_till_start);
            strcpy(hours_till_end, end_time);
            timestamp_to_string(missing_hours, end_time);
            end_time_timestamp = missing_hours;
        } else {
            strcpy(hours_till_start, end_time);
            strcpy(hours_till_end, end_time);
        }

        if (compare_dates(hours_from_end, hours_from_start, 1)) {
            char tmp_buffer[128] = "";
            sprintf(tmp_buffer, "(time_periods.period_type = 'hour' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", hours_from_start, hours_from_end);
            strcat(time_periods_sql, tmp_buffer);
        }

        if (compare_dates(hours_till_end, hours_till_start, 1)) {
            char tmp_buffer[128] = "";
            sprintf(tmp_buffer, "(time_periods.period_type = 'hour' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", hours_till_start, hours_till_end);
            strcat(time_periods_sql, tmp_buffer);
        }
    } else {
        char tmp_buffer[128] = "";
        sprintf(tmp_buffer, "(time_periods.period_type = 'hour' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", hours_from_start, end_time);
        strcat(time_periods_sql, tmp_buffer);
    }

    if (compare_dates(end_time, start_time, 1)) {

        int start_time_day = get_date_param(start_time, 2);
        int end_time_day = get_date_param(end_time, 2);
        char days_from_start[20] = "";
        char days_from_end[20] = "";
        char days_till_start[20] = "";
        char days_till_end[20] = "";

        if (start_time_day > 1) {
            time_t missing_days = start_time_timestamp + (get_last_datetime_of_month(start_time, NULL, 1) - start_time_day + 1)*24*60*60;
            strcpy(days_from_start, start_time);
            timestamp_to_string(missing_days - 1, days_from_end);
            timestamp_to_string(missing_days, start_time);
            start_time_timestamp = missing_days;
        } else {
            strcpy(days_from_start, start_time);
            strcpy(days_from_end, start_time);
        }

        if (compare_dates(end_time, days_from_end, 1)) {
            if (end_time_day < get_last_datetime_of_month(end_time, NULL, 1)) {
                time_t missing_days = end_time_timestamp - end_time_day*24*60*60;
                timestamp_to_string(missing_days + 1, days_till_start);
                strcpy(days_till_end, end_time);
                timestamp_to_string(missing_days, end_time);
                end_time_timestamp = missing_days;
            } else {
                strcpy(days_till_start, end_time);
                strcpy(days_till_end, end_time);
            }


            if (compare_dates(days_from_end, days_from_start, 1)) {
                char tmp_buffer[128] = "";
                sprintf(tmp_buffer, "(time_periods.period_type = 'day' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", days_from_start, days_from_end);
                strcat(time_periods_sql, tmp_buffer);
            }

            if (compare_dates(days_till_end, days_till_start, 1)) {
                char tmp_buffer[128] = "";
                sprintf(tmp_buffer, "(time_periods.period_type = 'day' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", days_till_start, days_till_end);
                strcat(time_periods_sql, tmp_buffer);
            }
        } else {
            char tmp_buffer[128] = "";
            sprintf(tmp_buffer, "(time_periods.period_type = 'day' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", days_from_start, end_time);
            strcat(time_periods_sql, tmp_buffer);
        }

        if (compare_dates(end_time, start_time, 1)) {
            char tmp_buffer[128] = "";
            sprintf(tmp_buffer, "(time_periods.period_type = 'month' AND time_periods.from_date BETWEEN '%s' AND '%s') OR ", start_time, end_time);
            strcat(time_periods_sql, tmp_buffer);
        }

    }

    time_periods_sql[strlen(time_periods_sql) - 3] = 0;

    // restore timezone sessions variable
    if (tz) {
        setenv("TZ", tz, 1);
        free(tz);
    } else {
        unsetenv("TZ");
    }
    tzset();

}


/*
    Get parameter from date string
    param 1 - hour
    param 2 - month day
*/


int get_date_param(char *date, int param) {

    // current time variables
    struct tm time_tm;

    // convert date to seconds
    memset(&time_tm, 0, sizeof(struct tm));
    strptime(date, DATE_FORMAT, &time_tm);

    if (param == 1) return time_tm.tm_hour;
    if (param == 2) return time_tm.tm_mday;

    return 0;

}


/*
    Format current date to last datetime of current month of previous month

    for example: if current datetime is 2014-01-23 15:10:20, then
    last datetime of current month is 2014-01-31 23:59:59
    last datetime of previous month is 2013-12-31 23:59:59

    current_month = 1, get last datetime for current month
    current_month = 0, get last datetime for previous month
*/


int get_last_datetime_of_month(char *date, char *buffer, int current_month) {

    time_t tmp_time;
    struct tm tmp_tm, tmp_ptm;
    char tmp_date[20] = "";

    // copy date to tmp
    strcpy(tmp_date, date);
    // set tmp_date to first day of month
    strcpy(tmp_date + 8, "01 00:00:00");
    // format time structure according to date
    memset(&tmp_tm, 0, sizeof(struct tm));
    strptime(tmp_date, DATE_FORMAT, &tmp_tm);

    // get seconds
    tmp_time = mktime(&tmp_tm);

    // in case we need to know last datetime of current month
    if (current_month) {
        // add 31 days and few hours to advance to next month
        tmp_time += (31*60*60*24 + 2*60*60);
        // convert seconds to time structure
        gmtime_r(&tmp_time, &tmp_ptm);
        // format date string
        strftime(tmp_date, sizeof(tmp_date), DATE_FORMAT, &tmp_ptm);
        // reset back to first day of calculated month
        strcpy(tmp_date + 8, "01 00:00:00");
        // convert date string back to time structure
        memset(&tmp_tm, 0, sizeof(struct tm));
        strptime(tmp_date, DATE_FORMAT, &tmp_tm);
        // get adjusted time in seconds
        tmp_time = mktime(&tmp_tm);
    }

    // go back 10 seconds to get back to previous month
    tmp_time -= 10;
    // convert date to time structure
    gmtime_r(&tmp_time, &tmp_ptm);
    if (buffer != NULL) {
        // format date string
        strftime(buffer, 20, DATE_FORMAT, &tmp_ptm);
        // set last hour, minute, second of calculated month
        strcpy(buffer + 11, "23:59:59");
    }

    return tmp_ptm.tm_mday;

}


/*
    Get invoice settings from conflines table
*/


int get_invoice_settings() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int i = 0;
    int last_owner_id = -1;
    char query[1024] = "";

    mor_log("Checking invoice settings\n");
    sprintf(query, "SELECT value, name, owner_id FROM conflines WHERE name IN ('Invoice_Number_Start', 'Invoice_Number_Length', 'Invoice_Number_Type', 'Prepaid_Invoice_Number_Start', 'Prepaid_Invoice_Number_Length', 'Prepaid_Invoice_Number_Type', 'Nice_Number_Digits') ORDER BY owner_id, name, value DESC");
    if (mor_mysql_query(query)) {
        return 1;
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {
                if (row[0] && row[1] && row[2]) {
                    int new_owner = 0;
                    if (atoi(row[2]) != last_owner_id) {
                        new_owner = 1;
                        invoice_settings = realloc(invoice_settings, (invoice_settings_count + 1) * sizeof(invoice_settings_t));
                        memset(&invoice_settings[invoice_settings_count], 0, sizeof(invoice_settings_t));
                        invoice_settings[invoice_settings_count].precision = 2;
                    }
                    if (new_owner) {
                        if (strcmp(row[1], "Invoice_Number_Type") == 0) invoice_settings[invoice_settings_count].invoice_number_type = atoi(row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Type") == 0) invoice_settings[invoice_settings_count].prepaid_invoice_number_type = atoi(row[0]);
                        if (strcmp(row[1], "Invoice_Number_Length") == 0) invoice_settings[invoice_settings_count].invoice_number_length = atoi(row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Length") == 0) invoice_settings[invoice_settings_count].prepaid_invoice_number_length = atoi(row[0]);
                        if (strcmp(row[1], "Invoice_Number_Start") == 0) strcpy(invoice_settings[invoice_settings_count].invoice_number_start, row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Start") == 0) strcpy(invoice_settings[invoice_settings_count].prepaid_invoice_number_start, row[0]);
                        if (strcmp(row[1], "Nice_Number_Digits") == 0) invoice_settings[invoice_settings_count].precision = atoi(row[0]);
                        invoice_settings[invoice_settings_count].owner_id = atoi(row[2]);
                    } else {
                        if (strcmp(row[1], "Invoice_Number_Type") == 0) invoice_settings[invoice_settings_count - 1].invoice_number_type = atoi(row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Type") == 0) invoice_settings[invoice_settings_count - 1].prepaid_invoice_number_type = atoi(row[0]);
                        if (strcmp(row[1], "Invoice_Number_Length") == 0) invoice_settings[invoice_settings_count - 1].invoice_number_length = atoi(row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Length") == 0) invoice_settings[invoice_settings_count - 1].prepaid_invoice_number_length = atoi(row[0]);
                        if (strcmp(row[1], "Invoice_Number_Start") == 0) strcpy(invoice_settings[invoice_settings_count - 1].invoice_number_start, row[0]);
                        if (strcmp(row[1], "Prepaid_Invoice_Number_Start") == 0) strcpy(invoice_settings[invoice_settings_count - 1].prepaid_invoice_number_start, row[0]);
                        if (strcmp(row[1], "Nice_Number_Digits") == 0) invoice_settings[invoice_settings_count - 1].precision = atoi(row[0]);
                        invoice_settings[invoice_settings_count - 1].owner_id = atoi(row[2]);
                    }
                    if (new_owner) {
                        invoice_settings_count++;
                    }
                    last_owner_id = atoi(row[2]);
                }
            }
        }
        mysql_free_result(result);
    }


    if (invoice_settings_count) {
        for (i = 0; i < invoice_settings_count; i++) {

            if (invoice_settings[i].precision < 0) {
                invoice_settings[i].precision = 0;
            }

            mor_log("Owner: %d, postpaid invoice number type: %d, postpaid invoice number length: %d, postpaid invoice number start: %s, "
                "prepaid invoice number type: %d, prepaid invoice number length: %d, prepaid invoice number start: %s, "
                "number precision: %d\n",
                invoice_settings[i].owner_id, invoice_settings[i].invoice_number_type, invoice_settings[i].invoice_number_length,
                invoice_settings[i].invoice_number_start, invoice_settings[i].prepaid_invoice_number_type, invoice_settings[i].prepaid_invoice_number_length,
                invoice_settings[i].prepaid_invoice_number_start, invoice_settings[i].precision);
            if (invoice_settings[i].invoice_number_type != 1 && invoice_settings[i].invoice_number_type != 2) {
                mor_log("Can't determine postpaid invoice number type: %d\n", invoice_settings[i].invoice_number_type);
            }
            if (invoice_settings[i].prepaid_invoice_number_type != 1 && invoice_settings[i].prepaid_invoice_number_type != 2) {
                mor_log("Can't determine prepaid invoice number type: %d\n", invoice_settings[i].prepaid_invoice_number_type);
            }
        }
    } else {
        mor_log("Invoice settings not found!\n");
        exit(1);
    }

    return 0;

}


/*
    Generate invoice number based on invoice settings
*/


void generate_invoice_number(users_t *user) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int invoice_number_type = 0;
    char invoice_number_start[32] = "";
    int invoice_number_length = 0;
    int i = 0;
    char query[2048] = "";
    int owner_id = 0;

    for (i = 0; i < invoice_settings_count; i++) {
        if (user->owner_id == invoice_settings[i].owner_id) {
            if (user->postpaid) {
                invoice_number_type = invoice_settings[i].invoice_number_type;
                invoice_number_length = invoice_settings[i].invoice_number_length;
                strcpy(invoice_number_start, invoice_settings[i].invoice_number_start);
                user->number_type = invoice_settings[i].invoice_number_type;
            } else {
                invoice_number_type = invoice_settings[i].prepaid_invoice_number_type;
                invoice_number_length = invoice_settings[i].prepaid_invoice_number_length;
                strcpy(invoice_number_start, invoice_settings[i].prepaid_invoice_number_start);
                user->number_type = invoice_settings[i].prepaid_invoice_number_type;
            }
            user->precision = invoice_settings[i].precision;
            owner_id = user->owner_id;
            break;
        }
    }

    if (invoice_number_type == 1) {

        int start_len = strlen(invoice_number_start);
        char number_str[256] = "";
        long long int number = 0;

        sprintf(query, "SELECT number FROM invoices "
            "LEFT JOIN users ON users.id = invoices.user_id "
            "WHERE SUBSTRING(number, 1, %d) = '%s' AND users.owner_id = %d AND number_type = 1 "
            "ORDER BY CAST(SUBSTRING(number, %d, 255) AS SIGNED) DESC LIMIT 1", start_len, invoice_number_start, owner_id, start_len + 1);

        if (mor_mysql_query(query)) {
            exit(1);
        }

        // get results
        result = mysql_store_result(&mysql);
        if (result) {
            if (mysql_num_rows(result)) {
                row = mysql_fetch_row(result);
                if (row[0]) {
                    strcpy(number_str, row[0]);
                }
            }
            mysql_free_result(result);
        }

        if (strlen(number_str)) {
            number = atoll(number_str + strlen(invoice_number_start)) + 1;
        } else {
            number = 1;
        }

        sprintf(user->invoice_number, "%s%0*llu", invoice_number_start, invoice_number_length, number);

    } else if (invoice_number_type == 2) {

        char year[3] = "";
        char month[3] = "";
        char day[3] = "";
        char tmp[256] = "";
        strncpy(year, date_from + 2, 2);
        strncpy(month, date_from + 5, 2);
        strncpy(day, date_from + 8, 2);
        int start_len = strlen(invoice_number_start) + 6;
        char number_str[256] = "";
        long long int number = 0;

        sprintf(query, "SELECT number FROM invoices "
            "LEFT JOIN users ON users.id = invoices.user_id "
            "WHERE SUBSTRING(number, 1, %d) = '%s%s%s%s' AND users.owner_id = %d AND number_type = 2 "
            "ORDER BY CAST(SUBSTRING(number, %d, 255) AS SIGNED) DESC LIMIT 1", start_len, invoice_number_start, year, month, day, owner_id, start_len + 1);

        if (mor_mysql_query(query)) {
            exit(1);
        }

        // get results
        result = mysql_store_result(&mysql);
        if (result) {
            if (mysql_num_rows(result)) {
                row = mysql_fetch_row(result);
                if (row[0]) {
                    strcpy(number_str, row[0]);
                }
            }
            mysql_free_result(result);
        }

        if (strlen(number_str)) {
            number = atoll(number_str + strlen(invoice_number_start) + 6) + 1;
        } else {
            number = 1;
        }

        sprintf(tmp, "%s%s%s%s", invoice_number_start, year, month, day);
        sprintf(user->invoice_number, "%s%0*llu", tmp, (int)(invoice_number_length - strlen(tmp)), number);

    } else {
        mor_log("Can't generate invoice, because invoice number type is unknown\n");
        exit(1);
    }

}


/*
    Get server GMT offset in decimal value
*/


void get_server_gmt_offset() {

    // get server gmt offset
    time_t t = time(NULL);
    struct tm lt = {0};
    localtime_r(&t, &lt);
    server_offset = lt.tm_gmtoff / 60.0 / 60.0;
    mor_log("Server GMT offset: %0.2f\n", server_offset);

}


/*
    How many months between dates?
*/


int months_between(char *date1, char *date2) {

    int months = 0;
    struct tm tm1, tm2;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(date1, DATE_FORMAT, &tm1);
    strptime(date2, DATE_FORMAT, &tm2);

    months = (tm2.tm_year - tm1.tm_year) * 12;
    months += tm2.tm_mon - tm1.tm_mon;

    return months;

}


/*
    How many days between dates?
*/


int days_between(char *date1, char *date2) {

    int days = 0;
    struct tm tm1, tm2;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(date1, DATE_FORMAT, &tm1);
    strptime(date2, DATE_FORMAT, &tm2);

    days = (tm2.tm_year - tm1.tm_year) * 12;
    days += tm2.tm_mon - tm1.tm_mon;
    days += tm2.tm_mday - tm1.tm_mday;

    return days;

}


/*
    Get day from date
*/


int get_day(char *date) {

    int day = 0;

    struct tm tm1;

    memset(&tm1, 0, sizeof(struct tm));
    strptime(date, DATE_FORMAT, &tm1);

    day = tm1.tm_mday;

    return day;

}


/*
    Get outgoing calls for users
*/


int calculate_outgoing_calls_price(int index, double *total_price, double *total_price_with_tax) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = "";
    char time_periods_sql[2048] = "";

    get_time_periods_sql(users[index].server_period_start, users[index].server_period_end, time_periods_sql);
    if (!strlen(time_periods_sql)) {
        mor_log("Time_periods_sql is empty. Skipping this user!\n");
        users[index].skip = 1;
        return 1;
    }

    // get aggregates calls by prefix
    sprintf(query, "SELECT prefix, SUM(user_billed), SUM(user_billed_billsec), SUM(answered_calls), destination, SUM(user_billed_with_tax) "
        "FROM aggregates "
        "JOIN time_periods ON time_periods.id = aggregates.time_period_id "
        "WHERE variation = 9 AND (%s) AND user_id = %d AND answered_calls > 0 AND user_billed > 0 "
        "GROUP BY prefix, user_id",
        time_periods_sql, users[index].id);

    // send query
    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                invoice_details = realloc(invoice_details, (invoice_details_count + 1) * sizeof(invoice_details_t));
                memset(&invoice_details[invoice_details_count], 0, sizeof(invoice_details_t));

                if (row[0]) strcpy(invoice_details[invoice_details_count].prefix, row[0]);
                if (row[1]) invoice_details[invoice_details_count].price = atof(row[1]);
                if (row[2]) invoice_details[invoice_details_count].billsec = atoi(row[2]);
                if (row[3]) invoice_details[invoice_details_count].units = atoi(row[3]);
                if (row[4]) strcpy(invoice_details[invoice_details_count].service, row[4]);
                if (row[5]) invoice_details[invoice_details_count].price_with_tax = atof(row[5]);
                invoice_details[invoice_details_count].user_id = users[index].id;

                invoice_details[invoice_details_count].price = invoice_details[invoice_details_count].price / users[index].exchange_rate;
                invoice_details[invoice_details_count].price_with_tax = invoice_details[invoice_details_count].price_with_tax / users[index].exchange_rate;

                mor_log("Destination: %s, prefix: %s, price: %f, price_with_tax: %f, billsec: %d, total_calls: %d\n",
                    invoice_details[invoice_details_count].service, invoice_details[invoice_details_count].prefix,
                    invoice_details[invoice_details_count].price, invoice_details[invoice_details_count].price_with_tax,
                    invoice_details[invoice_details_count].billsec, invoice_details[invoice_details_count].units);

                *total_price += invoice_details[invoice_details_count].price;
                *total_price_with_tax += invoice_details[invoice_details_count].price_with_tax;

                invoice_details_count++;

            }
        } else {
            mor_log("Calls data not found in this invoice period\n");
        }
    } else {
        mor_log("Calls data not found in this invoice period\n");
    }

    mysql_free_result(result);

    return 0;

}


/*
    Get sms price for users
*/


int calculate_sms_price(int index, double *total_price, double *total_price_with_tax) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = "";

    sprintf(query, "SELECT COUNT(*) AS sms_count, IFNULL(SUM(user_price), 0) AS total_sms_price "
        "FROM sms_messages "
        "WHERE user_id = %d AND user_price > 0 AND sending_date BETWEEN '%s' AND '%s'",
        users[index].id, users[index].server_period_start, users[index].server_period_end);

    // send query
    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                invoice_details = realloc(invoice_details, (invoice_details_count + 1) * sizeof(invoice_details_t));
                memset(&invoice_details[invoice_details_count], 0, sizeof(invoice_details_t));

                if (row[0]) invoice_details[invoice_details_count].units = atoi(row[0]);
                if (row[1]) invoice_details[invoice_details_count].price = atof(row[1]);
                if (row[1]) invoice_details[invoice_details_count].price_with_tax = atof(row[1]);
                invoice_details[invoice_details_count].user_id = users[index].id;
                strcpy(invoice_details[invoice_details_count].service, "SMS");

                mor_apply_taxes(&invoice_details[invoice_details_count].price_with_tax, users[index].tax_compound, users[index].tax1,
                    users[index].tax2, users[index].tax3, users[index].tax4, users[index].tax1_value, users[index].tax2_value, users[index].tax3_value,
                    users[index].tax4_value);

                invoice_details[invoice_details_count].price = invoice_details[invoice_details_count].price / users[index].exchange_rate;
                invoice_details[invoice_details_count].price_with_tax = invoice_details[invoice_details_count].price_with_tax / users[index].exchange_rate;

                if (invoice_details[invoice_details_count].price > 0) {
                    mor_log("SMS price: %f, total sms: %d\n", invoice_details[invoice_details_count].price,
                        invoice_details[invoice_details_count].units);

                    *total_price += invoice_details[invoice_details_count].price / users[index].exchange_rate;
                    *total_price_with_tax += invoice_details[invoice_details_count].price / users[index].exchange_rate;

                    invoice_details_count++;
                } else {
                    mor_log("SMS data not found in this invoice period\n");
                }
            }
        } else {
            mor_log("SMS data not found in this invoice period\n");
        }
    } else {
        mor_log("SMS data not found in this invoice period\n");
    }

    return 0;

}


/*
    Calculate price from subscriptions
*/


int calculate_subscription_price(int index, double *total_price, double *total_price_with_tax) {

    MYSQL_RES *result;
    MYSQL_RES *result_service;
    MYSQL_ROW row;
    MYSQL_ROW row_service;

    char query[2048] = "";
    char query_service[2048] = "";

    sprintf(query, "SELECT service_id, activation_start, activation_end, no_expire, memo FROM subscriptions WHERE ('%s' BETWEEN activation_start AND activation_end OR '%s' BETWEEN activation_start AND activation_end "
        "OR (activation_start > '%s' AND activation_end < '%s') OR (activation_start < '%s' AND activation_end IS NULL)) AND subscriptions.user_id = %d",
        date_from, date_till, date_from, date_till, date_till, users[index].id);

    if (mor_mysql_query(query)) {
        exit(1);
    }

    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                int sub_id = 0;
                char sub_activation_start[20] = "";
                char sub_activation_end[20] = "";
                double subscriptions_price = 0;
                int count_subscription = 0;
                int no_expire = 0;

                if (row[0]) sub_id = atoi(row[0]);
                if (row[1]) strcpy(sub_activation_start, row[1]);
                if (row[2]) strcpy(sub_activation_end, row[2]);
                if (row[3]) no_expire = atoi(row[3]);

                sprintf(query_service, "SELECT price, servicetype, periodtype FROM services WHERE id = %s", row[0]);

                if (mor_mysql_query(query_service)) {
                    exit(1);
                }

                result_service = mysql_store_result(&mysql);
                if (result_service) {
                    if (mysql_num_rows(result_service)) {
                        while (( row_service = mysql_fetch_row(result_service) )) {

                            char service_type[64] = "";
                            char period_type[64] = "";
                            double service_price = 0;

                            if (row_service[0]) service_price = atof(row_service[0]);

                            if (row_service[1]) {
                                strcpy(service_type, row_service[1]);
                            } else {
                                mor_log("%s\n", query_service);
                                mor_log("Unknown service type\n");
                                exit(1);
                            }

                            if (row_service[2]) {
                                strcpy(period_type, row_service[2]);
                            }

                            // one time fee
                            if (strcmp(service_type, "one_time_fee") == 0) {
                                mor_log("Calculating one time fee\n");
                                if (compare_dates(sub_activation_start, date_from, 0) && compare_dates(sub_activation_start, date_till, 3)) {
                                  subscriptions_price = service_price;
                                  count_subscription = 1;
                                }
                            }

                            // flat rate
                            if (strcmp(service_type, "flat_rate") == 0) {
                                mor_log("Calculating flat rate\n");
                                if (no_expire == 1) {
                                    if (compare_dates(sub_activation_start, users[index].server_period_start, 0) && compare_dates(sub_activation_start, users[index].server_period_end, 3)) {
                                        subscriptions_price = service_price;;
                                        count_subscription = 1;
                                    }
                                } else {
                                    char start_date[20] = "";
                                    char end_date[20] = "";

                                    if (compare_dates(sub_activation_start, date_from, 2)) {
                                        strcpy(start_date, date_from);
                                    } else {
                                        strcpy(start_date, sub_activation_start);
                                    }

                                    // till which day used?
                                    if (strlen(sub_activation_end) == 0 || compare_dates(sub_activation_end, date_till, 1)) {
                                        strcpy(end_date, date_till);
                                    } else {
                                        strcpy(end_date, sub_activation_end);
                                    }

                                    subscriptions_price = service_price * months_between(start_date, end_date);
                                    count_subscription = 1;
                                }
                            }

                            // periodic fee
                            if (strcmp(service_type, "periodic_fee") == 0) {

                                mor_log("Calculating periodic fee\n");

                                char start_date[20] = "";
                                char end_date[20] = "";
                                int days_used = 0;

                                count_subscription = 1;

                                // from which day used?
                                if (compare_dates(sub_activation_start, date_from, 2)) {
                                    strcpy(start_date, date_from);
                                } else {
                                    strcpy(start_date, sub_activation_start);
                                }

                                // till which day used?
                                if (strlen(sub_activation_end) == 0 || compare_dates(sub_activation_end, date_till, 1)) {
                                    strcpy(end_date, date_till);
                                } else {
                                    strcpy(end_date, sub_activation_end);
                                }

                                days_used = days_between(start_date, end_date);

                                if (strcmp(period_type, "day") == 0) {
                                    subscriptions_price = service_price * (days_used + 1);
                                } else if (strcmp(period_type, "month") == 0) {

                                    if (strncmp(date_from, date_till, 7) == 0) {
                                        int total_days = get_last_datetime_of_month(start_date, NULL, 1);
                                        subscriptions_price = service_price / total_days * (days_used + 1);
                                    } else {
                                        subscriptions_price = 0;

                                        if (months_between(start_date, end_date) > 1) {
                                            // jei daugiau nei 1 menuo. Tarpe yra sveiku menesiu kuriem nereikia papildomai skaiciuoti intervalu
                                            subscriptions_price += (months_between(start_date, end_date) - 1) * service_price;
                                        }

                                        // suskaiciuojam pirmo menesio pabaigos ir antro menesio pradzios datas
                                        char last_day_of_month[20] = "";
                                        int last_day_of_month_day = get_last_datetime_of_month(start_date, last_day_of_month, 1);
                                        int last_day_of_month2_day = get_last_datetime_of_month(end_date, NULL, 1);

                                        if (get_day(start_date) - get_day(end_date) == 1) {
                                            subscriptions_price += service_price;
                                        } else {
                                            subscriptions_price += service_price / last_day_of_month_day * (days_between(start_date, last_day_of_month) + 1);
                                            subscriptions_price += service_price / last_day_of_month2_day * (get_day(end_date));
                                        }
                                    }

                                }
                            }

                        }
                    }
                }

                mysql_free_result(result_service);

                if (count_subscription) {

                    invoice_details = realloc(invoice_details, (invoice_details_count + 1) * sizeof(invoice_details_t));
                    memset(&invoice_details[invoice_details_count], 0, sizeof(invoice_details_t));

                    invoice_details[invoice_details_count].price = subscriptions_price;
                    invoice_details[invoice_details_count].price_with_tax = subscriptions_price;
                    invoice_details[invoice_details_count].user_id = users[index].id;
                    if (row[4]) {
                        strcpy(invoice_details[invoice_details_count].service, row[4]);
                    }
                    invoice_details[invoice_details_count].invdet_type = 1;

                    mor_apply_taxes(&invoice_details[invoice_details_count].price_with_tax, users[index].tax_compound, users[index].tax1,
                        users[index].tax2, users[index].tax3, users[index].tax4, users[index].tax1_value, users[index].tax2_value, users[index].tax3_value,
                        users[index].tax4_value);

                    invoice_details[invoice_details_count].price = invoice_details[invoice_details_count].price / users[index].exchange_rate;
                    invoice_details[invoice_details_count].price_with_tax = invoice_details[invoice_details_count].price_with_tax / users[index].exchange_rate;

                    mor_log("Subscription: %s, price: %f, prixe with tax: %f\n", invoice_details[invoice_details_count].service,
                        invoice_details[invoice_details_count].price, invoice_details[invoice_details_count].price_with_tax);

                    *total_price += invoice_details[invoice_details_count].price;
                    *total_price_with_tax += invoice_details[invoice_details_count].price_with_tax;
                    invoice_details[invoice_details_count].units = 1;

                    invoice_details_count++;

                }

            }
        } else {
            mor_log("Subscription data not found in this invoice period\n");
        }
    } else {
        mor_log("Subscription data not found in this invoice period\n");
    }

    mysql_free_result(result);

    return 0;

}


/*
    Get did owner or incoming price for users
*/


int calculate_did_price(int index, double *total_price, double *total_price_with_tax, int owner) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = "";
    char time_periods_sql[2048] = "";
    int variation = 12;

    if (owner == 0) {
        variation = 13;
    }

    get_time_periods_sql(users[index].server_period_start, users[index].server_period_end, time_periods_sql);
    if (!strlen(time_periods_sql)) {
        mor_log("Time_periods_sql is empty. Skipping this user!\n");
        users[index].skip = 1;
        return 1;
    }

    // get aggregates calls by prefix
    sprintf(query, "SELECT SUM(user_billed), SUM(user_billed_with_tax), SUM(user_billed_billsec), SUM(answered_calls) "
        "FROM aggregates "
        "JOIN time_periods ON time_periods.id = aggregates.time_period_id "
        "LEFT JOIN daily_currencies ON daily_currencies.added = SUBSTR(time_periods.from_date, 1, 10) "
        "WHERE variation = %d AND (%s) AND user_id = %d AND user_billed > 0 "
        "GROUP BY user_id",
        variation, time_periods_sql, users[index].id);

    // send query
    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                invoice_details = realloc(invoice_details, (invoice_details_count + 1) * sizeof(invoice_details_t));
                memset(&invoice_details[invoice_details_count], 0, sizeof(invoice_details_t));

                if (row[0]) invoice_details[invoice_details_count].price = atof(row[0]);
                if (row[1]) invoice_details[invoice_details_count].price_with_tax = atof(row[1]);
                if (row[2]) invoice_details[invoice_details_count].billsec = atoi(row[2]);
                if (row[3]) invoice_details[invoice_details_count].units = atoi(row[3]);
                invoice_details[invoice_details_count].user_id = users[index].id;
                if (owner) {
                    strcpy(invoice_details[invoice_details_count].service, "DID Owner Cost");
                } else {
                    strcpy(invoice_details[invoice_details_count].service, "Calls to DIDs");
                }

                invoice_details[invoice_details_count].price = invoice_details[invoice_details_count].price / users[index].exchange_rate;
                invoice_details[invoice_details_count].price_with_tax = invoice_details[invoice_details_count].price_with_tax / users[index].exchange_rate;

                mor_log("Price: %f, price_with_tax: %f, total calls: %d, total billsec: %d\n",
                    invoice_details[invoice_details_count].price, invoice_details[invoice_details_count].price_with_tax,
                    invoice_details[invoice_details_count].units, invoice_details[invoice_details_count].billsec);

                *total_price += invoice_details[invoice_details_count].price;
                *total_price_with_tax += invoice_details[invoice_details_count].price_with_tax;

                invoice_details_count++;

            }
        } else {
            mor_log("Calls data not found in this invoice period\n");
        }
    } else {
        mor_log("Calls data not found in this invoice period\n");
    }

    mysql_free_result(result);

    return 0;

}


/*
    Function that handles segmentation fault and regular returns
*/


void error_handle() {

    static int marked = 0;

    if (marked == 0) {
        if (task_failed && task_id) {
            mor_task_unlock(4); // mark task as failed
        }
        marked = 1;
    }

    exit(1);

}


/*
    Get web_dir and web_url from conf file
*/


int get_web_config() {

    FILE *file;
    char var[256] = "";
    char val[256] = "";

    mor_log("Parsing web url and web dir variables\n");

    file = fopen(GUICONFPATH, "r");

    if (!file) {
        mor_log("Cannot read configuration variables from: " GUICONFPATH "\n");
        return 1;
    }

    // read values from conf file
    while (fscanf(file, "%s = %s", var, val) != EOF) {

        if (!strcmp(var, "Web_Dir")) {
            strcpy(web_dir, val + 1);
        }
        if (!strcmp(var, "Web_URL")) {
            strcpy(web_url, val + 1);
        }

    }

    // Web_Dir can be written in two forms:
    //
    // Web_Dir = Rails.env.to_s == 'production' ? "/billing" : ''
    // or
    // Web_Dir = "/billing"
    //
    // we should check which is it and then parse properly

    if (strlen(web_dir) && strcmp(web_dir, "ails.env.to_s") == 0) {

        FILE *fp;
        char new_line[256] = "";
        char *line = NULL;
        size_t len = 0;
        ssize_t read;
        char *ptr_start = NULL;
        char *ptr_end = NULL;

        fp = fopen(GUICONFPATH, "r");

        if (!fp) {
            mor_log("Cannot read configuration variables from: " GUICONFPATH "\n");
            return 1;
        }

        while (( read = getline(&line, &len, fp)) != -1) {

            if (strstr(line, "Web_Dir =")) {

                strcpy(new_line, line);
                ptr_start = strstr(new_line, "?");
                ptr_end = strstr(new_line, ":");

                if (ptr_start && ptr_end && strlen(ptr_start) && strlen(ptr_end)) {
                    *(ptr_end - 1) = '\0';
                    strcpy(web_dir, ptr_start + 3);
                }

                break;
            }

        }

        if (line) {
            free(line);
            line = NULL;
        }

        fclose(fp);

    }

    // remove quotes
    if (strlen(web_dir) && strlen(web_url)) {
        web_url[strlen(web_url) - 1] = 0;
        web_dir[strlen(web_dir) - 1] = 0;
        mor_log("Web dir: %s, web url: %s\n", web_dir, web_url);
    } else {
        mor_log("Failed to parse web_dir (%s) or web_url (%s)\n", web_dir, web_url);
        return 1;
    }

    fclose(file);
    return 0;

}


/*
    Get invoices by date and user type to recalculate
*/


int get_recalculate_invoices() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = "";
    char users_sql[512] = "";

    if (strcmp(user_type, "user") == 0) {
        sprintf(users_sql, "users.id = %d", user_id);
    } else if (strcmp(user_type, "prepaid") == 0) {
        sprintf(users_sql, "users.postpaid = 0");
    } else if (strcmp(user_type, "postpaid") == 0) {
        sprintf(users_sql, "users.postpaid = 1");
    } else {
        mor_log("Unknown user type\n");
        exit(1);
    }

    sprintf(query, "SELECT invoices.id, user_id, number, invoice_currency, period_start, period_end, issue_date "
        "FROM invoices "
        "JOIN users ON users.id = invoices.user_id "
        "WHERE period_start >= '%s' AND period_end <= '%s' AND users.owner_id = %d AND %s", date_from_date_only, date_till_date_only, owner_id, users_sql);

    // send query
    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {

                recalculate_invoices = realloc(recalculate_invoices, (recalculate_invoices_count + 1) * sizeof(invoices_t));
                memset(&recalculate_invoices[recalculate_invoices_count], 0, sizeof(invoices_t));

                if (row[0]) recalculate_invoices[recalculate_invoices_count].id = atoll(row[0]);
                if (row[1]) recalculate_invoices[recalculate_invoices_count].user_id = atoi(row[1]);
                if (row[2]) strcpy(recalculate_invoices[recalculate_invoices_count].invoice_number, row[2]);
                if (row[3]) strcpy(recalculate_invoices[recalculate_invoices_count].invoice_currency, row[3]);
                if (row[4]) strcpy(recalculate_invoices[recalculate_invoices_count].date_from, row[4]);
                if (row[5]) strcpy(recalculate_invoices[recalculate_invoices_count].date_till, row[5]);
                if (row[6]) strcpy(recalculate_invoices[recalculate_invoices_count].issue_date, row[6]);

                recalculate_invoices_count++;

            }
        } else {
            mor_log("Invoices not found!\n");
            exit(1);
        }
    } else {
        mor_log("Invoices not found!\n");
        exit(1);
    }

    mysql_free_result(result);
    return 0;

}


/*
    Delete old invoice details by invoice id
*/


int delete_invoicedetails(long long int invoice_id) {

    char query[2048] = "";

    mor_log("Deleting old invoice details for invoice_id = %lld\n", invoice_id);
    sprintf(query, "DELETE FROM invoicedetails WHERE invoice_id = %lld", invoice_id);

    if (mor_mysql_query(query)) {
        exit(1);
    }

    return 0;

}


/*
    Get exchange rate by currency name
*/


double get_exchange_rate(char *currency) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[2048] = "";
    double exchange_rate = 0;

    sprintf(query, "SELECT exchange_rate FROM currencies WHERE name = '%s' LIMIT 1", currency);

    // send query
    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {
                if (row[0]) {
                    exchange_rate = atof(row[0]);
                    mor_log("Exchange rate for currency %s is %f\n", currency, exchange_rate);
                }
            }
        }
    }

    mysql_free_result(result);

    return exchange_rate;

}
