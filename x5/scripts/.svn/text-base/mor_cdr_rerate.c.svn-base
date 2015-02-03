// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Script recalculates user's and reseller's cdr and balance

#define SCRIPT_VERSION      "1.8"
#define SCRIPT_NAME         "mor_cdr_rerate"
#define SQL_BATCH_SIZE      100
#define BUFFER_SIZE         SQL_BATCH_SIZE * 350 + 600
#define RERATE_BACTHES      100000
#define PROGRESS_TIMER      10
#define MOR_SQL_CONNECTIONS 4

#include "mor_functions.c"
#include "mor_cdr_rerate.h"

// Main function

int main(int argc, char *argv[]) {

    // check if debug is ON
    if (argc > 1) {
        if (strcmp(argv[1], "--debug") == 0) {
            DEBUG_RERATE = 1;
        }
    }

    // mark task as failed on segmentation fault
    struct sigaction sa;
    memset(&sa, 0, sizeof(struct sigaction));
    sigemptyset(&sa.sa_mask);
    sa.sa_sigaction = error_handle;
    sa.sa_flags     = SA_SIGINFO;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    atexit(error_handle);

    int i = 0;

    // mark start time
    gettimeofday(&t0, NULL);
    gettimeofday(&_t0, NULL);
    _t=_t0.tv_sec;
    _ut0=_t0.tv_usec;
    t=_t0.tv_sec;
    ut0=_t0.tv_usec;

    mor_init("Starting 'MOR X5 CDR Rerate' script\n");

    if (mor_task_get(1, &user_id, date_from, date_till, ghost_time_str, include_reseller_users_str, NULL, NULL)) return 1;

    if (strlen(ghost_time_str)) {
        ghost_time = atof(ghost_time_str);
    }

    if (strlen(include_reseller_users_str)) {
        include_reseller_users = atoi(include_reseller_users_str);
    }

    if (user_id > -1) {
        user_is_reseller = is_reseller(user_id);
        user_belongs_to_reseller = belongs_to_reseller(user_id);
        mor_log("User belongs to reseller: %d\n", user_belongs_to_reseller);
    }

    // we mark task as failed in case script will be interrupted
    // at the end of the script we will mark it as completed
    task_failed = 1;

    if (task_id) {

        get_calls_count();

        if (total_calls) {
            mor_log("Total Calls retrieved: %lli\n", total_calls);
        } else {
            mor_log("No calls found\n");
            // task did not failed
            task_failed = 0;
            if (!DEBUG_RERATE) {
                mor_task_finish();
            }
            return 0;
        }

        load_locationrules();

        if (DEBUG_RERATE == 0) mor_task_lock();

        // create threads as 'detached'
        pthread_attr_t tattr;
        pthread_attr_init(&tattr);
        pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_DETACHED);

        mor_log("Starting rerating\n");

        // enable progress timer
        pthread_t timer;
        pthread_create(&timer, &tattr, set_timer, NULL);

        for (i = 0; i < rerate_batches; i++) {

            mor_log("Getting calls from id: %lld LIMIT %d\n", last_call_id, RERATE_BACTHES);
            // printf("Getting calls from id: %lld to %lld\n", min_call_id, min_call_id + total_calls_id_diff);

            if (calls_get(i)) {
                calls_rerate();
            }

            call_list_free();
            reset_globals();

        }

        // calculate deltas
        calculate_user_balance_diff();
        // update user balance
        update_user_balance();

        mor_log("--------------------------------------------------------------------------------\n");
        mor_log("TOTAL CALLS: %lld\n", total_calls);
        mor_log("RERATED USER CALLS: %lld\n", user_diff);
        mor_log("RERATED RESELLER CALLS: %lld\n", reseller_diff);
        mor_log("RERATED PROVIDER CALLS: %lld\n\n", provider_diff);

        mor_log("-------------------------------------------------------\n");
        mor_log("   PRICE                |      OLD     |      NEW      \n");
        mor_log("-------------------------------------------------------\n");
        mor_log("   USER                 |  %9.3f   |  %9.3f            \n", old_user_price, new_user_price);
        mor_log("   RESELLER             |  %9.3f   |  %9.3f            \n", old_reseller_price, new_reseller_price);
        mor_log("   PROVIDER             |  %9.3f   |  %9.3f            \n", old_provider_price, new_provider_price);
        mor_log("-------------------------------------------------------\n\n");

        mor_log("-------------------------------------------------------\n");
        mor_log("   BILLSEC              |      OLD     |      NEW      \n");
        mor_log("-------------------------------------------------------\n");
        mor_log("   USER                 |  %9lld   |  %9lld            \n", old_user_billsec, new_user_billsec);
        mor_log("   RESELLER             |  %9lld   |  %9lld            \n", old_reseller_billsec, new_reseller_billsec);
        mor_log("   PROVIDER             |  %9lld   |  %9lld            \n", old_provider_billsec, new_provider_billsec);
        mor_log("-------------------------------------------------------\n\n");

        mor_log("-------------------------------------------------------\n");
        mor_log("   DELTA                | PRICE DELTA  | BILLSEC DELTA \n");
        mor_log("-------------------------------------------------------\n");
        mor_log("   USER                 |  %9.3f   | %9lld             \n", user_delta_price, new_user_billsec - old_user_billsec);
        mor_log("   RESELLER             |  %9.3f   | %9lld             \n", reseller_delta_price, new_reseller_billsec - old_reseller_billsec);
        mor_log("   PROVIDER             |  %9.3f   | %9lld             \n", provider_delta_price, new_provider_billsec - old_provider_billsec);
        mor_log("-------------------------------------------------------\n\n");

        // terminate progress timer
        pthread_cancel(timer);
        pthread_attr_destroy(&tattr);

        if (DEBUG_RERATE == 0) mor_task_finish();

    }

    for (i = 0; i < MOR_SQL_CONNECTIONS; i++) {
        mysql_close(&mysql_multi[i]);
    }

    mysql_close(&mysql);
    mysql_library_end();
    mor_log("Closed connection to DB\n");

    // printf("cached_rates_count %lld\n", cached_rates_count);

    // mark end time
    gettimeofday(&t1, NULL);
    tt=t1.tv_sec;
    ut1=t1.tv_usec;

    // calculate script runtime and rerate speed
    if (ut0 > ut1) {
        ut1 += 1000000;
        tt -= 1;
    }

    double duration = (int)(tt-t) + (double)(ut1-ut0)/1000000;

    if (total_calls > 0) {
        mor_log("Script run time: %f sec, [%f s/call]\n", duration, duration/total_calls);
        if (DEBUG_RERATE) printf("Script run time: %f sec. [%f s/call]\n", duration, duration/total_calls);
    }

    if (cached_rates) {
        free(cached_rates);
        cached_rates = NULL;
    }

    if (user_balance) {
        free(user_balance);
        user_balance = NULL;
    }

    // script ended
    mor_log("MOR CDR Rerate script completed\n");

    // task did not failed
    task_failed = 0;

    return 0;
}

// Functions

// rerates all calls
void calls_rerate() {

    // create threads as 'detached'
    pthread_attr_t tattr;
    pthread_attr_init(&tattr);
    pthread_attr_setdetachstate(&tattr, PTHREAD_CREATE_DETACHED);

    call_data *current = NULL;

    strcat(update_query, update_query_beginning);

    // GET RATES

    current = call_data_start;
    while (current != NULL) {

        int user_cached_index = -1;         // by default, cached rates not found (-1)
        int reseller_cached_index = -1;     // by default, cached rates not found (-1)
        int provider_cached_index = -1;     // by default, cached rates not found (-1)

        if (current->rerate_user_cdr) {
            if (strlen(current->prefix)) {
                pthread_mutex_lock(&mutex);
                user_cached_index = get_cached_rate(current, current->user_tariff, current->prefix, 1);
                pthread_mutex_unlock(&mutex);
            }
        } else {
            // no need to get rates
            user_cached_index = -2;
        }

        if (current->rerate_reseller_cdr) {
            if (strlen(current->prefix)) {
                pthread_mutex_lock(&mutex);
                reseller_cached_index = get_cached_rate(current, current->reseller_tariff, current->prefix, 2);
                pthread_mutex_unlock(&mutex);
            }
        } else {
            // not need to get rates
            reseller_cached_index = -2;
        }

        if (strlen(current->prefix)) {
            pthread_mutex_lock(&mutex);
            provider_cached_index = get_cached_rate(current, current->provider_tariff, current->prefix, 3);
            pthread_mutex_unlock(&mutex);
        }

        if (user_cached_index == -1 || reseller_cached_index == -1 || provider_cached_index == -1) {
            pt_args_t *pt_args = malloc(sizeof(pt_args_t));
            pt_args->data = current;
            pt_args->user_cached_rate_index = user_cached_index;
            pt_args->reseller_cached_rate_index = reseller_cached_index;
            pt_args->provider_cached_rate_index = provider_cached_index;
            pthread_mutex_lock(&mutex);
            get_rate_details_sem++;
            pthread_mutex_unlock(&mutex);
            pthread_t get_rate_thread;
            pthread_create(&get_rate_thread, &tattr, get_rate_details, (void *)pt_args);
        }

        current = current->next;
    }
    current = call_data_start;

    // wait for all all threads to finish work
    // * why don't i just join threads instead of this weird semaphore? maybe i will change it in the future *
    while (get_rate_details_sem > 0);

    while (current != NULL) {

        // rerate user part of cdr
        if (current->rerate_user_cdr) {
            calculate_call_price(current, 1);
        }

        // rerate reseller part of cdr
        if (current->rerate_reseller_cdr) {
            calculate_call_price(current, 2);
        }

        // rerate provider part of cdr
        calculate_call_price(current, 3);

        current = current->next;
    }
    current = call_data_start;

    // find rerated calls
    while (current != NULL) {

        int user_need_update = 0;
        int reseller_need_update = 0;
        int provider_need_update = 0;

        if (current->rerate_user_cdr) {
            // check user price
            // check difference, because there may be very small rouding errors
            if (fabs(current->user_price - current->user_new_price) > 0.000001 && !(current->user_price == 0 && current->user_new_price == 0)) {
                user_need_update = 1;
            } else {
                // there may be a very small error due to rounding
                // so we just assing one to another so that they would be equal
                current->user_new_price = current->user_price;
            }

            // check user billsec
            if (current->user_billsec != current->user_new_billsec && !(current->user_billsec == 0 && current->user_new_billsec == 0)) {
                user_need_update = 1;
            }
        }

        if (current->rerate_reseller_cdr) {
            // check reseller price
            // check difference, because there may be very small rouding errors
            if (fabs(current->reseller_price - current->reseller_new_price) > 0.000001 && !(current->reseller_price == 0 && current->reseller_new_price == 0)) {
                reseller_need_update = 1;
            } else {
                // there may be a very small error due to rounding
                // so we just assing one to another so that they would be equal
                current->reseller_new_price = current->reseller_price;
            }

            // check reseller billsec
            if (current->reseller_billsec != current->reseller_new_billsec && !(current->reseller_billsec == 0 && current->reseller_new_billsec == 0)) {
                reseller_need_update = 1;
            }
        }

        // check provider price
        // check difference, because there may be very small rouding errors
        if (fabs(current->provider_price - current->provider_new_price) > 0.000001 && !(current->provider_price == 0 && current->provider_new_price == 0)) {
            provider_need_update = 1;
        } else {
            // there may be a very small error due to rounding
            // so we just assing one to another so that they would be equal
            current->provider_new_price = current->provider_price;
        }

        // check provider billsec
        if (current->provider_billsec != current->provider_new_billsec && !(current->provider_billsec == 0 && current->provider_new_billsec == 0)) {
            provider_need_update = 1;
        }

        if (user_need_update) {
            user_diff++;
        }

        if (reseller_need_update) {
            reseller_diff++;
        }

        if (provider_need_update) {
            provider_diff++;
        }

        if (DEBUG_RERATE == 0 && (user_need_update || reseller_need_update || provider_need_update)) {

            double uprice = current->user_price;
            double urate = current->user_max_arate;
            int ubillsec = current->user_billsec;

            double rprice = current->reseller_price;
            double rrate = current->reseller_max_arate;
            int rbillsec = current->reseller_billsec;

            double pprice = current->provider_price;
            double prate = current->provider_max_arate;
            int pbillsec = current->provider_billsec;

            if (user_need_update) {
                uprice = current->user_new_price;
                ubillsec = current->user_new_billsec;
                urate = current->user_max_arate;
            }

            if (reseller_need_update) {
                rprice = current->reseller_new_price;
                rbillsec = current->reseller_new_billsec;
                rrate = current->reseller_max_arate;
            }

            if (provider_need_update) {
                pprice = current->provider_new_price;
                pbillsec = current->provider_new_billsec;
                prate = current->provider_max_arate;
            }

            sprintf(buffer, "(%lld,%.6f,%.6f,%d,%.6f,%.6f,%d,%.6f,%.6f,%d),", current->call_id, uprice, urate, ubillsec, rprice, rrate, rbillsec, pprice, prate, pbillsec);
            strcat(update_query, buffer);
            batch_counter++;

        }

        if (DEBUG_RERATE == 0 && (batch_counter == SQL_BATCH_SIZE)) {

            batch_counter = 0; // reset batch counter

            update_query[strlen(update_query) - 1] = '\0'; // remove last comma separator
            strcat(update_query, update_query_ending);    // add query ending
            char *thread_buffer = malloc(BUFFER_SIZE * sizeof(char));
            strcpy(thread_buffer, update_query);

            pt_args_t *pt_args = malloc(sizeof(pt_args_t));
            pt_args->buffer = thread_buffer;
            pthread_mutex_lock(&mutex);
            update_cdr_sem++;
            pthread_mutex_unlock(&mutex);

            pthread_t update;
            pthread_create(&update, &tattr, update_record, (void *)pt_args);

            memset(update_query, 0, sizeof(update_query));
            memset(buffer, 0, sizeof(buffer));
            strcat(update_query, update_query_beginning);

        }

        rerated_calls++;

        current = current->next;
    }
    current = call_data_start;

    // wait for all all threads to finish work
    // * why don't i just join threads instead of this weird semaphore? maybe i will change it in the future *
    while (update_cdr_sem > 0);

    // sum new prices and billsec
    while (current != NULL) {

        // calculate new user price for single user
        if (current->rerate_user_cdr) {
            int user_balance_index = get_user_balance_index(current->user_id);
            if (user_balance_index > -1) {
                update_user_new_balance(user_balance_index, current->user_new_price);
            }
        }

        if (current->rerate_reseller_cdr) {
            int reseller_balance_index = get_user_balance_index(current->reseller_id);
            if (reseller_balance_index > -1) {
                update_user_new_balance(reseller_balance_index, current->reseller_new_price);
            }
        }

        new_user_price += current->user_new_price;
        new_reseller_price += current->reseller_new_price;
        new_provider_price += current->provider_new_price;
        new_user_billsec += current->user_new_billsec;
        new_reseller_billsec += current->reseller_new_billsec;
        new_provider_billsec += current->provider_new_billsec;
        current = current->next;
    }
    current = call_data_start;

    user_delta_price = old_user_price - new_user_price;
    reseller_delta_price = old_reseller_price - new_reseller_price;
    provider_delta_price = old_provider_price - new_provider_price;

    // update last calls
    if (DEBUG_RERATE == 0 && (strlen(buffer) > 0)) {
        strcat(update_query, buffer);
        update_query[strlen(update_query) - 1] = ' '; // remove last separator
        strcat(update_query, update_query_ending);
        int connection = 0;
        if (mor_mysql_query_multi(update_query, &connection)) {
            return;
        }
        mysql_connections[connection] = 0;
    }

}

// free memory allocated for call_list dynamic list

void call_list_free() {

    long long int i = 0;

    call_data *current, *next_node;

    current = call_data_start;
    while (current != NULL) {
        next_node = current->next;

        free (current);
        current = next_node;

        i++;
    }

    mor_log("Call ID Nodes freed: %lli\n", i);

}

// get calls's ids from db and put them into dynamic list

int calls_get(int i) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";
    char user_sql[64] = "";
    char sign[64] = ">";
    int connection = 0;

    long long int retrieved_calls = 0;

    call_data *node = NULL, *end_node = NULL;

    if (user_id > -1) {
        if (user_is_reseller) {
            // SQL to select calls for particular reseller
            sprintf(user_sql, "calls.reseller_id = %d AND", user_id);
        } else {
            // SQL to select calls for particular user
            sprintf(user_sql, "calls.user_id = %d AND", user_id);
        }
    }

    if (first_iteration) {
        strcpy(sign, ">=");
        first_iteration = 0;
    }

    sprintf(sqlcmd, "SELECT calls.id, user_price, user.tariff_id, calldate, billsec, user_billsec, user_rate, prefix, calls.user_id, tariffs.purpose, dst, "
        "devices.location_id, devices.grace_time, currencies.exchange_rate, reseller_id, reseller_price, reseller.tariff_id, reseller_billsec, reseller_rate, "
        "reseller_tariffs.purpose, reseller_currencies.exchange_rate, provider_id, provider_price, providers.tariff_id, provider_billsec, provider_rate, "
        "provider_currencies.exchange_rate "
        "FROM calls "
        "JOIN devices ON devices.id = calls.accountcode "
        "JOIN users AS user ON user.id = calls.user_id "
        "JOIN tariffs ON tariffs.id = user.tariff_id "
        "JOIN providers ON providers.id = calls.provider_id "
        "JOIN tariffs AS provider_tariffs ON provider_tariffs.id = providers.tariff_id "
        "LEFT JOIN currencies ON (currencies.name = tariffs.currency) "
        "LEFT JOIN currencies AS provider_currencies ON (provider_currencies.name = provider_tariffs.currency) "
        "LEFT JOIN users AS reseller ON reseller.id = calls.reseller_id "
        "LEFT JOIN tariffs AS reseller_tariffs ON reseller_tariffs.id = reseller.tariff_id "
        "LEFT JOIN currencies AS reseller_currencies ON (reseller_currencies.name = reseller_tariffs.currency) "
        "WHERE %s calldate BETWEEN '%s' AND '%s' AND calls.id %s %lld AND disposition = 'ANSWERED' AND provider_id > 0 AND billsec > 0 LIMIT %d",
        user_sql, date_from, date_till, sign, last_call_id, RERATE_BACTHES);

    mor_log("%s\n", sqlcmd);

    if (mor_mysql_query_multi(sqlcmd, &connection)) {
        return 0;
    } else {

        result = mysql_store_result(&mysql_multi[connection]);
        mysql_connections[connection] = 0;

        if (result) { // there are rows

            while ((row = mysql_fetch_row(result))) {

                if (row[0]) {

                    // form dynamic list
                    node = (call_data *) malloc(sizeof(call_data));
                    memset(node, 0, sizeof(call_data));

                    if (call_data_start == NULL) {
                        call_data_start = node;
                    }

                    node->call_id = atoll(row[0]);
                    node->user_price = atof(row[1]);
                    node->user_tariff = atoi(row[2]);
                    strcpy(node->calldate, row[3]);
                    node->ghost_billsec = (int)ceilf(atoi(row[4]) + (atoi(row[4]) * (ghost_time/100)));
                    node->billsec = atoi(row[4]);
                    node->user_billsec = atoi(row[5]);
                    node->user_rate = atof(row[6]);
                    node->user_max_arate = atof(row[6]);
                    strcpy(node->prefix, row[7]);
                    node->user_id = atoi(row[8]);
                    if (strcmp(row[9], "user") == 0) node->user_tariff_type = 1;
                    strcpy(node->dst, row[10]);
                    node->location_id = atoi(row[11]);
                    if (row[12]) node->grace_time = atoi(row[12]); else node->grace_time = 0;
                    if (row[13]) node->user_exchange_rate = atof(row[13]); else node->user_exchange_rate = 1;

                    // for reseller
                    node->reseller_tariff_type = 0;
                    if (row[14]) node->reseller_id = atoi(row[14]); else node->reseller_id = 0;
                    if (row[15]) node->reseller_price = atof(row[15]); else node->reseller_price = 0;
                    if (row[16]) node->reseller_tariff = atoi(row[16]); else node->reseller_tariff = 0;
                    if (row[17]) node->reseller_billsec = atoi(row[17]); else node->reseller_billsec = 0;
                    if (row[18]) node->reseller_rate = atof(row[18]); else node->reseller_rate = 0;
                    if (row[18]) node->reseller_max_arate = atof(row[18]); else node->reseller_max_arate = 0;
                    if (row[19]) if (strcmp(row[19], "user") == 0) node->reseller_tariff_type = 1;
                    if (row[20]) node->reseller_exchange_rate = atof(row[20]); else node->reseller_exchange_rate = 1;

                    // for provider
                    // provider tariff type should be always wholesale
                    if (row[21]) node->provider_id = atoi(row[21]); else node->provider_id = 0;
                    if (row[22]) node->provider_price = atof(row[22]); else node->provider_price = 0;
                    if (row[23]) node->provider_tariff = atoi(row[23]); else node->provider_tariff = 0;
                    if (row[24]) node->provider_billsec = atoi(row[24]); else node->provider_billsec = 0;
                    if (row[25]) node->provider_rate = atof(row[25]); else node->provider_rate = 0;
                    if (row[25]) node->provider_max_arate = atof(row[25]); else node->provider_max_arate = 0;
                    if (row[26]) node->provider_exchange_rate = atof(row[26]); else node->provider_exchange_rate = 1;

                    // fix broken exchange rates
                    if (node->user_exchange_rate == 0) node->user_exchange_rate = 0;
                    if (node->reseller_exchange_rate == 0) node->reseller_exchange_rate = 0;
                    if (node->provider_exchange_rate == 0) node->provider_exchange_rate = 0;

                    // localization rules
                    lrules_ret_t *changed_tariff = localize_dst(node->dst, node->localized_dst, node->location_id);
                    if (changed_tariff) {
                        node->user_tariff = changed_tariff->tariff_id;
                        node->user_tariff_type = changed_tariff->tariff_type;
                        free(changed_tariff);
                    }

                    // should we change user part of cdr?
                    if (!(node->reseller_id && !include_reseller_users) || user_belongs_to_reseller) {
                        node->rerate_user_cdr = 1;
                    }

                    // should we change reseller part of cdr?
                    if (node->reseller_id && user_belongs_to_reseller == 0) {
                        node->rerate_reseller_cdr = 1;
                    }

                    if (node->rerate_user_cdr) {
                        int user_balance_index = get_user_balance_index(node->user_id);
                        if (user_balance_index > -1) {
                            update_user_old_balance(user_balance_index, node->user_price);
                        } else {
                            add_user_balance(node->user_id, node->user_price);
                        }
                    }

                    if (node->rerate_reseller_cdr) {
                        int reseller_balance_index = get_user_balance_index(node->reseller_id);
                        if (reseller_balance_index > -1) {
                            update_user_old_balance(reseller_balance_index, node->reseller_price);
                        } else {
                            add_user_balance(node->reseller_id, node->reseller_price);
                        }
                    }

                    // calculate total user, reseller prices and billsec
                    if (node->rerate_user_cdr) {
                        old_user_price += node->user_price;
                        old_user_billsec += node->user_billsec;
                    }
                    if (node->rerate_reseller_cdr) {
                        old_reseller_price += node->reseller_price;
                        old_reseller_billsec += node->reseller_billsec;
                    }
                    old_provider_price += node->provider_price;
                    old_provider_billsec += node->provider_billsec;

                    node->next = NULL;

                    if (end_node) {
                        end_node->next = node;
                    }

                    end_node = node;
                }

                retrieved_calls++;
            }

            if (node) {
                last_call_id = node->call_id;
            } else {
                last_call_id += RERATE_BACTHES;
            }

            mysql_free_result(result);
        }
    }

    mor_log("Total Calls retrieved for batch (%d): %lli\n", i, retrieved_calls);
    mor_log("Memory taken: %lli bytes (%lu/node)\n", sizeof(call_data)*retrieved_calls, sizeof(call_data));

    return retrieved_calls;
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

// timer periodically updates current progress
void *set_timer() {

    char sqlcmd[1024] = "";
    long int count = 1;
    long int time_left = 0;
    double calls_per_sec = 0;
    double progress_percent = 0;
    char datetime[100] = "";
    int connection = 0;

    printf("--------------------------------------------------------------------------------\n");
    printf("    Progress   | Completed | Calls per sec | Time left |  Expected to finish at \n");
    printf("--------------------------------------------------------------------------------\n");

    while (1) {

        long long int progress_rerated_calls = rerated_calls;

        if (progress_rerated_calls == 0) progress_rerated_calls = 1;

        sleep(PROGRESS_TIMER);

        progress_percent = (double)((double)progress_rerated_calls/total_calls)*100;
        calls_per_sec = (double)progress_rerated_calls/count;
        if (calls_per_sec > 0) {
            time_left = ceil((double)(total_calls - progress_rerated_calls) / calls_per_sec);
        } else {
            time_left = 1;
        }

        calculate_expected_time(datetime, time_left);

        if (!is_date(datetime)) {
            strcpy(datetime, "0000-00-00 00:00:00");
        }

        sprintf(sqlcmd,"UPDATE background_tasks SET percent_completed = %.3f, expected_to_finish_at = '%s' WHERE id = %i;", progress_percent, datetime, task_id);
        if (mor_mysql_query_multi(sqlcmd, &connection)) {
            mor_log("Query failed: %s\n", sqlcmd);
            exit(1);
        }
        mysql_connections[connection] = 0;

        printf("  %.5lld/%.5lld  | %6.2f %%  |  %9.2f    | %4ld sec  |  %s\n", progress_rerated_calls, total_calls, progress_percent, calls_per_sec, time_left, datetime);

        count += PROGRESS_TIMER;

    }

    pthread_exit(NULL);
}

void *update_record(void *arg) {

    int connection = 0;
    pt_args_t *args = (pt_args_t *)arg;

    if (mor_mysql_query_multi(args->buffer, &connection)) {
        exit(1);
    }

    mysql_connections[connection] = 0;

    pthread_mutex_lock(&mutex);
    update_cdr_sem--;
    pthread_mutex_unlock(&mutex);

    free(args->buffer);
    free(args);

    pthread_exit(NULL);
}

// function that handles segmentation fault and regular returns

void error_handle() {
    static int marked = 0;

    if (marked == 0) {
        if (task_failed && DEBUG_RERATE == 0) {
            mor_task_unlock(4); // mark task as failed
        }
        marked = 1;
    }

    exit(1);
}


void *get_rate_details(void *arg) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char prefix_sql_line[9000] = "";
    char calldate[20] = "";
    int connection = 0;
    int i = 0;
    int user = 1;
    int tariff_type = 0;
    char sqlcmd[10000] = "";
    pt_args_t *args = (pt_args_t *)arg;

    struct tm tmm;
    char daytype[3] = "WD";
    char call_time[9] = "00:00:00";

    // check if call was made during a free day or a work day
    strptime(args->data->calldate, DATE_FORMAT, &tmm);
    if (tmm.tm_wday == 0 || tmm.tm_wday == 6) {
        strcpy(daytype, "FD");
    }

    strcpy(call_time, args->data->calldate + 11);
    strcpy(calldate, args->data->calldate);

    // wholesale

    for (user = 1; user <= 3; user++) {

        // user = 1 - user
        // user = 2 - reseller
        // user = 3 - provider

        if (user == 1 && args->user_cached_rate_index != -1) continue;
        if (user == 2 && args->reseller_cached_rate_index != -1) continue;
        if (user == 3 && args->provider_cached_rate_index != -1) continue;

        if (user == 1) tariff_type = args->data->user_tariff_type;
        if (user == 2) tariff_type = args->data->reseller_tariff_type;
        if (user == 3) tariff_type = 0;

        if (tariff_type == 0) {

            int tariff_id;
            int *total_arates;
            double *max_arate;
            double *total_event_price;
            double *rate_ws;
            int *increment_ws;
            int *min_time_ws;
            double *connection_fee_ws;

            if (user == 1) {
                tariff_id = args->data->user_tariff;
                rate_ws = &args->data->user_rate_ws;
                increment_ws = &args->data->user_increment_ws;
                min_time_ws = &args->data->user_min_time_ws;
                connection_fee_ws = &args->data->user_connection_fee_ws;
                total_arates = &args->data->user_total_arates;
                max_arate = &args->data->user_max_arate;
                total_event_price = &args->data->user_total_event_price;
            } else if (user == 2) {
                tariff_id = args->data->reseller_tariff;
                rate_ws = &args->data->reseller_rate_ws;
                increment_ws = &args->data->reseller_increment_ws;
                min_time_ws = &args->data->reseller_min_time_ws;
                connection_fee_ws = &args->data->reseller_connection_fee_ws;
                total_arates = &args->data->reseller_total_arates;
                max_arate = &args->data->reseller_max_arate;
                total_event_price = &args->data->reseller_total_event_price;
            } else if (user == 3) {
                tariff_id = args->data->provider_tariff;
                rate_ws = &args->data->provider_rate_ws;
                increment_ws = &args->data->provider_increment_ws;
                min_time_ws = &args->data->provider_min_time_ws;
                connection_fee_ws = &args->data->provider_connection_fee_ws;
                total_arates = &args->data->provider_total_arates;
                max_arate = &args->data->provider_max_arate;
                total_event_price = &args->data->provider_total_event_price;
            } else {
                pthread_mutex_lock(&mutex);
                get_rate_details_sem--;
                pthread_mutex_unlock(&mutex);
                exit(1);
            }

            format_prefix_sql(prefix_sql_line, args->data->localized_dst);

            sprintf(sqlcmd, "SELECT A.prefix, ratedetails.rate, ratedetails.increment_s, ratedetails.min_time, ratedetails.connection_fee as 'cf', rates.ghost_min_perc FROM rates JOIN ratedetails ON (ratedetails.rate_id = rates.id AND (ratedetails.daytype = '%s' OR ratedetails.daytype = '' ) AND '%s' BETWEEN ratedetails.start_time AND ratedetails.end_time) JOIN (SELECT destinations.* FROM destinations WHERE destinations.prefix IN (%s)) as A ON (A.id = rates.destination_id) WHERE rates.tariff_id = %i AND (rates.effective_from <= '%s' OR rates.effective_from IS NULL) ORDER BY LENGTH(A.prefix) DESC, rates.effective_from DESC LIMIT 1", daytype, call_time, prefix_sql_line, tariff_id, calldate);

            if (mor_mysql_query_multi(sqlcmd, &connection)) {
                exit(1);
            } else {
                result = mysql_store_result(&mysql_multi[connection]);
                mysql_connections[connection] = 0;
            }

            if (result) {
                while (( row = mysql_fetch_row(result) )) {

                    if (row[1]) *rate_ws = atof(row[1]); else *rate_ws = 0;
                    if (row[2]) *increment_ws = atoi(row[2]); else *increment_ws = 1;
                    if (row[3]) *min_time_ws = atoi(row[3]); else *min_time_ws = 0;
                    if (row[4]) *connection_fee_ws = atof(row[4]); else *connection_fee_ws = 0;

                    *total_arates = 1;
                    *max_arate = *rate_ws;
                    *total_event_price = *connection_fee_ws;

                }
                mysql_free_result(result);
            }

        } else {

            // retail

            struct advanced_rate *arates;
            int *total_arates;
            double *max_arate;
            double *total_event_price;
            int *custom_rates;
            int tariff_id = 0;
            int user_id = 0;

            if (user == 1) {
                user_id = args->data->user_id;
                tariff_id = args->data->user_tariff;
                arates = (struct advanced_rate *)&args->data->user_arates;
                total_arates = &args->data->user_total_arates;
                max_arate = &args->data->user_max_arate;
                total_event_price = &args->data->user_total_event_price;
                custom_rates = &args->data->user_custom_rates;
            } else if (user == 2) {
                user_id = args->data->reseller_id;
                tariff_id = args->data->reseller_tariff;
                arates = (struct advanced_rate *)&args->data->reseller_arates;
                total_arates = &args->data->reseller_total_arates;
                max_arate = &args->data->reseller_max_arate;
                total_event_price = &args->data->reseller_total_event_price;
                custom_rates = &args->data->reseller_custom_rates;
            }  else {
                pthread_mutex_lock(&mutex);
                get_rate_details_sem--;
                pthread_mutex_unlock(&mutex);
                exit(1);
            }

            *total_arates = 0;
            *max_arate = 0;
            *total_event_price = 0;

            format_prefix_sql(prefix_sql_line, args->data->localized_dst);

            sprintf(sqlcmd, "SELECT B.prefix, aid, afrom, adur, atype, around, aprice, acid, acfrom, acdur, actype, acround, acprice, ghostminperc FROM (SELECT A.prefix, aratedetails.id as 'aid', aratedetails.from as 'afrom', aratedetails.duration as 'adur', aratedetails.artype as 'atype', aratedetails.round as 'around', aratedetails.price as 'aprice', acustratedetails.id as 'acid', acustratedetails.from as 'acfrom', acustratedetails.duration as 'acdur', acustratedetails.artype as 'actype', acustratedetails.round as 'acround', acustratedetails.price as 'acprice', SUM(acustratedetails.id) as 'sacid', rates.ghost_min_perc as 'ghostminperc' FROM  rates LEFT JOIN aratedetails ON (aratedetails.rate_id = rates.id  AND '%s' BETWEEN aratedetails.start_time AND aratedetails.end_time AND (aratedetails.daytype = '%s' OR aratedetails.daytype = '')) JOIN destinationgroups ON (destinationgroups.id = rates.destinationgroup_id)   JOIN (SELECT destinations.* FROM  destinations WHERE destinations.destinationgroup_id != 0 AND destinations.prefix IN (%s) ORDER BY LENGTH(destinations.prefix) DESC LIMIT 1) as A ON (A.destinationgroup_id = destinationgroups.id) LEFT JOIN customrates ON (customrates.destinationgroup_id = destinationgroups.id AND customrates.user_id = %i) LEFT JOIN acustratedetails ON (acustratedetails.customrate_id = customrates.id  AND '%s' BETWEEN acustratedetails.start_time AND acustratedetails.end_time AND (acustratedetails.daytype = '%s' OR acustratedetails.daytype = '')) WHERE rates.tariff_id = %i GROUP BY aratedetails.id, acustratedetails.id ) AS B GROUP BY IF(B.sacid > 0,B.acid,B.aid) ORDER BY acfrom ASC, actype ASC, afrom ASC, atype ASC;", call_time, daytype, prefix_sql_line, user_id, call_time, daytype, tariff_id);

            if (mor_mysql_query_multi(sqlcmd, &connection)) {
                exit(1);
            } else {
                result = mysql_store_result(&mysql_multi[connection]);
                mysql_connections[connection] = 0;
            }

            if (result) {
                while (( row = mysql_fetch_row(result) )) {

                    if (!row[7]) {

                        // without custom rates

                        *custom_rates = 0;
                        arates[i].from = atoi(row[2]);
                        arates[i].duration = atoi(row[3]);
                        arates[i].round = atoi(row[5]);
                        arates[i].price = atof(row[6]);

                        if (!strcmp("minute", row[4])) {
                            // minute
                            arates[i].artype = 1;
                            if (arates[i].price > *max_arate) *max_arate = arates[i].price;
                        } else {
                            // event
                            arates[i].artype = 2;
                            *total_event_price += arates[i].price;
                        }

                    } else {

                        // with custom rates

                        *custom_rates = 1;
                        arates[i].from = atoi(row[8]);
                        arates[i].duration = atoi(row[9]);
                        arates[i].round = atoi(row[11]);
                        arates[i].price = atof(row[12]);

                        if (!strcmp("minute", row[10])) {
                            // minute
                            arates[i].artype = 1;
                            if (arates[i].price > *max_arate) *max_arate = arates[i].price;
                        } else {
                            // event
                            arates[i].artype = 2;
                            *total_event_price += arates[i].price;
                        }

                    }

                    // possible bad data fixing
                    if (arates[i].round <= 0) arates[i].round = 1;

                    // char buffier[1024] = "";
                    // sprintf(buffier, "%s|%i|%i|%i|%i|%f\n", row[0], arates[i].from, arates[i].duration, arates[i].artype, arates[i].round, arates[i].price);
                    // printf("%s\n", buffier);

                    i++;

                }

                *total_arates = i;

                mysql_free_result(result);
            }
        }

        // cache these rates
        pthread_mutex_lock(&mutex);
        cached_rates_function(args->data, user);
        pthread_mutex_unlock(&mutex);

    }

    free(args);

    pthread_mutex_lock(&mutex);
    get_rate_details_sem--;
    pthread_mutex_unlock(&mutex);

    return 0;

}

void calculate_call_price(call_data *node, int user) {

    int i = 0;
    int li = 0;
    int t_billsec = 0;
    struct advanced_rate *arates = NULL;
    int total_arates = 0;
    double *max_arate = NULL;
    double rate_ws = 0;
    int min_time_ws = 0;
    int increment_ws = 0;
    double connection_fee_ws = 0;
    int tariff_type = 0;
    int *call_billsec = 0;
    double *call_price = NULL;
    double *call_rate = NULL;
    double *exchange_rate = NULL;
    int grace_time = 0;
    int billsec = 0;

    i = 0;
    li = 0;
    t_billsec = 0;
    if (user == 1 || user == 2) {
        billsec = node->ghost_billsec;
    } else {
        billsec = node->billsec;
    }
    grace_time = node->grace_time;

    if (user == 1) {
        arates = (struct advanced_rate *)&node->user_arates;
        total_arates = node->user_total_arates;
        max_arate = &node->user_max_arate;
        rate_ws = node->user_rate_ws;
        min_time_ws = node->user_min_time_ws;
        increment_ws = node->user_increment_ws;
        connection_fee_ws = node->user_connection_fee_ws;
        tariff_type = node->user_tariff_type;
        call_billsec = &node->user_new_billsec;
        call_price = &node->user_new_price;
        call_rate = &node->user_rate;
        exchange_rate = &node->user_exchange_rate;
    } else if (user == 2) {
        arates = (struct advanced_rate *)&node->reseller_arates;
        total_arates = node->reseller_total_arates;
        max_arate = &node->reseller_max_arate;
        rate_ws = node->reseller_rate_ws;
        min_time_ws = node->reseller_min_time_ws;
        increment_ws = node->reseller_increment_ws;
        connection_fee_ws = node->reseller_connection_fee_ws;
        tariff_type = node->reseller_tariff_type;
        call_billsec = &node->reseller_new_billsec;
        call_price = &node->reseller_new_price;
        call_rate = &node->reseller_rate;
        exchange_rate = &node->reseller_exchange_rate;
    } else if (user == 3) {
        total_arates = node->provider_total_arates;
        max_arate = &node->provider_max_arate;
        rate_ws = node->provider_rate_ws;
        min_time_ws = node->provider_min_time_ws;
        increment_ws = node->provider_increment_ws;
        connection_fee_ws = node->provider_connection_fee_ws;
        tariff_type = 0;
        call_billsec = &node->provider_new_billsec;
        call_price = &node->provider_new_price;
        call_rate = &node->provider_rate;
        exchange_rate = &node->provider_exchange_rate;
    }

    // check grace time
    if (grace_time > 0) {
        if (grace_time >= billsec) {
            billsec = 0;
        }
    }

    if (tariff_type == 1) {

        // RETAIL

        for (i = 0; i < total_arates; i++) {

            if (arates[i].from <= billsec) {
                // this arate is suitable for this call
                if (arates[i].artype == 1) {
                    // minute
                    // count the time frame for us to bill
                    if (arates[i].duration == -1) {
                        // t_billsec = cd->arates[i].duration;
                        t_billsec = billsec - arates[i].from + 1;
                    } else {
                        if (billsec < (arates[i].from + arates[i].duration)) {
                            t_billsec = billsec - arates[i].from + 1;
                        } else {
                            t_billsec = arates[i].duration;
                        }
                    }

                    // possible error fixing
                    if (arates[i].round < 1) arates[i].round = 1;

                    // round time frame
                    if (!(t_billsec % arates[i].round)) {
                        t_billsec = ceilf(t_billsec / arates[i].round) * arates[i].round;
                    } else {
                        t_billsec = (ceilf(t_billsec / arates[i].round) + 1) * arates[i].round;
                    }

                    // count the price for the time frame
                    *call_price += ((arates[i].price / *exchange_rate) * t_billsec) / 60 ;

                } else {
                    // event
                    *call_price += arates[i].price / *exchange_rate;
                    t_billsec = 0;
                }

                li = i;
            }

        }

        if (total_arates > 0) {
            if ((t_billsec + arates[li].from - 1) > billsec) {
                *call_billsec = t_billsec + arates[li].from - 1;
            } else {
                *call_billsec = billsec;
            }
        } else {
            *call_billsec = billsec;
        }

        *call_rate = *max_arate / *exchange_rate;
        *max_arate = *max_arate / *exchange_rate;

    } else {

        // WHOLESALE

        // possible error fixing
        if (increment_ws < 1) {
            increment_ws = 1;
        }

        // count seconds for user wholesale
        if (!(billsec % increment_ws)) {
            *call_billsec = ceilf(billsec / increment_ws) * increment_ws;
        } else {
            *call_billsec = (ceilf(billsec / increment_ws) + 1) * increment_ws;
        }

        if (min_time_ws && (*call_billsec < min_time_ws)) {
            *call_billsec = min_time_ws;
        }

        *call_price = (rate_ws * *call_billsec) / 60;
        *call_price += connection_fee_ws;
        *call_price = *call_price / *exchange_rate;
        *call_rate = rate_ws / *exchange_rate;
        *max_arate = rate_ws / *exchange_rate;

    }



}


int get_cached_rate(call_data *data, int tariff_id, char *prefix, int user) {

    if (cached_rates_count == 0) return -1;

    int i = 0;

    int user_id = 0;
    int *total_arates = NULL;
    double *max_arate = NULL;
    double *total_event_price = NULL;
    double *rate_ws = NULL;
    int *increment_ws = NULL;
    int *min_time_ws = NULL;
    double *connection_fee_ws = NULL;
    struct advanced_rate *arates = NULL;
    int tariff_type = 0;

    // user == 1 - user
    // user == 2 - reseller
    // user == 3 - provider

    if (user == 2) {
        tariff_type = data->reseller_tariff_type;
        if (tariff_type == 0) {
            rate_ws = &data->reseller_rate_ws;
            increment_ws = &data->reseller_increment_ws;
            min_time_ws = &data->reseller_min_time_ws;
            connection_fee_ws = &data->reseller_connection_fee_ws;
            total_arates = &data->reseller_total_arates;
            max_arate = &data->reseller_max_arate;
            total_event_price = &data->reseller_total_event_price;
        } else {
            user_id = data->reseller_id;
            arates = (struct advanced_rate *)&data->reseller_arates;
            total_arates = &data->reseller_total_arates;
            max_arate = &data->reseller_max_arate;
            total_event_price = &data->reseller_total_event_price;
        }
    } else if (user == 1) {
        tariff_type = data->user_tariff_type;
        if (tariff_type == 0) {
            rate_ws = &data->user_rate_ws;
            increment_ws = &data->user_increment_ws;
            min_time_ws = &data->user_min_time_ws;
            connection_fee_ws = &data->user_connection_fee_ws;
            total_arates = &data->user_total_arates;
            max_arate = &data->user_max_arate;
            total_event_price = &data->user_total_event_price;
        } else {
            user_id = data->user_id;
            arates = (struct advanced_rate *)&data->user_arates;
            total_arates = &data->user_total_arates;
            max_arate = &data->user_max_arate;
            total_event_price = &data->user_total_event_price;
        }
    } else if (user == 3) {
        tariff_type = 0;
        rate_ws = &data->provider_rate_ws;
        increment_ws = &data->provider_increment_ws;
        min_time_ws = &data->provider_min_time_ws;
        connection_fee_ws = &data->provider_connection_fee_ws;
        total_arates = &data->provider_total_arates;
        max_arate = &data->provider_max_arate;
        total_event_price = &data->provider_total_event_price;
    }

    for (i = 0; i < cached_rates_count; i++) {
        if ((cached_rates[i].tariff_id == tariff_id) && (strcmp(prefix, cached_rates[i].prefix) == 0)) {

            if (rate_ws) *rate_ws = cached_rates[i].rate_ws;
            if (increment_ws) *increment_ws = cached_rates[i].increment_ws;
            if (min_time_ws) *min_time_ws = cached_rates[i].min_time_ws;
            if (connection_fee_ws) *connection_fee_ws = cached_rates[i].connection_fee_ws;
            if (total_arates) *total_arates = cached_rates[i].total_arates;
            if (total_event_price) *total_event_price = cached_rates[i].total_event_price;
            if (max_arate) *max_arate = cached_rates[i].max_arate;

            if (tariff_type == 1) {
                int j = 0;
                for (j = 0; j < cached_rates[i].total_arates; j++) {
                    arates[j] = cached_rates[i].arates[j];
                }
            }

            return i;
        }
    }

    return -1;

}

void cached_rates_function(call_data *data, int user) {

    int user_id = 0;
    int tariff_id;
    int *total_arates = NULL;
    double *max_arate = NULL;
    double *total_event_price = NULL;
    double *rate_ws = NULL;
    int *increment_ws = NULL;
    int *min_time_ws = NULL;
    double *connection_fee_ws = NULL;
    struct advanced_rate *arates = NULL;
    int tariff_type = 0;

    // user = 1 - user
    // user = 2 - reseller
    // user = 3 - provider

    if (user == 2) {
        tariff_type = data->reseller_tariff_type;
        if (tariff_type == 0) {
            tariff_id = data->reseller_tariff;
            rate_ws = &data->reseller_rate_ws;
            increment_ws = &data->reseller_increment_ws;
            min_time_ws = &data->reseller_min_time_ws;
            connection_fee_ws = &data->reseller_connection_fee_ws;
            total_arates = &data->reseller_total_arates;
            max_arate = &data->reseller_max_arate;
            total_event_price = &data->reseller_total_event_price;
        } else {
            user_id = data->reseller_id;
            tariff_id = data->reseller_tariff;
            arates = (struct advanced_rate *)&data->reseller_arates;
            total_arates = &data->reseller_total_arates;
            max_arate = &data->reseller_max_arate;
            total_event_price = &data->reseller_total_event_price;
        }
    } else if (user == 1) {
        tariff_type = data->user_tariff_type;
        if (tariff_type == 0) {
            tariff_id = data->user_tariff;
            rate_ws = &data->user_rate_ws;
            increment_ws = &data->user_increment_ws;
            min_time_ws = &data->user_min_time_ws;
            connection_fee_ws = &data->user_connection_fee_ws;
            total_arates = &data->user_total_arates;
            max_arate = &data->user_max_arate;
            total_event_price = &data->user_total_event_price;
        } else {
            user_id = data->user_id;
            tariff_id = data->user_tariff;
            arates = (struct advanced_rate *)&data->user_arates;
            total_arates = &data->user_total_arates;
            max_arate = &data->user_max_arate;
            total_event_price = &data->user_total_event_price;
        }
    } else if (user == 3) {
        tariff_type = 0;
        tariff_id = data->provider_tariff;
        rate_ws = &data->provider_rate_ws;
        increment_ws = &data->provider_increment_ws;
        min_time_ws = &data->provider_min_time_ws;
        connection_fee_ws = &data->provider_connection_fee_ws;
        total_arates = &data->provider_total_arates;
        max_arate = &data->provider_max_arate;
        total_event_price = &data->provider_total_event_price;
    }

    cached_rates = realloc(cached_rates, (cached_rates_count + 1) * sizeof(cached_rates_t));

    cached_rates[cached_rates_count].tariff_id = tariff_id;
    strcpy(cached_rates[cached_rates_count].prefix, data->prefix);
    if (rate_ws) {
        cached_rates[cached_rates_count].rate_ws = *rate_ws;
    } else {
        cached_rates[cached_rates_count].rate_ws = 0;
    }
    if (increment_ws) {
        cached_rates[cached_rates_count].increment_ws = *increment_ws;
    } else {
        cached_rates[cached_rates_count].increment_ws = 0;
    }
    if (min_time_ws) {
        cached_rates[cached_rates_count].min_time_ws = *min_time_ws;
    } else {
        cached_rates[cached_rates_count].min_time_ws = 0;
    }
    if (connection_fee_ws) {
        cached_rates[cached_rates_count].connection_fee_ws = *connection_fee_ws;
    } else {
        cached_rates[cached_rates_count].connection_fee_ws = 0;
    }
    if (total_arates) {
        cached_rates[cached_rates_count].total_arates = *total_arates;
    } else {
        cached_rates[cached_rates_count].total_arates = 0;
    }
    if (total_event_price) {
        cached_rates[cached_rates_count].total_event_price = *total_event_price;
    } else {
        cached_rates[cached_rates_count].total_event_price = 0;
    }
    if (max_arate) {
        cached_rates[cached_rates_count].max_arate = *max_arate;
    } else {
        cached_rates[cached_rates_count].max_arate = 0;
    }

    if (tariff_type == 1) {
        int i = 0;
        for (i = 0; i < *total_arates; i++) {
            cached_rates[cached_rates_count].arates[i] = arates[i];
        }
    }

    cached_rates_count++;

}

void format_prefix_sql(char *prefixes, const char *number) {

    char buffer[256] = "";
    int i;

    memset(buffer, 0, sizeof(buffer));
    memset(prefixes, 0, sizeof(prefixes));

    for(i = 0; i < strlen(number); i++) {

        strcat(prefixes, "'");
        strncpy(buffer, number, i + 1);
        strcat(prefixes, buffer);
        strcat(prefixes, "'");
        if( i < (strlen(number) - 1)) strcat(prefixes, ",");
        memset(buffer, 0, sizeof(buffer));

    }

}

int load_locationrules() {

    int connection = 0;
    MYSQL_RES *result;
    MYSQL_ROW row;

    if (mor_mysql_query_multi("SELECT locationrules.location_id, locationrules.cut, locationrules.add, locationrules.tariff_id, minlen, maxlen, tariffs.purpose FROM locationrules LEFT JOIN tariffs ON tariffs.id = locationrules.tariff_id WHERE enabled=1 AND lr_type='dst' ORDER BY location_id, LENGTH(cut) DESC", &connection)) {
        exit(1);
    } else {
        result = mysql_store_result(&mysql_multi[connection]);
        mysql_connections[connection] = 0;
    }

    while (( row = mysql_fetch_row(result) )) {

        if (row[0]) lrules[lrules_count].location_id = atoi(row[0]);
        if (row[1]) strcpy(lrules[lrules_count].cut, row[1]); else lrules[lrules_count].cut[0] = 0;
        if (row[2]) strcpy(lrules[lrules_count].add, row[2]); else lrules[lrules_count].add[0] = 0;
        if (row[3]) lrules[lrules_count].tariff_id = atoi(row[3]); else lrules[lrules_count].tariff_id = -1;
        if (row[4]) lrules[lrules_count].minlen = atoi(row[4]); else lrules[lrules_count].minlen = -1;
        if (row[5]) lrules[lrules_count].maxlen = atoi(row[5]); else lrules[lrules_count].maxlen = -1;
        if (row[6]) {
            if (strcmp(row[6], "user") == 0) {
                lrules[lrules_count].tariff_type = 1;
            } else {
                lrules[lrules_count].tariff_type = 0;
            }
        } else {
            lrules[lrules_count].tariff_type = 0;
        }

        lrules_count++;

        if (lrules_count == 50000) {
            mor_log("Too many location rules\n");
            exit(1);
        }
    }

    mysql_free_result(result);

    return 0;

}

lrules_ret_t *localize_dst(char *dst, char *new_dst, int location_id) {

    int i = 0;
    int str_len = strlen(dst);
    char tmp[32] = "";

    strcpy(new_dst, dst);

    if (lrules_count == 0) return NULL;

    for (i = 0; i < lrules_count; i++) {
        if (location_id == lrules[i].location_id) {
            if (str_len >= lrules[i].minlen && str_len <= lrules[i].maxlen) {
                strncat(tmp, dst, strlen(lrules[i].cut));
                if (strcmp(tmp, lrules[i].cut) == 0) {
                    sprintf(new_dst, "%s%s", lrules[i].add, dst + strlen(lrules[i].cut));
                    if (lrules[i].tariff_id > 0) {
                        lrules_ret_t *lrules_ret = malloc(sizeof(lrules_ret_t));
                        lrules_ret->tariff_id = lrules[i].tariff_id;
                        lrules_ret->tariff_type = lrules[i].tariff_type;
                        return lrules_ret;
                    } else {
                        return NULL;
                    }
                }
                memset(tmp, 0, 32);
            }
        }
    }

    return NULL;

}

void get_calls_count() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int connection = 0;
    char sqlcmd[2048] = "";
    char user_sql[512] = "";

    if (user_id > -1) {
        if (user_is_reseller) {
            // SQL to select calls for particular reseller
            sprintf(user_sql, "calls.reseller_id = %d AND", user_id);
        } else {
            // SQL to select calls for particular user
            sprintf(user_sql, "calls.user_id = %d AND", user_id);
        }
    }

    mor_log("Calculating total calls\n");

    sprintf(sqlcmd, "SELECT count(calls.id), min(calls.id) FROM calls "
                    "JOIN users ON users.id = calls.user_id "
                    "WHERE %s calldate BETWEEN '%s' AND '%s' AND disposition='ANSWERED' AND provider_id > 0 AND billsec > 0", user_sql, date_from, date_till);

    mor_log("%s\n", sqlcmd);

    if (mor_mysql_query_multi(sqlcmd, &connection)) {
        exit(1);
    }

    result = mysql_store_result(&mysql_multi[connection]);
    mysql_connections[connection] = 0;

    if (result) {
        while (( row = mysql_fetch_row(result) )) {
            if (row[0]) total_calls = atoll(row[0]);
            if (row[1]) last_call_id = atoll(row[1]);
        }

        mysql_free_result(result);

    }

    rerate_batches = ceil((total_calls / (float)RERATE_BACTHES));

}

void reset_globals() {

    batch_counter = 0;
    waiting = 0;
    get_rate_details_sem = 0;
    update_cdr_sem = 0;
    memset(buffer, 0, sizeof(buffer));
    memset(update_query, 0, sizeof(update_query));
    call_data_start = NULL;

}

int get_user_balance_index(int user_id) {

    int index = -1;
    int i;

    for (i = 0; i < user_balance_count; i++) {
        if (user_balance[i].user_id == user_id) return i;
    }

    return index;

}

void add_user_balance(int user_id, double user_price) {

    user_balance = realloc(user_balance, (user_balance_count + 1) * sizeof(user_balance_t));
    user_balance[user_balance_count].user_id = user_id;
    user_balance[user_balance_count].new_price = 0;
    user_balance[user_balance_count].old_price = user_price;
    user_balance[user_balance_count].diff_price = 0.0;
    user_balance_count++;

}

void update_user_old_balance(int index, double user_price) {
    user_balance[index].old_price += user_price;
}

void update_user_new_balance(int index, double user_price) {
    user_balance[index].new_price += user_price;
}

void calculate_user_balance_diff() {
    int i;
    for (i = 0; i < user_balance_count; i++) {
        user_balance[i].diff_price = user_balance[i].old_price - user_balance[i].new_price;
    }
}

void update_user_balance() {

    int connection = 0;
    char sqlcmd[1024] = "";
    int i;
    int updated = 0;

    mor_log("Updating user balance. Prices will be calculated for period: %s - %s\n", date_from, date_till);

    for (i = 0; i < user_balance_count; i++) {

        if (fabs(user_balance[i].diff_price) > 0.000001) {
            updated = 1;

            if (user_balance[i].diff_price > 0) {
                mor_log("user_id: %d, old_price, %f, new_price: %f, balance will be increased by %f\n", user_balance[i].user_id, user_balance[i].old_price, user_balance[i].new_price, user_balance[i].diff_price);
            } else {
                mor_log("user_id: %d, old_price, %f, new_price: %f, balance will be decreased by %f\n", user_balance[i].user_id, user_balance[i].old_price, user_balance[i].new_price, -1 * user_balance[i].diff_price);
            }

            if (DEBUG_RERATE == 0) {

                sprintf(sqlcmd,"UPDATE users SET balance = balance + %f WHERE id = %d", user_balance[i].diff_price, user_balance[i].user_id);
                if (mor_mysql_query_multi(sqlcmd, &connection)) {
                    exit(1);
                }

                mysql_connections[connection] = 0;

            }
        }

    }

    if (updated == 0) {
        mor_log("Nothing to update\n");
    }

}

int is_reseller(int user_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    int connection = 0;
    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT IF(usertype = 'reseller', 1, 0) FROM users WHERE id = %d\n", user_id);

    if (mor_mysql_query_multi(sqlcmd, &connection)) {
        exit(1);
    }

    result = mysql_store_result(&mysql_multi[connection]);
    mysql_connections[connection] = 0;

    if (result) {
        while (( row = mysql_fetch_row(result) )) {
            if (row[0]) {
                if (atoi(row[0]) == 1) {
                    mysql_free_result(result);
                    return 1;
                }
            }
        }

        mysql_free_result(result);

    }

    return 0;

}

int belongs_to_reseller(int user_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    int connection = 0;
    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT owner_id FROM users WHERE id = %d\n", user_id);

    if (mor_mysql_query_multi(sqlcmd, &connection)) {
        exit(1);
    }

    result = mysql_store_result(&mysql_multi[connection]);
    mysql_connections[connection] = 0;

    if (result) {
        while (( row = mysql_fetch_row(result) )) {
            if (row[0]) {
                if (atoi(row[0]) > 0) {
                    mysql_free_result(result);
                    return 1;
                }
            }
        }

        mysql_free_result(result);

    }

    return 0;

}
