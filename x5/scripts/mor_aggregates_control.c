// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script checks if there are missing aggregate data


#define SCRIPT_VERSION              "1.11"
#define SCRIPT_NAME                 "mor_aggregates_control"
#define MAX_CALLS_PER_HOUR          10000
#define AGGREGATES_CONTROL_SCRIPT   1

#include "crc64.c"
#include "mor_functions.c"
#include "mor_aggregates.h"
#include "mor_aggregates_functions.c"

int mor_get_calls_data(int time_period_index, char *calldate);
int mor_get_missing_periods();
int mor_check_if_time_periods_exist();
int get_oldest_calldate();
int get_oldest_time_period();
void aggregate();

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    int i = 0, j = 0;

    // starting sript
    mor_init("Starting MOR X5 Aggregates Control script\n");

    if (argc == 2) {
        strncpy(aggregate_till, argv[1], 19);
        mor_log("Calls will be aggregated till: %s\n", aggregate_till);
    } else {
        char value[64] = "";
        if (mor_get_variable("aggregate_days", value)) {
            exit(1);
        }
        if (strlen(value) == 0) {
            mor_log("All calls will be aggregated\n");
        } else {
            struct tm tmm;
            time_t timestamp, new_timestamp;
            timestamp = time(NULL);
            new_timestamp = timestamp - atoi(value)*60*60*24;
            gmtime_r(&new_timestamp, &tmm);
            strftime(aggregate_till, sizeof(aggregate_till), DATE_FORMAT, &tmm);
            mor_log("Calls will be aggregated %s days back (till: %s)\n", value, aggregate_till);
        }
    }

    if (mor_check_if_time_periods_exist()) exit(1);
    if (mor_get_missing_periods()) exit(1);

    // initialize mysql buffers
    memset(insert_update_values_query, 0, INSERT_UPDATE_BUFFER_SIZE);
    sprintf(insert_update_query, INSERT_UPDATE_BEGINNING_SQL);

    if (missing_time_periods_count) {

        for (i = 0; i < missing_time_periods_count; i++) {
            mor_log("Date: %s, Full aggregate: %d, Last calls ID: %" PRIu64 "\n", missing_time_periods[i].date, missing_time_periods[i].full_aggregate, missing_time_periods[i].last_call_id);
        }

        for (i = 0; i < missing_time_periods_count; i++) {

            // insert new time period in 'time_periods' table

            // get period id for this hour
            if ((time_period_hour_id = mor_get_time_period_id(1, missing_time_periods[i].date)) == 0) {
                mor_log("Hour time period id = 0. Aborting\n");
                exit(1);
            }

            // get period id for this day
            if ((time_period_day_id = mor_get_time_period_id(2, missing_time_periods[i].date)) == 0) {
                mor_log("Day time period id = 0. Aborting\n");
                exit(1);
            }

            // get period id for this month
            if ((time_period_month_id = mor_get_time_period_id(3, missing_time_periods[i].date)) == 0) {
                mor_log("Month time period id = 0. Aborting\n");
                exit(1);
            }

            // get calls for current missing period
            if (mor_get_calls_data(i, NULL)) exit(1);
            // if we have calls, aggregate them
            if (calls_data_count) aggregate();
            // mark this period as finished
            mor_mark_finished_time_period(0);

            // check if we should stop aggregate
            if (strlen(aggregate_till) && strncmp(missing_time_periods[i].date, aggregate_till, 13) == 0) {
                mor_log("Calls are aggregates till %s\n", aggregate_till);
                break;
            }

        }

    } else {
        mor_log("No gaps in time periods found. Searching for missing time periods...\n");
    }

    // get dates
    if (get_oldest_calldate()) exit(1);
    if (get_oldest_time_period()) exit(1);

    // handle errors
    if (!strlen(oldest_calldate)) {
        mor_log("Oldest calldate is empty\n");
        exit(1);
    } else {
        mor_log("Oldest calldate: %s\n", oldest_calldate);
    }

    // handle errors
    if (!strlen(oldest_time_period)) {
        mor_log("Oldest time_period is empty\n");
        exit(1);
    } else {
        mor_log("Oldest time_period: %s\n", oldest_time_period);
    }

    // calculate hour diff between oldest calldate and oldest time period

    char time_tmp1[20] = "";
    char time_tmp2[20] = "";
    time_t t1, t2;
    struct tm tmm, tm1, tm2;
    int hour_diff;
    char calculated_date[20] = "";

    // set environment timezone to UTC to avoid daylight saving
    // we can use UTC time zone, because we have two date string and we need to generate dates
    // between those two dates, so we don't care about the actual timezone used
    // calldates will have correct timezones and will get assinged to correct time_periods
    setenv("TZ", "UTC", 1);

    // get time in seconds of the oldest time period
    memset(&tm1, 0, sizeof(struct tm));
    strcpy(time_tmp1, oldest_time_period);
    strcpy(time_tmp1 + 14, "00:00");
    strptime(time_tmp1, DATE_FORMAT, &tm1);
    t1 = mktime(&tm1);

    // get time in seconds of the oldest calldate
    memset(&tm2, 0, sizeof(struct tm));
    strcpy(time_tmp2, oldest_calldate);
    strcpy(time_tmp2 + 14, "00:00");
    strptime(time_tmp2, DATE_FORMAT, &tm2);
    t2 = mktime(&tm2);

    // unset UTC timezone
    unsetenv("TZ");

    // calculate hour diff between oldest time_period and calldate
    hour_diff = ceil((float)(difftime(t1, t2))/60.0/60);

    // only proceed if hour diff is 2 or more (we skip current hour, because aggregate main script should handle courrent hour)
    if (hour_diff < 1) {
        mor_log("Data is aggregated for old calls. Nothing to do...\n");
        exit(1);
    }

    // print some info
    mor_log("Oldest calldate: %s, hour diff: %d\n", oldest_calldate, hour_diff);

    // missing dates loop
    for (j = 0; j < hour_diff; j++) {

        // decrement calculated time (in seconds) by 1 hour
        t1 -= 3600;
        // fill up struct_tm variable
        gmtime_r(&t1, &tmm);
        // format time string
        strftime(calculated_date, sizeof(calculated_date), DATE_FORMAT, &tmm);

        // insert new time period in 'time_periods' table

        // get period id for this hour
        if ((time_period_hour_id = mor_get_time_period_id(1, calculated_date)) == 0) {
            mor_log("Hour time period id = 0. Aborting\n");
            exit(1);
        }

        // get period id for this day
        if ((time_period_day_id = mor_get_time_period_id(2, calculated_date)) == 0) {
            mor_log("Day time period id = 0. Aborting\n");
            exit(1);
        }

        // get period id for this month
        if ((time_period_month_id = mor_get_time_period_id(3, calculated_date)) == 0) {
            mor_log("Month time period id = 0. Aborting\n");
            exit(1);
        }

        // get calls for current missing period
        mor_get_calls_data(-1, calculated_date);
        // if we have calls, aggregate them
        current_aggregates = 0;
        if (calls_data_count) aggregate();
        // mark this period as finished
        mor_mark_finished_time_period();

        // check if we should stop aggregate
        if (strlen(aggregate_till) && strncmp(calculated_date, aggregate_till, 13) == 0) {
            mor_log("Calls are aggregates till %s\n", aggregate_till);
            break;
        }

    }

    // close mysql connection
    mysql_close(&mysql);
    // we will not use mysql, so free other memory used by sql
    mysql_library_end();

    // free memory
    if (calls_data) free(calls_data);
    if (time_periods) free(time_periods);
    if (missing_time_periods) free(missing_time_periods);

    mor_log("Script completed!\n");

    pthread_exit(NULL);

}


/*

    ############  FUNCTIONS #######################################################

*/


/*
    Get calls from database
*/


int mor_get_calls_data(int time_period_index, char *calldate) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char query[2048] = "";
    char get_calls_from[1024] = "";
    char date_from[20] = "";
    char date_till[20] = "";
    char partial_aggregate_sql[512] = "";

    // when slow mode = 1, then get calls not by one hour period, but by 10 minute period
    // and do small pauses between sql
    // many calls in one hour indicate that client has high traffic so we need to slow down aggregate process
    int slow_mode = 0;
    int slow_mode_iteration = 0;

    // if we have calldate, then we need to fetch calls according to this calldate
    // used with SECOND AGGREGATE CONTROL PHASE, when we calculate missing dates between oldest time_period and oldest calldate

    // if we don't have calldate, then we need to check missing_time_periods structure and get date from that variable
    // used with FIRST AGGREGATE CONTROL PHASE, when we calculate missing dates between current time and oldest time_period
    // also, missing_time_periods variable shows if we should aggregate full hour or just a part of missing hour data

    if (calldate != NULL) {

        // make from and till dates equal
        strcpy(date_from, calldate);
        strcpy(date_till, calldate);

        // date from should be xxxx-xx-xx xx:00:00
        // date till should be xxxx-xx-xx xx:59:59
        // then we will get calls only for specific hour
        strcpy(date_from + 14, "00:00");
        strcpy(date_till + 14, "59:59");

    } else {

        // some error handling
        if (time_period_index < 0) {
            mor_log("mor_get_calls_data time_period_index < -1, aborting...\n");
            exit(1);
        }

        // some error handling
        if (&missing_time_periods[time_period_index] == NULL) {
            mor_log("missing_time_periods is NULL, aborting...\n");
            exit(1);
        }

        // make from and till dates equal
        strcpy(date_from, missing_time_periods[time_period_index].date);
        strcpy(date_till, missing_time_periods[time_period_index].date);

        // make from date xxxx-xx-xx xx:00:00 and till date xxxx-xx-xx xx:59:59
        strcpy(date_from + 14, "00:00");
        strcpy(date_till + 14, "59:59");

        // if aggregates is partial, then we need to get call starting from specific id
        if (missing_time_periods[time_period_index].full_aggregate != 1) {
            sprintf(partial_aggregate_sql, " AND calls.id > %" PRIu64, missing_time_periods[time_period_index].last_call_id);
        }

    }

    // check how many calls there are in one hour period
    // if there are more than X, then aggregate in 10 minute batches for this hour

    sprintf(get_calls_from, "calls.calldate BETWEEN '%s' AND '%s'", date_from, date_till);
    sprintf(query, "SELECT COUNT(id) FROM calls WHERE %s", get_calls_from);
    // lock thread because aggregate threads might be running
    pthread_mutex_lock(&mutex);
    if (mor_mysql_query(query)) exit(1);
    result = mysql_store_result(&mysql);
    pthread_mutex_unlock(&mutex);
    row = mysql_fetch_row(result);
    if (row) {
        if (atoi(row[0]) > MAX_CALLS_PER_HOUR) {
            slow_mode = 1;
            mor_log("There are more than %d (%d) calls between %s - %s ! Calls will be aggregated in 10 minute batches\n", MAX_CALLS_PER_HOUR, atoi(row[0]), date_from, date_till);
        }
    }

    // initialize calls
    calls_data = realloc(calls_data, sizeof(calls_data_t));
    memset(calls_data, 0, sizeof(calls_data_t));
    calls_data_count = 0;

    slow_mode_jmp:

    if (slow_mode) {
        if (slow_mode_iteration == 0) {
            strcpy(date_from + 14, "00:00");
            strcpy(date_till + 14, "09:59");
        }
        if (slow_mode_iteration == 1) {
            strcpy(date_from + 14, "10:00");
            strcpy(date_till + 14, "19:59");
        }
        if (slow_mode_iteration == 2) {
            strcpy(date_from + 14, "20:00");
            strcpy(date_till + 14, "29:59");
        }
        if (slow_mode_iteration == 3) {
            strcpy(date_from + 14, "30:00");
            strcpy(date_till + 14, "39:59");
        }
        if (slow_mode_iteration == 4) {
            strcpy(date_from + 14, "40:00");
            strcpy(date_till + 14, "49:59");
        }
        if (slow_mode_iteration == 5) {
            strcpy(date_from + 14, "50:00");
            strcpy(date_till + 14, "59:59");
        }
    }

    mor_log("Reading calls for period: %s - %s\n", date_from, date_till);
    sprintf(get_calls_from, "calls.calldate BETWEEN '%s' AND '%s'", date_from, date_till);

    sprintf(query, "SELECT * FROM (SELECT calls.id AS 'callid', calls.user_id, user_billsec, user_price + did_inc_price, terminator_id, provider_billsec, provider_price + did_prov_price, billsec, real_billsec, hangupcause, calls.prefix, "
                   "destinations.destinationgroup_id, destinationgroups.name, destinations.id, destinations.name as 'dname', calls.uniqueid, activecalls.id AS 'aid', "
                   "IF(taxes.compound_tax is not null, IF(taxes.compound_tax = 1, (((((user_price+did_inc_price)/100*(tax1_value+100))/100*IF(tax2_enabled = 1,tax2_value+100,100))/100*IF(tax3_enabled = 1,tax3_value+100,100))/100*IF(tax4_enabled = 1,tax4_value+100,100)),((user_price+did_inc_price) )/100*(tax1_value+IF(tax2_enabled = 1,tax2_value,0)+IF(tax3_enabled = 1,tax3_value,0)+IF(tax4_enabled = 1,tax4_value,0)+100)),(user_price+did_inc_price)) AS 'price_with_tax', "
                   "src_device.user_id AS 'src_user_id', calls.dst_user_id, destinationgroups.desttype "
                   "FROM calls "
                   "LEFT JOIN providers ON providers.id = calls.provider_id "
                   "LEFT JOIN destinations ON destinations.prefix = calls.prefix "
                   "LEFT JOIN destinationgroups ON destinations.destinationgroup_id = destinationgroups.id "
                   "LEFT JOIN activecalls ON calls.uniqueid = activecalls.uniqueid "
                   "LEFT JOIN users ON users.id = calls.user_id "
                   "LEFT JOIN taxes ON taxes.id = users.tax_id "
                   "LEFT JOIN devices AS src_device ON src_device.id = calls.src_device_id "
                   "WHERE %s%s) AS A ORDER BY A.uniqueid, A.callid DESC", get_calls_from, partial_aggregate_sql);

    // lock thread because aggregate threads might be running
    pthread_mutex_lock(&mutex);

    if (mor_mysql_query(query)) {
        exit(1);
    }

    // get results
    result = mysql_store_result(&mysql);
    pthread_mutex_unlock(&mutex);

    // we will check current calls.uniqueid with this variable and if it changes, then it mean we have another user calls (user's call is explained below)
    char last_uid[64] = "";
    // for profiling current calls count
    current_calls = 0;

    // fill this node
    while ((row = mysql_fetch_row(result)) != NULL) {

        int src_user_aggregate = 0;
        int dst_user_aggregate = 0;
        int src_user_aggregated = 0;
        int dst_user_aggregated = 0;

        // get primary user
        int user_id = 0;
        if (row[1]) user_id = atoi(row[1]); else user_id  = 0;

        src_user_aggregate_label:
        dst_user_aggregate_label:

        if (src_user_aggregate) {
            src_user_aggregated = 1;
        }

        if (dst_user_aggregate) {
            dst_user_aggregated = 1;
        }

        calls_data = realloc(calls_data, (calls_data_count + 1) * sizeof(calls_data_t));
        memset(&calls_data[calls_data_count], 0, sizeof(calls_data_t));

        if (row[0]) calls_data[calls_data_count].id = atoll(row[0]); else calls_data[calls_data_count].id = 0;
        if (row[1]) calls_data[calls_data_count].user_id = atoi(row[1]); else calls_data[calls_data_count].user_id  = 0;
        if (row[2]) calls_data[calls_data_count].user_billsec = atol(row[2]); else calls_data[calls_data_count].user_billsec = 0;
        if (row[3]) calls_data[calls_data_count].user_price = atof(row[3]); else calls_data[calls_data_count].user_price = 0;
        if (row[4]) calls_data[calls_data_count].terminator_id = atoi(row[4]); else calls_data[calls_data_count].terminator_id = 0;
        if (row[5]) calls_data[calls_data_count].terminator_billsec = atol(row[5]); else calls_data[calls_data_count].terminator_billsec = 0;
        if (row[6]) calls_data[calls_data_count].terminator_price = atof(row[6]); else calls_data[calls_data_count].terminator_price = 0;
        if (row[7]) calls_data[calls_data_count].billsec = atol(row[7]); else calls_data[calls_data_count].billsec = 0;
        if (row[8]) calls_data[calls_data_count].real_billsec = atof(row[8]); else calls_data[calls_data_count].real_billsec = 0;
        if (row[9] && (atoi(row[9]) == 16)) calls_data[calls_data_count].answered = 1; else calls_data[calls_data_count].answered = 0;
        if (row[10]) strcpy(calls_data[calls_data_count].prefix, row[10]); else strcpy(calls_data[calls_data_count].prefix, "");
        if (row[11]) calls_data[calls_data_count].direction_id = atoi(row[11]); else calls_data[calls_data_count].direction_id = 0;
        if (row[12]) strcpy(calls_data[calls_data_count].direction_name, row[12]); else strcpy(calls_data[calls_data_count].direction_name, "");
        if (row[13]) calls_data[calls_data_count].destination_id = atoi(row[13]); else calls_data[calls_data_count].destination_id = 0;
        if (row[14]) strcpy(calls_data[calls_data_count].destination, row[14]); else strcpy(calls_data[calls_data_count].destination, "");
        if (row[15]) strcpy(calls_data[calls_data_count].uniqueid, row[15]); else strcpy(calls_data[calls_data_count].uniqueid, "");
        if (row[16]) calls_data[calls_data_count].activecalls = 1; else calls_data[calls_data_count].activecalls = 0;
        if (row[17]) calls_data[calls_data_count].user_price_with_tax = atof(row[17]); else calls_data[calls_data_count].user_price_with_tax = 0;
        if (row[18]) calls_data[calls_data_count].src_user_id = atoi(row[18]); else calls_data[calls_data_count].src_user_id = 0;
        if (row[19]) calls_data[calls_data_count].dst_user_id = atoi(row[19]); else calls_data[calls_data_count].dst_user_id = 0;

        if (src_user_aggregate) calls_data[calls_data_count].user_id = calls_data[calls_data_count].src_user_id;
        if (dst_user_aggregate) calls_data[calls_data_count].user_id = calls_data[calls_data_count].dst_user_id;
        if (row[20]) strcpy(calls_data[calls_data_count].desttype, row[20]); else strcpy(calls_data[calls_data_count].desttype, "");

        calls_data[calls_data_count].time_period_hour_id = time_period_hour_id;
        calls_data[calls_data_count].time_period_day_id = time_period_day_id;
        calls_data[calls_data_count].time_period_month_id = time_period_month_id;

        // sometimes names have ' symbol and this brakes mysql querys like this: 'this is some string's example', so we need to escape like this: 'this is some string\'s example'
        mor_escape_string(calls_data[calls_data_count].destination, '\'');
        mor_escape_string(calls_data[calls_data_count].direction_name, '\'');

        // user call is the last attempt
        // for example if user calls though 4 providers (3 failed and 1 succeeded), then only the last call is considered as user's call
        // all these 4 calls will have the same uniqueid, but different cdrs
        // because calls are ordered by uniqueid and id, last call with the same uniqueid will be user's call
        // so we are checking current and last uniqueid, if they change, it means last uniqueid was 'the last of all the same uniqueids' and this is our 'users call'
        calls_data[calls_data_count].user_call = 0;
        if (strcmp(last_uid, calls_data[calls_data_count].uniqueid) != 0) {
            if (calls_data_count) {
                if (!calls_data[calls_data_count - 1].activecalls) {
                    calls_data[calls_data_count - 1].user_call = 1;
                }
            }
        }

        // save last uniqueid
        strcpy(last_uid, calls_data[calls_data_count].uniqueid);

        calls_data_count++;
        current_calls++;

        if (src_user_aggregated != 1 && calls_data[calls_data_count - 1].src_user_id > 0 && calls_data[calls_data_count - 1].src_user_id != user_id) {
            src_user_aggregate = 1;
            goto src_user_aggregate_label;
        } else {
            src_user_aggregate = 0;
        }

        if (dst_user_aggregated != 1 && calls_data[calls_data_count - 1].dst_user_id > 0 && calls_data[calls_data_count - 1].dst_user_id != user_id) {
            dst_user_aggregate = 1;
            goto dst_user_aggregate_label;
        } else {
            dst_user_aggregate = 0;
        }

    }

    // don't forget to mark last call as 'user call'
    if (calls_data_count) {
        if (!calls_data[calls_data_count - 1].activecalls) calls_data[calls_data_count - 1].user_call = 1;
    }

    mysql_free_result(result);

    if (slow_mode) {
        slow_mode_iteration++;
        if (slow_mode_iteration <= 5) {
            sleep(2);
            goto slow_mode_jmp;
        }
    }

    return 0;

}


/*
    Check if atleast one time period exists, if not, then exit this script
*/


int mor_check_if_time_periods_exist() {

    MYSQL_RES *result;
    MYSQL_ROW row;
    uint64_t time_periods_count = 0;

    // get cout of time periods
    if (mor_mysql_query("SELECT count(id) FROM time_periods")) {
        return 1;
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) time_periods_count = atoll(row[0]);
        }
    }

    mysql_free_result(result);

    // if count is zero, aggregate script was not started
    // so we don't need to aggregate missing data
    if (time_periods_count == 0) {
        mor_log("Time periods count is zero\n");
        return 1;
    } else {
        return 0;
    }

}


/*
    Compare string dates
*/


int comp_by_date(const void * elem1, const void * elem2) {

    time_periods_t *f = (time_periods_t *)elem1;
    time_periods_t *s = (time_periods_t *)elem2;

    time_t t1, t2;
    struct tm tm1, tm2;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(f->date, DATE_FORMAT, &tm1);
    strptime(s->date, DATE_FORMAT, &tm2);

    t1 = mktime(&tm1);
    t2 = mktime(&tm2);

    if (t1 > t2) return  1;
    if (t1 < t2) return -1;
    return 0;

}


/*
    Get missing dates between oldest time_period and current date
*/


int mor_get_missing_periods() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int hour_diff = 0;
    char query[512] = "";

    char current_time[20] = "";
    time_t t_current;
    struct tm tm_current;
    t_current = time(NULL);
    localtime_r(&t_current, &tm_current);
    // format current time string
    strftime(current_time, sizeof(current_time), DATE_FORMAT, &tm_current);
    strcpy(current_time + 14, "00:00");

    // get all dates older than current date
    sprintf(query, "SELECT from_date, last_call_id FROM time_periods WHERE period_type = 'hour' AND from_date < '%s' AND from_date > '0000-00-00 00:00:00'", current_time);

    // get cout of time periods
    if (mor_mysql_query(query)) {
        return 1;
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            while (( row = mysql_fetch_row(result) )) {
                if (row[0]) {
                    time_periods = realloc(time_periods, (time_periods_count + 1) * sizeof(time_periods_t));
                    memset(&time_periods[time_periods_count], 0, sizeof(time_periods_t));
                    if (row[0]) strcpy(time_periods[time_periods_count].date, row[0]);
                    if (row[1]) time_periods[time_periods_count].last_call_id = atoll(row[1]);
                    time_periods_count++;
                }
            }
        }
    }

    mysql_free_result(result);

    // sort by date
    if (time_periods_count) {

        char time_tmp[20] = "";

        qsort(time_periods, time_periods_count, sizeof(time_periods_t), comp_by_date);

        // find gaps between time periods

        // first we get current hour
        time_t t1, t2;
        struct tm tm1, tm2;
        t1 = time(NULL);
        localtime_r(&t1, &tm1);
        tm1.tm_min = 0;
        tm1.tm_sec = 0;
        t1 = mktime(&tm1);

        // calculate hour diff between current hour and oldest time period
        // get time in seconds of the oldest time period
        memset(&tm2, 0, sizeof(struct tm));
        strcpy(time_tmp, time_periods[0].date);
        strcpy(time_tmp + 14, "00:00");
        strptime(time_tmp, DATE_FORMAT, &tm2);
        t2 = mktime(&tm2);

        // check for error
        if (t1 < t2) {
            mor_log("Current date is older than last period date! Aborting\n");
            return 1;
        }

        // get hour difference between current hour and oldest time period
        hour_diff = ceil((float)(difftime(t1, t2))/60.0/60);

        mor_log("Oldest period: %s, hour diff: %d\n", time_tmp, hour_diff);

        // check if difference is atleast 1 hour
        if (hour_diff < 1) return 0;

        // aggregate max 2 years back
        if (hour_diff > 17520) {
            hour_diff = 17520;
        }

        int last_tm_hour = -1;
        char calculated_date[20] = "";
        int i, j = 0, k;
        int status = 0; // shows if period needs to be aggregated (0 - don't need, 1 - full aggregate, 2 - partial aggregate)

        // calculate date every date starting from current hour
        // and check if that date exists in time periods table
        // also check that data is aggregated for that period
        for (i = 0; i < hour_diff; i++) {

            // decrement by hour
            t1 -= 3600;
            // calculate time
            localtime_r(&t1, &tm1);
            // format time string
            strftime(calculated_date, sizeof(calculated_date), DATE_FORMAT, &tm1);

            // in case of daylight saving
            // we need to skip this hour, because it was adjusted backward
            if (tm1.tm_hour == last_tm_hour) {
                mor_log("Skipped date: %s\n", calculated_date);
                continue;
            }

            // i don't think we need to handle daylight saving adjustment forward

            // save current hour for later comparison
            last_tm_hour = tm1.tm_hour;

            // set minutes and second to 59:59
            // because this will help us check if time period was fully aggregated for that hour
            // if from_date = xxxx-xx-xx xx:59:59, then it mean data was fully aggregated for that hour
            // otherwise, minutes and seconds show when aggregate stopped in that hour
            strcpy(calculated_date + 14, "59:59");

            // check if dates matches
            int match = 0;
            for (j = 0; j < time_periods_count; j++) {
                match = 1;
                for (k = 0; k < 13; k++) {
                    if (calculated_date[k] != time_periods[j].date[k]) match = 0;
                }
                if (match) break;
            }

            // reset variable
            status = 0;

            // if date matches, we have aggregated data for this hour
            // we need to check if it was fully aggregated
            if (match) {
                if (strcmp(calculated_date + 13, time_periods[time_periods_count - j - 1].date + 13)) {
                    // mark for partial aggregate
                    status = 2;
                }
            } else {
                // mark for full aggregate
                status = 1;
            }

            // if status, then periods is missing (either partially or fully)
            if (status) {
                missing_time_periods = realloc(missing_time_periods, (missing_time_periods_count + 1) * sizeof(time_periods_t));
                memset(&missing_time_periods[missing_time_periods_count], 0, sizeof(time_periods_t));
                if (status == 1) {
                    strcpy(missing_time_periods[missing_time_periods_count].date, calculated_date);
                    missing_time_periods[missing_time_periods_count].full_aggregate = 1;
                } else {
                    strcpy(missing_time_periods[missing_time_periods_count].date, time_periods[time_periods_count - j - 1].date);
                    missing_time_periods[missing_time_periods_count].last_call_id = time_periods[time_periods_count - j - 1].last_call_id;
                }
                missing_time_periods_count++;
            }

        }

    }

    return 0;

}

int get_oldest_calldate() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // get oldest calldate in case aggregate script started after some calls where made
    if (mor_mysql_query("SELECT MIN(calldate) FROM calls WHERE calldate > '0000-00-00 00:00:00'")) {
        return 1;
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) strcpy(oldest_calldate, row[0]);
        }
    }

    mysql_free_result(result);

    return 0;

}

int get_oldest_time_period() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    // get oldest time period
    if (mor_mysql_query("SELECT MIN(from_date) FROM time_periods WHERE period_type = 'hour' AND from_date > '0000-00-00 00:00:00'")) {
        return 1;
    }

    // get results
    result = mysql_store_result(&mysql);
    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) strcpy(oldest_time_period, row[0]);
        }
    }

    mysql_free_result(result);

    return 0;

}

void aggregate() {

    int i;

    pthread_attr_t tattr;
    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_JOINABLE);

    // we don't care about thread id, so all threads will be initialized to this thread id
    // every aggregate variation will be done in a thread
    pthread_t thread[VARIATIONS];

    // i = 1   aggregate by originator
    // i = 2   aggregate by terminator
    // i = 3   aggregate by direction
    // i = 4   aggregate by originator and terminator
    // i = 5   aggregate by originator and direction
    // i = 6   aggregate by terminator and direction
    // i = 7   aggregate by direction and destination
    // i = 8   aggregate by originator and terminator and direction
    // i = 9   aggregate by originator and direction and destination
    // i = 10  aggregate by terminator and direction and destination
    // i = 11  aggregate by originator and terminator and direction and destination (all)

    for (i = 1; i <= VARIATIONS; i++) {

        // calculation will be done by multiple cores
        thread_args_t *targs_originator = malloc(sizeof(thread_args_t));
        targs_originator->calls = malloc(calls_data_count * sizeof(calls_data_t));
        targs_originator->count = calls_data_count;
        targs_originator->type = i;
        memcpy(targs_originator->calls, calls_data, calls_data_count * sizeof(calls_data_t));
        pthread_create(&thread[i - 1], &tattr, mor_aggregate, (void *)targs_originator);

    }

    // wait for threads to finish their work
    for (i = 0; i < VARIATIONS; i++) {
        pthread_join(thread[i], NULL);
    }

    // lock thread because other aggregate threads might be running
    pthread_mutex_lock(&mutex);
    mor_update_aggregated_data();
    batch_count = 0;
    pthread_mutex_unlock(&mutex);

}
