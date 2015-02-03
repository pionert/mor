// Author:      Ricardas Stoma
// Company:     Kolmisoft
// Year:        2012
// About:       Script sends email using MOR API (http://wiki.kolmisoft.com/index.php/MOR_API_send_email_api)

// Arguments:
//      --auth_user_id          ID of user who is sending email (required)
//      --email_name            Email template name (required)
//      --email_to_user_id      User ID which will receive email. If parameter is not supplied email is sent to user authorized with parameters --u and --p
//      --xxxxx                 Here xxxxx is any email template variable        

// Usage:
//      mor_send_email_api --auth_user_id 0 --email_to_user_id 142 --email_name registration_confirmation_for_user --server_ip 127.0.0.2

// Returns:
//      0 - success
//      1 - error

#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include <getopt.h>
#include <mysql/mysql.h>

#define NUMOPTS        35
#define REQUIRED       2
#define ASTCONFPATH    "/var/lib/asterisk/agi-bin/mor.conf"
#define GUICONFPATH    "/home/mor/config/environment.rb"

typedef struct {
    char web_url[32];
    char web_dir[32];
    char web_url_from_db[32];
    char username[32];
    char secret[32];
} conf_t;

int  db_connect(MYSQL *mysql, const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag);
void add_variable(struct option *l_options, char *list[NUMOPTS], const char *namearg, const char *optarg);
void construct_strings(struct option *l_options, char *list[NUMOPTS], char *str_hash, char *str_curl, char secret[64], char *username);
void fetch_from_db(MYSQL *mysql, char *sql_query, char *dst, char *error);
void parse_conf(conf_t *conf, int auth_user_id);
char *str_replace(char *orig, char *rep, char *with);

int main(int argc, char *argv[]) {
    char curl_host[32] = "http://localhost";
    char c, sha1[41];
    char *sorted_options[NUMOPTS] = { 0 };
    char *hash_string;
    char *curl_string;
    char *encoded_curl_string;
    char *shell_string;
    int i, check_sum = 0;
    int hash_string_len = 0, curl_string_len = 0;

    CURL *curl;
    CURLcode res = -1;

    conf_t conf;

    // email template variables
    struct option long_options[] = {
        { "user_id",                     required_argument, 0, 0 },
        { "balance",                     required_argument, 0, 0 },
        { "email",                       required_argument, 0, 0 },
        { "description",                 required_argument, 0, 0 },
        { "amount",                      required_argument, 0, 0 },
        { "server_ip",                   required_argument, 0, 0 },
        { "device_type",                 required_argument, 0, 0 },
        { "device_username",             required_argument, 0, 0 },
        { "device_password",             required_argument, 0, 0 },
        { "login_url",                   required_argument, 0, 0 },
        { "login_username",              required_argument, 0, 0 },
        { "username",                    required_argument, 0, 0 },
        { "first_name",                  required_argument, 0, 0 },
        { "last_name",                   required_argument, 0, 0 },
        { "full_name",                   required_argument, 0, 0 },
        { "nice_balance",                required_argument, 0, 0 },
        { "warning_email_balance",       required_argument, 0, 0 },
        { "nice_warning_email_balance",  required_argument, 0, 0 },
        { "currency",                    required_argument, 0, 0 },
        { "user_email",                  required_argument, 0, 0 },
        { "company_email",               required_argument, 0, 0 },
        { "company",                     required_argument, 0, 0 },
        { "primary_device_pin",          required_argument, 0, 0 },
        { "login_password",              required_argument, 0, 0 },
        { "user_ip",                     required_argument, 0, 0 },
        { "date",                        required_argument, 0, 0 },
        { "auth_code",                   required_argument, 0, 0 },
        { "transaction_id",              required_argument, 0, 0 },
        { "customer_name",               required_argument, 0, 0 },
        { "cc_purchase_details",         required_argument, 0, 0 },
        { "email_name",                  required_argument, 0, 0 }, // required
        { "email_to_user_id",            required_argument, 0, 0 },
        { "caller_id",                   required_argument, 0, 0 },
        { "device_id",                   required_argument, 0, 0 },
        { "auth_user_id",                required_argument, 0, 0 }, // required
        { 0, 0, 0, 0 }
    };

    // parse arguments
    while(1) {
        int option_index = 0;

        c = getopt_long(argc, argv, "", long_options, &option_index);
        
        if(c == -1) break;

        switch(c) {
            case 0:
                // check for required arguments
                if(strcmp(long_options[option_index].name, "auth_user_id") == 0) check_sum++;
                if(strcmp(long_options[option_index].name, "email_name") == 0) check_sum++;
                // add template variable to list
                add_variable(long_options, sorted_options, long_options[option_index].name, optarg);
                break;
            default:
                return 1;
        }
    }

    if(check_sum < REQUIRED) {
        printf("User ID or email name is missing\n");
        return 1;
    }

    // atoi(sorted_options[NUMOPTS - 1]) <--- auth_user_id
    parse_conf(&conf, atoi(sorted_options[NUMOPTS - 1]));

    // calculate memory space for HASH and CURL request strings
    for(i = 0; i < NUMOPTS; i++) {
        if(sorted_options[i] != NULL) {
            hash_string_len += strlen(sorted_options[i]);
            curl_string_len += strlen(long_options[i].name) + strlen(sorted_options[i]) + 2;
        }
    }

    hash_string_len += strlen(conf.secret) + 1; // add additional space for secret key
    curl_string_len += 64;                        // add additional space for hash

    hash_string = (char *)malloc(hash_string_len*sizeof(char));
    curl_string = (char *)malloc(curl_string_len*sizeof(char));

    *hash_string = '\0';
    *curl_string = '\0';

    // construct HASH and CURL strings from parsed template variables
    construct_strings(long_options, sorted_options, hash_string, curl_string, conf.secret, conf.username);

    // generate SHA1
    shell_string = (char *)malloc((hash_string_len + 164)*sizeof(char));
    sprintf(shell_string, "echo -n \"%s\" | sha1sum -t | awk '{print $1}'", hash_string);

    FILE *poutput = popen(shell_string, "r");
    fgets(sha1, 41, poutput);
    pclose(poutput);

    if(strlen(sha1) < 40) {
        printf("Cannot generate sha1 hash\n");
        return 1;
    }

    strcat(curl_string, sha1);


    // encode curl string
    encoded_curl_string = malloc((curl_string_len + 600)*sizeof(char));
    encoded_curl_string = str_replace(curl_string, " ", "%20"); // encode space character

    if (encoded_curl_string != NULL) {
        if (!strstr(" ", encoded_curl_string)) {
            encoded_curl_string = malloc((curl_string_len + 600)*sizeof(char));
            strcpy(encoded_curl_string, curl_string);
        }
    } else {
        encoded_curl_string = malloc((curl_string_len + 600)*sizeof(char));
        strcpy(encoded_curl_string, curl_string);
    }

    // store cURL response in a temporary file (will be deleted automatically)
    FILE *curl_resp = tmpfile();

    int curl_retry = -1;

    // send cURL request
    while(res != CURLE_OK) {
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();

        if(curl) {
            char host[256] = "";
            
            if (curl_retry < 2) {
                sprintf(host, "%s%s/api/email_send?", curl_host, conf.web_dir);
            } else {
                strcpy(host, curl_host);
            }

            if (curl_retry == -1) sprintf(host, "http://localhost/billing/api/email_send?");

            // printf("\n%s%s\n", host, encoded_curl_string);

            curl_easy_setopt(curl, CURLOPT_URL, host);

            if(encoded_curl_string) {
                curl_easy_setopt(curl, CURLOPT_POSTFIELDS, encoded_curl_string);
            } else {
                curl_easy_setopt(curl, CURLOPT_POSTFIELDS, curl_string);
            }

            curl_easy_setopt(curl, CURLOPT_WRITEDATA, curl_resp);
            
            res = curl_easy_perform(curl);
            if(res != CURLE_OK) {

                if(curl_retry == 0) {
                    strcpy(curl_host, conf.web_url);
                } else if(curl_retry == 1) {
                    sprintf(curl_host, "http://%s", conf.web_url_from_db);
                } else {
                    printf("cURL cannot resolve hostname\n");
                    return 1;
                }

                curl_retry++;
                printf("cURL retry request using hostname: %s\n", curl_host);
            }
        } else {
            printf("Cannot initiate cURL\n");
            return 1;
        }

        curl_easy_cleanup(curl);
        curl_global_cleanup();
    }

    char resp_buffer[1024] = { 0 };
    int curl_resp_code = 1;

    fseek(curl_resp, 0L, SEEK_SET);

    // find if email was sent successfully
    while(fscanf(curl_resp, "%s", resp_buffer) != EOF) {
        if(strcmp(resp_buffer, "sent</email_sending_status>") == 0) curl_resp_code = 0;
    }

    // print reason why email was not sent successfully
    if(curl_resp_code) {
        fseek(curl_resp, 0L, SEEK_SET);
        while(fscanf(curl_resp, "%s", resp_buffer) != EOF) {
            printf("%s", resp_buffer);
        }
    }
    
    fclose(curl_resp);
    free(shell_string);
    free(curl_string);
    free(encoded_curl_string);
    free(hash_string);

    for(i = 0; i < NUMOPTS; i++) {
        free(sorted_options[i]);
    }

    return curl_resp_code;
}


void add_variable(struct option *l_options, char *list[NUMOPTS], const char *namearg, const char *optarg) {
    if(strlen(optarg) > 0) {
        int index;

        // find index of parsed template variable
        for(index = 0; index < NUMOPTS; index++) {
            if(strcmp(namearg, l_options[index].name) == 0) {
                break;
            }
        }

        list[index] = (char *)malloc(strlen(optarg)*sizeof(char));
        if(list[index] == NULL) {
            printf("Cannot allocate memory\n");
            exit(1);
        }

        strcpy(list[index], optarg);
    } else {
        printf("Argument cannot be an empty string\n");
        exit(1);
    }
}

void parse_conf(conf_t *conf, int auth_user_id) {
    MYSQL mysql;

    char mysql_host[32];
    char mysql_user[32];
    char mysql_password[32];
    char mysql_db[32];

    char var[64];
    char val[64];

    // parse database configuration
    FILE *file = fopen(ASTCONFPATH, "r");

    if(file == NULL) {
        printf("Cannot open MOR configuration file %s\n", ASTCONFPATH);
        exit(1);
    }

    while(fscanf(file, "%s = %s", var, val) != EOF) {
        if(strcmp(var, "host") == 0) strcpy(mysql_host, val);
        if(strcmp(var, "db") == 0) strcpy(mysql_db, val);
        if(strcmp(var, "user") == 0) strcpy(mysql_user, val);
        if(strcmp(var, "secret") == 0) strcpy(mysql_password, val);
    }

    fclose(file);

    // get GUI url
    file = fopen(GUICONFPATH, "r");

    if(file == NULL) {
        printf("Cannot open MOR configuration file %s\n", GUICONFPATH);
        exit(1);
    }

    memset(val, 0, 64);

    while(fscanf(file, "%s = %s", var, val) != EOF) {
        if(strcmp(var, "Web_Dir") == 0) strcpy(conf->web_dir, val);
        if(strcmp(var, "Web_URL") == 0) strcpy(conf->web_url, val);
    }

    // remove quotes
    strncpy(conf->web_url, conf->web_url + 1, strlen(conf->web_url) - 2);
    strncpy(conf->web_dir, conf->web_dir + 1, strlen(conf->web_dir) - 2);
    conf->web_url[strlen(conf->web_url) - 2] = 0;
    conf->web_dir[strlen(conf->web_dir) - 2] = 0;

    fclose(file);

    if(db_connect(&mysql, mysql_host, mysql_user, mysql_password, mysql_db, 0, NULL, 0) == 1) {
        printf("Cannot connect to databse\n");
        exit(1);
    }

    // get API_Secret_Key from database
    fetch_from_db(&mysql, "SELECT value FROM conflines WHERE name='API_Secret_key';", conf->secret, "Cannot fetch API secret key from database");
    if(strlen(conf->secret) < 1) {
        printf("API secret key is empty\n");
        exit(1);
    }

    // get host name
    fetch_from_db(&mysql, "SELECT hostname FROM servers;", conf->web_url_from_db, "Cannot fetch hostname from database");

    // get username
    char sql_query[64];
    sprintf(sql_query, "SELECT username FROM users WHERE id=%d;", auth_user_id);
    fetch_from_db(&mysql, sql_query, conf->username, "Cannot fetch username from database");
 
    mysql_close(&mysql);
}

void construct_strings(struct option *l_options, char *list[NUMOPTS], char *str_hash, char *str_curl, char secret[64], char *username) {
    int i;

    for(i = 0; i < NUMOPTS; i++) {
        if(list[i] != NULL) {
            // --auth_user_id is not included in the hash string
            if(strcmp(l_options[i].name, "auth_user_id") != 0) {
                strcat(str_hash, list[i]);
                sprintf(str_curl, "%s%s=%s&", str_curl, l_options[i].name, list[i]);
            } else {
                sprintf(str_curl, "%su=%s&", str_curl, username);
            }
        }
    }

    strcat(str_hash, secret);
    strcat(str_curl, "hash=");
}

int db_connect(MYSQL *mysql, const char *host, const char *user, const char *pass, const char *db, unsigned int port, const char *socket, unsigned long cflag) {
    
    if(!mysql_init(mysql)) {
        printf("MySQL error: %s", mysql_error(mysql));
        return 1;
    }

    if(!mysql_real_connect(mysql, host, user, pass, db, port, socket, cflag)) {
        printf("MySQL error: %s", mysql_error(mysql));
        return 1;
    }

    return 0;
}

void fetch_from_db(MYSQL *mysql, char *sql_query, char *dst, char *error) {
    MYSQL_RES *res_set;
    MYSQL_ROW row;

    if(mysql_query(mysql, sql_query)) {
        printf("MySQL query cannot be sent to database: %s\n", mysql_error(mysql));
    } else {
        res_set = mysql_store_result(mysql);
        if(res_set == NULL) {
            printf("Cannot fetch data from database\n");
            exit(1);
        } else {
            if(mysql_field_count(mysql) > 0) {
                if((row = mysql_fetch_row(res_set)) != NULL) {
                    strcpy(dst, row[0]);
                    mysql_free_result(res_set);
                } else {
                    printf("%s\n", error);
                    exit(1);
                }
            } else {
                printf("%s\n", error);
                exit(1);
            }
        }
    }
}

char *str_replace(char *orig, char *rep, char *with) {
    char *result;  // the return string
    char *ins;     // the next insert point
    char *tmp;     // varies
    int len_rep;   // length of rep
    int len_with;  // length of with
    int len_front; // distance between rep and end of last rep
    int count;     // number of replacements

    if (!orig)
        return NULL;
    if (!rep || !(len_rep = strlen(rep)))
        return NULL;
    if (!(ins = strstr(orig, rep))) 
        return NULL;
    if (!with)
        with = "";
    len_with = strlen(with);

    for (count = 0; (tmp = strstr(ins, rep)); ++count) {
        ins = tmp + len_rep;
    }

    tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);

    if (!result)
        return NULL;

    while (count--) {
        ins = strstr(orig, rep);
        len_front = ins - orig;
        tmp = strncpy(tmp, orig, len_front) + len_front;
        tmp = strcpy(tmp, with) + len_with;
        orig += len_front + len_rep; // move to next "end of rep"
    }
    strcpy(tmp, orig);
    
    return result;
}
