#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mysql/mysql.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <signal.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <inttypes.h>

#define CACHED_TIME_PERIODS_COUNT   48
#define INSERT_UPDATE_SIZE          50
#define INSERT_UPDATE_BUFFER_SIZE   INSERT_UPDATE_SIZE * 256 + 1024
#define VARIATIONS                  11

#define INSERT_UPDATE_BEGINNING_SQL "INSERT INTO aggregates(uniqueid,user_id,user_billed,user_billed_billsec,terminator_id,terminator_billed,terminator_billed_billsec,billsec,real_billsec,answered_calls,total_calls,prefix,variation,direction,destination,total_calls_for_user,time_period_id,user_billed_with_tax) VALUES "
#define INSERT_UPDATE_ENDING_SQL    "ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),user_billed=VALUES(user_billed)+user_billed,user_billed_billsec=VALUES(user_billed_billsec)+user_billed_billsec,terminator_id=VALUES(terminator_id),terminator_billed=VALUES(terminator_billed)+terminator_billed,terminator_billed_billsec=VALUES(terminator_billed_billsec)+terminator_billed_billsec,billsec=VALUES(billsec)+billsec,real_billsec=VALUES(real_billsec)+real_billsec,answered_calls=VALUES(answered_calls)+answered_calls,total_calls=VALUES(total_calls)+total_calls,prefix=VALUES(prefix),variation=VALUES(variation),direction=VALUES(direction),destination=VALUES(destination),total_calls_for_user=VALUES(total_calls_for_user)+total_calls_for_user,time_period_id=VALUES(time_period_id),user_billed_with_tax=VALUES(user_billed_with_tax)+user_billed_with_tax"

// data from calls table
typedef struct calls_data_struct {
    uint64_t id;
    int user_id;
    long int user_billsec;
    double user_price;
    double user_price_with_tax;
    int terminator_id;
    int direction_id;
    char direction_name[256];
    char destination[256];
    long int terminator_billsec;
    double terminator_price;
    unsigned char answered;
    double real_billsec;
    long int billsec;
    char prefix[32];
    int destination_id;
    int user_call;
    int activecalls;
    char calldate[20];
    int src_user_id;
    int dst_user_id;
    char uniqueid[64];
    char desttype[64];
    uint64_t time_period_hour_id;
    uint64_t time_period_day_id;
    uint64_t time_period_month_id;
} calls_data_t;

typedef struct thread_args_struct {
    int count;
    int type;
    calls_data_t *calls;
} thread_args_t;

typedef struct time_periods_struct {
    char date[20];
    uint64_t last_call_id;
    int full_aggregate;
    int cached_period_index;
} time_periods_t;

typedef struct cached_time_periods_struct {
    char from_date[20];
    uint64_t hour_id;
    uint64_t day_id;
    uint64_t month_id;
} cached_time_periods_t;

cached_time_periods_t cached_time_periods[CACHED_TIME_PERIODS_COUNT];
int cached_time_periods_count = 0;

// last calls
unsigned long int calls_data_count = 0;
calls_data_t *calls_data = NULL;

// time periods from database
time_periods_t *time_periods = NULL;
uint64_t time_periods_count = 0;

// time periods wich need to be aggregated
time_periods_t *missing_time_periods = NULL;
uint64_t missing_time_periods_count = 0;

// last call ID
uint64_t last_call_id = 0;

// time periods
uint64_t time_period_hour_id = 0;
uint64_t time_period_day_id = 0;
uint64_t time_period_month_id = 0;
char last_calldate[20] = "";

// get last call id and date when aggregate stopped in this hour
// we will continue aggregate from this call id
// if aggregate stopped earlier than this hour, then another script should
// aggregate missing data
char aggregate_stopped_at_calldate[20] = "";
uint64_t aggregate_stopped_at_callid = 0;
char oldest_calldate[20] = "";
char oldest_time_period[20] = "";
char aggregate_till[20] = "";

// bacthes
char insert_update_query[INSERT_UPDATE_BUFFER_SIZE] = "";
char insert_update_values_query[INSERT_UPDATE_BUFFER_SIZE] = "";
int batch_count = 0;

// mutex to handle global write to mysql buffer
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

uint64_t total_calls = 0;
uint64_t current_calls = 0;
uint64_t current_aggregates = 0;

// FUNCTION DECLARATIONS

int mor_update_aggregated_data();
void mor_aggregate_sql_format(int o_id, double o_price, long int o_billsec, int t_id, double t_price, long int t_billsec, long int billsec, double real_billsec, int answered, char *prefix, char *direction, int direction_id, char *destination, int calls_count, int user_calls_count, int type, uint64_t tphid, uint64_t tpdid, uint64_t tpmid, double o_price_tax);
void *mor_aggregate(void *args);
uint64_t mor_get_time_period_id(int type, char *calldate);
void mor_mark_finished_time_period();
