
/*
    Sorting functions
*/


int comp_by_originator(const void * elem1, const void * elem2) {
    calls_data_t *f = (calls_data_t *)elem1;
    calls_data_t *s = (calls_data_t *)elem2;
    if (f->user_id > s->user_id) return  1;
    if (f->user_id < s->user_id) return -1;
    return 0;
}

int comp_by_terminator(const void * elem1, const void * elem2) {
    calls_data_t *f = (calls_data_t *)elem1;
    calls_data_t *s = (calls_data_t *)elem2;
    if (f->terminator_id > s->terminator_id) return  1;
    if (f->terminator_id < s->terminator_id) return -1;
    return 0;
}

int comp_by_direction(const void * elem1, const void * elem2) {
    calls_data_t *f = (calls_data_t *)elem1;
    calls_data_t *s = (calls_data_t *)elem2;
    if (f->direction_id > s->direction_id) return  1;
    if (f->direction_id < s->direction_id) return -1;
    return 0;
}

int comp_by_destination(const void * elem1, const void * elem2) {
    calls_data_t *f = (calls_data_t *)elem1;
    calls_data_t *s = (calls_data_t *)elem2;
    if (f->destination_id > s->destination_id) return  1;
    if (f->destination_id < s->destination_id) return -1;
    return 0;
}

int comp_by_time_period_id(const void * elem1, const void * elem2) {
    calls_data_t *f = (calls_data_t *)elem1;
    calls_data_t *s = (calls_data_t *)elem2;
    if (f->time_period_hour_id > s->time_period_hour_id) return  1;
    if (f->time_period_hour_id < s->time_period_hour_id) return -1;
    return 0;
}


/*
    Group and aggregate calls
*/


void *mor_aggregate(void *args) {

    // thread args
    thread_args_t *arg = (thread_args_t *)args;
    int calls_data_count = arg->count;
    calls_data_t *calls = (calls_data_t *)arg->calls;
    int type = arg->type;

    // aggregate variables
    double user_price = 0, user_price_tax = 0, terminator_price = 0, real_billsec = 0;
    int i, count = 0, user_count = 0, user_id = -2, terminator_id = -2, direction_id = -2, destination_id = -2, answered = 0;
    long int billsec = 0, user_billsec = 0, terminator_billsec = 0;
    char prefix[128] = "";
    char direction[256] = "";
    char destination[256] = "";
    int got_data = 0;
    uint64_t tphid = 0;
    uint64_t tpdid = 0;
    uint64_t tpmid = 0;

    // sort by time period id
    qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_time_period_id);

    // SORTING BASED ON VARIATION

    if (type == 1) qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    if (type == 2) qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
    if (type == 3) qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
    if (type == 4) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    }
    if (type == 5) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    }
    if (type == 6) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
    }
    if (type == 7) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_destination);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
    }
    if (type == 8) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    }
    if (type == 9) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_destination);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    }
    if (type == 10) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_destination);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
    }
    if (type == 11) {
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_destination);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_direction);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_terminator);
        qsort(calls, calls_data_count, sizeof(calls_data_t), comp_by_originator);
    }

    // GROUPING BASED ON VARIATION

    for (i = 0; i < calls_data_count; i++) {

        got_data = 0;

        // AGGREGATE BY ORIGINATOR
        if (type == 1) {
            if (!(calls[i].user_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY TERMINATOR
        if (type == 2) {
            if (!(calls[i].terminator_id > 0)) goto skip;
            if ((terminator_id != calls[i].terminator_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY DIRECTION
        if (type == 3) {
            if (!(calls[i].direction_id > 0)) goto skip;
            if ((direction_id != calls[i].direction_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY ORIGINATOR AND TERMINATOR
        if (type == 4) {
            if (!(calls[i].user_id > 0) || !(calls[i].terminator_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || terminator_id != calls[i].terminator_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY ORIGINATOR AND DIRECTION
        if (type == 5) {
            if (!(calls[i].user_id > 0) || !(calls[i].direction_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || direction_id != calls[i].direction_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY TERMINATOR AND DIRECTION
        if (type == 6) {
            if (!(calls[i].terminator_id > 0) || !(calls[i].direction_id > 0)) goto skip;
            if ((terminator_id != calls[i].terminator_id || direction_id != calls[i].direction_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY DIRECTION AND DESTINATION
        if (type == 7) {
            if (!(calls[i].direction_id > 0) || !(calls[i].destination_id > 0)) goto skip;
            if ((direction_id != calls[i].direction_id || destination_id != calls[i].destination_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY ORIGINATOR AND TERMINATOR AND DIRECTION
        if (type == 8) {
            if (!(calls[i].user_id > 0) || !(calls[i].terminator_id > 0) || !(calls[i].direction_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || terminator_id != calls[i].terminator_id || direction_id != calls[i].direction_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY ORIGINATOR AND DIRECTION AND DESTINATION
        if (type == 9) {
            if (!(calls[i].user_id > 0) || !(calls[i].direction_id > 0) || !(calls[i].destination_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || direction_id != calls[i].direction_id || destination_id != calls[i].destination_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY TERMINATOR AND DIRECTION AND DESTINATION
        if (type == 10) {
            if (!(calls[i].terminator_id > 0) || !(calls[i].direction_id > 0) || !(calls[i].destination_id > 0)) goto skip;
            if ((terminator_id != calls[i].terminator_id || direction_id != calls[i].direction_id || destination_id != calls[i].destination_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // AGGREGATE BY ORIGINATOR AND TERMINATOR AND DIRECTION AND DESTINATION
        if (type == 11) {
            if (!(calls[i].user_id > 0) || !(calls[i].terminator_id > 0) || !(calls[i].direction_id > 0) || !(calls[i].destination_id > 0)) goto skip;
            if ((user_id != calls[i].user_id || terminator_id != calls[i].terminator_id || direction_id != calls[i].direction_id || destination_id != calls[i].destination_id || tphid != calls[i].time_period_hour_id) && count) got_data = 1;
        }

        // UPDATE AGGREGATED DATA
        if (got_data) {
            mor_aggregate_sql_format(user_id, user_price, user_billsec, terminator_id, terminator_price, terminator_billsec, billsec, real_billsec, answered, prefix, direction, direction_id, destination, count, user_count, type, tphid, tpdid, tpmid, user_price_tax);
            user_price = user_price_tax = terminator_price = user_billsec = terminator_billsec = billsec = real_billsec = count = user_count = answered = 0;
        }

        tphid = calls[i].time_period_hour_id;
        tpdid = calls[i].time_period_day_id;
        tpmid = calls[i].time_period_month_id;

        count++;
        if (calls[i].user_call) user_count++;
        if (calls[i].answered) {
            answered++;
            user_price += calls[i].user_price;
            user_price_tax += calls[i].user_price_with_tax;
            user_billsec += calls[i].user_billsec;
            terminator_billsec += calls[i].terminator_billsec;
            terminator_price += calls[i].terminator_price;
            billsec += calls[i].billsec;
            real_billsec += calls[i].real_billsec;
        }

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
        // i = 11  aggregate by originator and terminator and direction and destination

        if (type == 1 || type == 4 || type == 5 || type == 8 || type == 9 || type == 11) user_id = calls[i].user_id;
        if (type == 2 || type == 4 || type == 6 || type == 8 || type == 10 || type == 11) terminator_id = calls[i].terminator_id;
        if (type == 3 || type == 5 || type == 6 || type == 7 || type == 8 || type == 9 || type == 10 || type == 11) {
            direction_id = calls[i].direction_id;
            if (strlen(calls[i].desttype)) {
                sprintf(direction, "%s %s", calls[i].direction_name, calls[i].desttype);
            } else {
                sprintf(direction, "%s", calls[i].direction_name);
            }
        }
        if (type == 7 || type == 9 || type == 10 || type == 11) {
            destination_id = calls[i].destination_id;
            strcpy(destination, calls[i].destination);
            strcpy(prefix, calls[i].prefix);
        }

        skip:;

    }

    if (calls_data_count && count) {
        mor_aggregate_sql_format(user_id, user_price, user_billsec, terminator_id, terminator_price, terminator_billsec, billsec, real_billsec, answered, prefix, direction, direction_id, destination, count, user_count, type, tphid, tpdid, tpmid, user_price_tax);
        user_price = terminator_price = user_billsec = terminator_billsec = billsec = real_billsec = count = user_count = answered = 0;
    }

    if (calls) free(calls);
    if (arg) free(arg);

    pthread_exit(NULL);

}


/*
    Format mysql aggregate update batch
*/


void mor_aggregate_sql_format(int o_id, double o_price, long int o_billsec, int t_id, double t_price, long int t_billsec, long int billsec, double real_billsec, int answered, char *prefix, char *direction, int direction_id, char *destination, int calls_count, int user_calls_count, int type, uint64_t tphid, uint64_t tpdid, uint64_t tpmid, double o_price_tax) {

    char o_id_str[64] = "X";
    char t_id_str[64] = "X";
    char prefix_str[64] = "X";
    char direction_str[256] = "X";
    char buffer[1024] = "";
    uint64_t crc = 0;
    char tmp_buffer[1024] = "";

    if (o_id < 0) o_id = 0;
    if (t_id < 0) t_id = 0;

    if (o_id > 0) sprintf(o_id_str, "%d", o_id);
    if (t_id > 0) sprintf(t_id_str, "%d", t_id);
    if (strlen(prefix) > 0) strcpy(prefix_str, prefix);
    if (strlen(direction) > 0 && direction_id) sprintf(direction_str, "%d%s", direction_id, direction);

    // lock thread because other aggregate threads might be running
    pthread_mutex_lock(&mutex);

    // for hours
    sprintf(buffer, "%s,%s,%s,%d,%s,%" PRIu64, o_id_str, t_id_str, prefix_str, type, direction_str, tphid);
    crc = crc64((const void *)buffer, strlen(buffer));
    sprintf(tmp_buffer, "(%" PRIu64 ",%d,%f,%ld,%d,%f,%ld,%ld,%f,%d,%d,'%s',%d,'%s','%s',%d,%" PRIu64 ",%f),", crc, o_id, o_price, o_billsec, t_id, t_price, t_billsec, billsec, real_billsec, answered, calls_count, prefix, type, direction, destination, user_calls_count, tphid, o_price_tax);
    strcat(insert_update_values_query, tmp_buffer);
    // for days
    sprintf(buffer, "%s,%s,%s,%d,%s,%" PRIu64, o_id_str, t_id_str, prefix_str, type, direction_str, tpdid);
    crc = crc64((const void *)buffer, strlen(buffer));
    sprintf(tmp_buffer, "(%" PRIu64 ",%d,%f,%ld,%d,%f,%ld,%ld,%f,%d,%d,'%s',%d,'%s','%s',%d,%" PRIu64 ",%f),", crc, o_id, o_price, o_billsec, t_id, t_price, t_billsec, billsec, real_billsec, answered, calls_count, prefix, type, direction, destination, user_calls_count, tpdid, o_price_tax);
    strcat(insert_update_values_query, tmp_buffer);
    // for months
    sprintf(buffer, "%s,%s,%s,%d,%s,%" PRIu64, o_id_str, t_id_str, prefix_str, type, direction_str, tpmid);
    crc = crc64((const void *)buffer, strlen(buffer));
    sprintf(tmp_buffer, "(%" PRIu64 ",%d,%f,%ld,%d,%f,%ld,%ld,%f,%d,%d,'%s',%d,'%s','%s',%d,%" PRIu64 ",%f),", crc, o_id, o_price, o_billsec, t_id, t_price, t_billsec, billsec, real_billsec, answered, calls_count, prefix, type, direction, destination, user_calls_count, tpmid, o_price_tax);
    strcat(insert_update_values_query, tmp_buffer);
    batch_count += 3;
    current_aggregates += 3;

    if (batch_count >= INSERT_UPDATE_SIZE) {

        if (mor_update_aggregated_data()) {
            pthread_mutex_unlock(&mutex);
            exit(1);
        }
        batch_count = 0;

    }

    pthread_mutex_unlock(&mutex);

}


/*
    Send aggregate batch query
*/


int mor_update_aggregated_data() {

    if (strlen(insert_update_values_query)) {
        insert_update_values_query[strlen(insert_update_values_query) - 1] = ' ';
        strcat(insert_update_query, insert_update_values_query);
        strcat(insert_update_query, INSERT_UPDATE_ENDING_SQL);
        if (mor_mysql_query(insert_update_query)) {
            return 1;
        }
        memset(insert_update_values_query, 0, INSERT_UPDATE_BUFFER_SIZE);
        sprintf(insert_update_query, INSERT_UPDATE_BEGINNING_SQL);
    }

    return 0;

}


/*
    Get time period id for specified date (if date is not in the time_periods table, insert it and get its id)
*/


uint64_t mor_get_time_period_id(int type, char *calldate) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char time_buffer1[20] = "";
    char time_buffer2[20] = "";
    char query[1024] = "";
    // hour/day/month
    char type_str[256] = "";
    char type_str2[256] = "";

    // return_error = 1 and time_period_id = 0 means that something is wrong and we need to exit
    int return_error = 0;

    // id to time_periods table
    // we will update aggregated data using this period_id
    uint64_t time_period_id = 0;

    if (calldate) {
        strcpy(time_buffer1, calldate);
        strcpy(time_buffer2, calldate);
    } else {
        mor_get_current_date(time_buffer1);
        mor_get_current_date(time_buffer2);
    }

    // change date according to period type (hour, day, month)
    if (type == 1) {
        // time_periods.from_data should look like YYYY-MM-DD HH:00:00
        strcpy(time_buffer1 + 14, "00:00");
        strcpy(time_buffer2 + 14, "59:59");
        sprintf(type_str, "from_date BETWEEN '%s' AND  '%s' AND period_type = 'hour'", time_buffer1, time_buffer2);
        strcpy(type_str2, "hour");
    } else if (type == 2) {
        // time_periods.from_data should look like YYYY-MM-DD 00:00:00
        strcpy(time_buffer1 + 11, "00:00:00");
        sprintf(type_str, "from_date = '%s' AND period_type = 'day'", time_buffer1);
        strcpy(type_str2, "day");
    } else if (type == 3) {
        // time_periods.from_data should look like YYYY-MM-01 00:00:00
        strcpy(time_buffer1 + 8, "01 00:00:00");
        sprintf(type_str, "from_date = '%s' AND period_type = 'month'", time_buffer1);
        strcpy(type_str2, "month");
    }

    // we try to get period id again when we didn't find one and inserted new one
    try_again:

    // try to find period id
    sprintf(query, "SELECT id, from_date, last_call_id FROM time_periods WHERE %s", type_str);

    // lock thread because aggregate threads might be running
    pthread_mutex_lock(&mutex);

    // get period_id for this hour/day/month
    if (mor_mysql_query(query)) {
        pthread_mutex_unlock(&mutex);
        return 0;
    }

    // get results
    result = mysql_store_result(&mysql);
    pthread_mutex_unlock(&mutex);

    if (result) {
        if (mysql_num_rows(result)) {
            row = mysql_fetch_row(result);
            if (row[0]) time_period_id = atoll(row[0]);
            if (type == 1) if (row[1]) strcpy(aggregate_stopped_at_calldate, row[1]);
            if (type == 1) if (row[2]) aggregate_stopped_at_callid = atoll(row[2]);
        }
    }

    mysql_free_result(result);

    // if we did not get period id, insert new one
    if (!time_period_id) {

        // if new one was inserted but we still didn't get it, stop everything and check why
        if (!return_error) {

            sprintf(query, "INSERT INTO time_periods(period_type, from_date) VALUES('%s', '%s')", type_str2, time_buffer1);

            // lock thread because aggregate threads might be running
            pthread_mutex_lock(&mutex);
            // get period_id for this hour
            if (mor_mysql_query(query)) {
                pthread_mutex_unlock(&mutex);
                return 0;
            }
            pthread_mutex_unlock(&mutex);

            // set this variable to prevent loop
            return_error = 1;
            // try one more time to get time_period id
            // we should get id of currently inserted time period
            goto try_again;

        } else {
            return 0;
        }

    }

    return time_period_id;

}


/*
    Finished time period looks like this 'xxxx-xx-xx xx:59:59'
*/


void mor_mark_finished_time_period() {

    char query[1024] = "";
    sprintf(query, "UPDATE time_periods SET from_date = CONCAT(SUBSTRING(from_date, 1, 14), '59:59') WHERE id = %" PRIu64, time_period_hour_id);

    // lock thread because aggregate threads might be running
    pthread_mutex_lock(&mutex);
    // get period_id for this hour
    if (mor_mysql_query(query)) {
        pthread_mutex_unlock(&mutex);
        return;
    }
    pthread_mutex_unlock(&mutex);

}
