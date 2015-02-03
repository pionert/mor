typedef struct users_struct {
    int id;
    char name[256];
    double exchange_rate;
    char currency[256];
    char timezone[256];
    float timezone_offset;
    char server_period_start[20];
    char server_period_end[20];
    char user_date[20];
    char address[256];
    char city[256];
    char postcode[256];
    char state[256];
    char phone[256];
    char invoice_number[256];
    int direction_id;
    int tax_id;
    int postpaid;
    int owner_id;
    int tax_compound;
    int tax1;
    int tax2;
    int tax3;
    int tax4;
    double tax1_value;
    double tax2_value;
    double tax3_value;
    double tax4_value;
    int precision;
    int number_type;
    long long int invoice_id;
    int  skip;
} users_t;

users_t *users = NULL;
int users_count = 0;

typedef struct invoice_details {
    double price;
    double price_with_tax;
    int billsec;
    char prefix[128];
    int user_id;
    int units;
    char service[256];
    int invdet_type;
} invoice_details_t;

invoice_details_t *invoice_details = NULL;
int invoice_details_count = 0;

typedef struct timezones_struct {
    char zone[256];
    float offset;
} timezones_t;

timezones_t tz[34];
int tz_count = 34;

float server_offset = 0;

typedef struct invoices {
    int user_id;
    long long int id;
    char period_start[20];
    char period_end[20];
    char invoice_number[256];
    char invoice_currency[10];
    char date_from[20];
    char date_till[20];
    char issue_date[20];
} invoices_t;

invoices_t *invoices = NULL;
int invoices_count = 0;

invoices_t *recalculate_invoices = NULL;
int recalculate_invoices_count = 0;

// invoice settings
typedef struct invoice_settings_struct {
    int invoice_number_type;
    int prepaid_invoice_number_type;
    int invoice_number_length;
    int prepaid_invoice_number_length;
    char invoice_number_start[32];
    char prepaid_invoice_number_start[32];
    int owner_id;
    int precision;
} invoice_settings_t;

invoice_settings_t *invoice_settings = NULL;
int invoice_settings_count = 0;

char current_date[20] = "";

int user_id = 0;
char date_from[20] = "";
char date_from_date_only[20] = "";
char date_till[20] = "";
char date_till_date_only[20] = "";
char issue_date[20] = "";
char user_type[64] = "";
char currency[10] = "";
double exchange_rate = 0;
int owner_id = 0;
int recalculate = 0;

int task_failed = 1;

// web variables
char web_dir[256] = "";
char web_url[256] = "";

int get_users_data(int user_id_parameter);
int compare_dates(const char *date1, const char *date2, int mode);
int check_completed_invoices();
int insert_new_invoices(int index);
void get_server_gmt_offset();
int get_invoice_data();
int insert_invoicedetails(long long int invoice_id);
int get_last_datetime_of_month(char *date, char *buffer, int current_month);
time_t get_timestamp(char *date);
void timestamp_to_string(time_t timestamp, char *date);
void get_time_periods_sql(char *user_start_time, char *user_end_time, char *time_periods_sql);
int get_date_param(char *date, int param);
int get_invoice_settings();
void generate_invoice_number(users_t *user);
void adjust_to_target_time(char *date, char *buffer, float offset, int target);
int calculate_subscription_price(int index, double *total_price, double *total_price_with_tax);
int calculate_did_price(int index, double *total_price, double *total_price_with_tax, int owner);
int calculate_outgoing_calls_price(int index, double *total_price, double *total_price_with_tax);
int calculate_sms_price(int index, double *total_price, double *total_price_with_tax);
int months_between(char *date1, char *date2);
int days_between(char *date1, char *date2);
int get_day(char *date);
void error_handle();
int get_web_config();
int get_recalculate_invoices();
int delete_invoicedetails(long long int invoice_id);
double get_exchange_rate(char *currency);
