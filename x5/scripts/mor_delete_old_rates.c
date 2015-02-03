// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2014
// About:         Script checks effective_from date for all rates and checks if rate is too old and should be deleted


#define SCRIPT_VERSION  "1.0"
#define SCRIPT_NAME     "mor_delete_old_rates"
#define BATCH_SIZE      1000

#include "mor_functions.c"

// FUNCTION DECLARATIONS

int date_diff(const char *date1, const char *date2, int days_old);

// GLOBAL VARIABLES

// how many days is considered to be old rate
int days_old = 0;

typedef struct rates_id_struct {
    long long int id;
} rates_t;

int rates_count = 0;
int total_rates = 0;
rates_t *rates = NULL;

// MAIN FUNCTION

int main(int argc, char *argv[]) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    MYSQL_RES *result1;
    MYSQL_ROW row1;

    char query[2048] = "";
    int i = 0;
    char current_date[20] = "";

    mor_get_current_date(current_date);

    // starting sript
    mor_init("Starting 'Delete old rates' script\n");

    // get 'days old'
    if (mor_mysql_query("SELECT value FROM conflines WHERE name = 'delete_not_actual_rates_after'")) {
        exit(1);
    }

    result1 = mysql_store_result(&mysql);
    if (mysql_num_rows(result1)) {
        while (( row1 = mysql_fetch_row(result1) )) {
            if (row1[0]) days_old = atoi(row1[0]);
        }
    }

    mysql_free_result(result1);

    if (!days_old) {
        mor_log("Days_old = 0. Nothing to do...\n");
        exit(0);
    } else {
        mor_log("Days_old = %d\n", days_old);
    }

    // get id of all tariffs
    if (mor_mysql_query("SELECT id FROM tariffs WHERE purpose != 'user'")) {
        exit(1);
    }

    result1 = mysql_store_result(&mysql);

    if (result1) {
        if (mysql_num_rows(result1)) {
            while (( row1 = mysql_fetch_row(result1) )) {
                if (row1[0]) {

                    char last_prefix[256] = "";
                    int new_prefix = 0;
                    int tariff_id = atoi(row1[0]);

                    sprintf(query, "SELECT prefix, effective_from, rates.id FROM rates "
                                   "JOIN destinations ON destinations.id = rates.destination_id "
                                   "WHERE (effective_from IS NULL OR effective_from < NOW()) "
                                   "AND rates.tariff_id = %d "
                                   "ORDER BY prefix, effective_from DESC", tariff_id);

                    if (mor_mysql_query(query)) {
                        exit(1);
                    }

                    result = mysql_store_result(&mysql);

                    if (result) {
                        if (mysql_num_rows(result)) {
                            while (( row = mysql_fetch_row(result) )) {

                                if (row[0] && row[2]) {

                                    if (strcmp(row[0], last_prefix)) {
                                        new_prefix = 1;
                                    } else {
                                        new_prefix = 0;
                                    }

                                    // skip first rate, because this rate is in use
                                    // if we got more rates for this destination, it means that these rates are not used anymore

                                    if (!new_prefix) {

                                        if (date_diff(current_date, row[1] == NULL ? "1900-01-01 00:00:00" : row[1], days_old)) {
                                            mor_log("This rate should be deleted! Rate_id: %s, effective_from: %s\n", row[2], row[1] == NULL ? "null" : row[1]);
                                            rates = realloc(rates, (rates_count + 1) * sizeof(rates_t));
                                            rates[rates_count].id = atol(row[2]);
                                            rates_count++;
                                            total_rates++;
                                        }

                                    }

                                    strcpy(last_prefix, row[0]);

                                }

                            }
                        }
                    }

                    mysql_free_result(result);

                    // delete old rates

                    int count = 0;
                    char id_buffer[10*BATCH_SIZE] = "";
                    char delete_query[10*BATCH_SIZE+256] = "";
                    for (i = 0; i < rates_count; i++) {
                        char buffer[256] = "";
                        sprintf(buffer, "%lld,", rates[i].id);
                        strcat(id_buffer, buffer);
                        count++;
                        if (count >= BATCH_SIZE || (i == rates_count - 1)) {
                            id_buffer[strlen(id_buffer) - 1] = 0;
                            mor_log("Deleting rates from ratedetails (rate_id: %s)\n", id_buffer);
                            sprintf(delete_query, "DELETE FROM ratedetails WHERE rate_id in (%s)", id_buffer);
                            if (mor_mysql_query(delete_query)) {
                                exit(1);
                            }
                            mor_log("Deleting rates (rate_id: %s)\n", id_buffer);
                            sprintf(delete_query, "DELETE FROM rates WHERE id in (%s)", id_buffer);
                            if (mor_mysql_query(delete_query)) {
                                exit(1);
                            }
                            memset(id_buffer, 0, 10*BATCH_SIZE);
                            count = 0;
                        }

                    }

                    rates_count = 0;

                }
            }
        }
    }

    mysql_free_result(result1);

    // close mysql connection
    mysql_close(&mysql);
    // we will not use mysql, so free other memory used by sql
    mysql_library_end();

    mor_log("Rates deleted: %d\n", total_rates);

    mor_log("Script completed\n");


    return 0;

}


/*

    ############  FUNCTIONS #######################################################

*/


/*
    Date compare function
*/


int date_diff(const char *date1, const char *date2, int days_old) {

    time_t t1, t2;
    struct tm tm1, tm2;
    int diff;

    memset(&tm1, 0, sizeof(struct tm));
    memset(&tm2, 0, sizeof(struct tm));

    strptime(date1, DATE_FORMAT, &tm1);
    strptime(date2, DATE_FORMAT, &tm2);

    t1 = mktime(&tm1);
    t2 = mktime(&tm2);

    diff = difftime(t1, t2)/86400;

    if (diff > days_old) return 1;

    return 0;

}
