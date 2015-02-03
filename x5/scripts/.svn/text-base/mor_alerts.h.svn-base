#define DATA_TICK_TIME          15                                  // get calls every x seoncds
#define DATA_HOLD_PERIOD        86400                               // hold data for x seconds (24 hours in this case)
#define DELETE_OLD_AC_DATA      3600                                // delete old data from active_call_data
#define UPDATE_EMAILS_EVERY     3600                                // update email data every 60min
#define CHECK_IF_UPDATE         30                                  // check if alerts need to be updated every x seconds
#define DATA_PACKETS            DATA_HOLD_PERIOD / DATA_TICK_TIME   // how many data packets will be there?
#define DATA_AGGREGATE_PERIODS  DATA_TICK_TIME / 3                  // aggregate and check data in x seconds periods

typedef unsigned char uchar;
typedef unsigned int uint;

typedef struct schedule_struct {
    char start[9];
    char end[9];
    int daytype;
    struct schedule_struct *prev;
} schedule_t;

typedef struct contact_struct {
    int id;
    char email[64];
    int timezone;
    char number[32];
    struct contact_struct *prev;
} contact_t;

typedef struct group_struct {
    int alert_id;
    char name[64];
    int email_schedule_id;
    int sms_schedule_id;
    schedule_t *schedule;
    contact_t *contact;
} group_t;

typedef struct data_info_struct {
    long int id;
    long int user_id;
    int user_lcr_id;
    int ignore_alert;
    double data_sum;
    double last_data_diff;
    double current_data_diff;
    unsigned long long int data_count;
    unsigned long long int clear_period_counter;
    long long int clear_period_countdown;
    uchar alert_is_set;
    struct data_info_struct *next;
} data_info_t;

// alerts typedef
typedef struct alerts_struct {
    unsigned int id;
    uchar alert_type;
    uchar alert_count_type;
    uchar check_type;
    uchar status;
    uchar action_alert_email;
    uchar action_alert_sms;
    uchar action_alert_disable_object;
    int action_alert_disable_object_in_lcr;
    int action_alert_change_lcr_id;
    uchar action_clear_email;
    uchar action_clear_sms;
    uchar action_clear_enable_object;
    int action_clear_enable_object_in_lcr;
    int action_clear_change_lcr_id;
    int before_alert_original_lcr_id;
    int alert_groups_id;
    double value_at_alert;
    double alert_if_less;
    double alert_if_more;
    double value_at_clear;
    double clear_if_less;
    double clear_if_more;
    long int ignore_if_calls_less;
    long int ignore_if_calls_more;
    char check_data[64];
    int raw_period;
    int period;
    uint64_t clear_period;
    int disable_clear;
    unsigned int diff_counter;
    int owner_id;
    char comment[512];
    char name[256];
    char clear_date[20];
    int notify_to_user;
    int hgc;
    int alert_if_more_than;
    int clear_if_less_than;
    char alert_group_id_list[1024];
    data_info_t *data_info;
    group_t *group;
} alerts_t;

// data from calls table
typedef struct calls_data_struct {
    int user_id;
    int provider_id;
    int device_id;
    int postpaid;
    int all;
    int destinationgroup_id;
    unsigned char answered;
    float pdd;
    long int duration;
    long int billsec;
    float user_price;
    float provider_price;
    int user_sim_calls;
    int prov_sim_calls;
    char prefix[32];
    int user_lcr_id;
    int hgc;
    int ignore_alert;
} calls_data_t;

typedef struct calls_index_struct {
    unsigned long int a_count;
    unsigned long int count;
    unsigned int uniqueid;
} calls_index_t;

typedef struct alerts_tmp_data_struct {
    int id;
    int found;
    data_info_t *addr;
} alerts_tmp_data_t;

typedef struct email_data_struct {
    int owner_id;
    int enabled;
    char server[256];
    char login[256];
    char password[256];
    char from[256];
    int port;
} email_data_t;
