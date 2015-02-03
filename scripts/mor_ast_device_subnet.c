/*
*
*    MOR Asterisk Device Subnet script
*    Copyright Mindaugas Kezys / Kolmisoft 2012
*
*    Script reads DB for CIDR addresses and generates configuration for such devices
*    It allows to have one Device in DB which will represent many IP addresses (by CIDR)
*    CIDR: http://software77.net/cidr-101.html http://en.wikipedia.org/wiki/CIDR_notation
*
*    In addition script also generates configuration for IP ranges like 192.168.0.1-100
*
*    v1.1
*
*    2014-08-07 1.1 IP ranges support
*    2012-07-18 1.0 Initial version only SIP support
*
*/

#include <mysql/mysql.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

/* Defines */

#define DATE_FORMAT "%Y-%m-%d"
#define TIME_FORMAT "%T"
#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S"

/* Structures */

typedef struct device_column_node_def {
    char name[30];
    struct device_column_node_def *next;
} device_column_node;

/* Variables */

char dbhost[40] = "", dbname[20] = "", dbuser[20] = "", dbpass[20] = "";
int dbport = 0;
int calls_one_time = 0, cron_interval = 0;

int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;

int server_id = 1;

static MYSQL mysql;

char device_sql[4096] = "";
char device_range_sql[4096] = "";

device_column_node *node = NULL, *device_column_list_start = NULL, *end_node = NULL;

/* Function declarations */

int generate_sip_device_configuration();
int device_codecs(char *codecs_string, int device_id);
int sql_construct();                                                        /* constructs sql to retrieve device data using all available device table columnd names excluding known-ones using by MOR (no need to put them to asterisk configuration) */
void dynamic_list_free();                                                   /* free memory for dynamic lists */
void whatmask_data_get(char *ip, int *start1, int *end1, int *start2, int *end2, int *start3, int *end3, char *ip_start);       /* get ip start data */

void read_config();
static int mysql_connect();

void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/mor_ast_device_subnet.log","a+");
    fprintf(file,"%s\n",msg);
    fclose(file);
}

void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/mor_ast_device_subnet.log","a+");
    fprintf(file,"%i\n",msg);
    fclose(file);
}

/* Main function */

int main(int argc, char *argv[]) {

    read_config();

    if(!mysql_connect()) return 0;

    generate_sip_device_configuration();
    // generate_sip_extensions();

    dynamic_list_free();
    mysql_close(&mysql);

    return 0;
}

/* Functions */

/*  Retrieve start-end values for whatmask data for IP

    yum -y install whatmask
    download_packet whatmask-1.2-1.i386.rpm
    rpm -Uvh whatmask-1.2-1.i386.rpm

    whatmask 192.168.0.12/29 | grep "First Usable IP Address" | awk -F: '{print $2}' | awk -F. '{print $4}'
    whatmask 192.168.0.12/29 | grep "Last Usable IP Address" | awk -F: '{print $2}' | awk -F. '{print $4}'
    whatmask 192.168.0.12/29 | grep "First Usable IP Address" | awk -F: '{ split($2,a,"."); print a[1]"."a[2]"."a[3]"."; }'
*/

void whatmask_data_get(char *ip, int *start1, int *end1, int *start2, int *end2, int *start3, int *end3, char *ip_start){

    FILE *FP;
    char buff[1024] = "", cmd[1024] = "";
    int len = 0;

    // get xxx.XXX.xxx.xxx start

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"First Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[2]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *start1 = atoi(buff);
    }
    pclose(FP);

    // get xxx.XXX.xxx.xxx end

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"Last Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[2]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *end1 = atoi(buff);
    }
    pclose(FP);

    // get xxx.xxx.XXX.xxx start

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"First Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[3]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *start2 = atoi(buff);
    }
    pclose(FP);

    // get xxx.xxx.XXX.xxx end

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"Last Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[3]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *end2 = atoi(buff);
    }
    pclose(FP);

    // get xxx.xxx.xxx.XXX start

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"First Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[4]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *start3 = atoi(buff);
    }
    pclose(FP);

    // get xxx.xxx.xxx.XXX end

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"Last Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[4]; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        *end3 = atoi(buff);
    }
    pclose(FP);

    /* get ip start, first 2 numbers: xxx.xxx */

    sprintf(cmd, "whatmask %s 2> /dev/null | grep \"Last Usable IP Address\" | awk -F: '{ split($2,a,\".\"); print a[1]\".\"; }' | sed \"s| ||g\"", ip);

    FP = popen(cmd, "r");
    while(fgets(buff,1024,FP)) {
    len = strlen(buff);
        if(buff[len - 1] == '\n')
            buff[len - 1] = '\0';
        strcpy(ip_start, buff);
    }
    pclose(FP);

    if(strcmp(ip_start, "<none>.") == 0) {
        exit(1);
    }

    if(strlen(ip_start) == 0)
        exit(1);
}

int generate_sip_device_configuration() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    int i, j, k, l;
    int device_id = 0;

    char codecs_string[2048] = "";
    char buff[2048];

    int ip_start1, ip_end1, ip_start2, ip_end2, ip_start3, ip_end3;
    char ip_start_octets[50] = "";

    sql_construct();

    if (mysql_query(&mysql, device_sql)) {
        return 1;
    } else {
        result = mysql_store_result(&mysql);
        if (result) {

            sprintf(buff, "\n; =========== MOR SIP Device with subnet configuration ============\n");
            printf(buff);

            node = device_column_list_start;
            while ((row = mysql_fetch_row(result))) {

                whatmask_data_get(row[3], &ip_start1, &ip_end1, &ip_start2, &ip_end2, &ip_start3, &ip_end3, ip_start_octets);

                // make Asterisk configuration
                for (j = ip_start1; j <= ip_end1; j++) {
                    for (k = ip_start2; k <= ip_end2; k++) {

                        int ip_startl = 0;
                        int ip_endl = 255;

                        if (j == ip_start1 && k == ip_start2) {
                            ip_startl = ip_start3;
                        }

                        if (j == ip_end1 && k == ip_end2) {
                            ip_endl = ip_end3;
                        }

                        for (l = ip_startl; l <= ip_endl; l++) {
                            char tmp_buffer[128] = "";
                            sprintf(tmp_buffer, "%s%d.%d.%d", ip_start_octets, j, k, l);
                            strcpy(buff, "");
                            sprintf(buff, "\n;Device id: %s\n[mor_device_%s]\nname=mor_device_%s\ntype=friend\naccountcode=%s\nipaddr=%s\nhost=%s\n", row[0], tmp_buffer, tmp_buffer, row[1], tmp_buffer, tmp_buffer);

                            node = device_column_list_start;
                            i = 0;
                            while (node) {
                                if ((row[i + 4]) && (strlen(row[i + 4]))) {
                                    sprintf(buff, "%s%s=%s\n", buff, node->name, row[i + 4]);
                                }
                                node = node->next;
                                i++;
                            }

                            if (row[1]) {
                                device_id = atoi(row[1]);
                            } else {
                                device_id = 0;
                            }

                            device_codecs(codecs_string, device_id);
                            sprintf(buff, "%s%s", buff, codecs_string);

                            // output to asterisk
                            printf(buff);
                        }
                    }
                }
            }
            mysql_free_result(result);
        }
    }

    // handle device ranges

    if (mysql_query(&mysql, device_range_sql)) {
        return 1;
    } else {
        result = mysql_store_result(&mysql);
        if (result) {

            sprintf(buff, "\n; =========== MOR SIP Device with IP range configuration ============\n");
            printf(buff);

            node = device_column_list_start;
            while ((row = mysql_fetch_row(result))) {

                int end_range = -1;
                int start_range = -1;

                char *ptr_start = NULL;
                char *ptr_end = NULL;

                if (row[3] == NULL) {
                    continue;
                }

                char ipaddr[256] = "";
                strcpy(ipaddr, row[3]);

                ptr_start = strrchr(ipaddr, '.');
                ptr_end = strchr(ipaddr, '-');

                if (ptr_start == NULL || ptr_end == NULL) {
                    continue;
                }

                if (strlen(ptr_start) <= strlen(ptr_end)) {
                    continue;
                }

                end_range = atoi(ptr_end + 1);
                *ptr_end = '\0';
                start_range = atoi(ptr_start + 1);

                if (start_range == -1 || end_range == -1) {
                    continue;
                }

                strcpy(ip_start_octets, row[3]);
                ptr_start = strrchr(ip_start_octets, '.');

                if (ptr_start == NULL) {
                    continue;
                }

                *ptr_start = '\0';

                for (j = start_range; j <= end_range; j++) {

                    char tmp_buffer[128] = "";
                    sprintf(tmp_buffer, "%s.%d", ip_start_octets, j);
                    strcpy(buff, "");
                    sprintf(buff, "\n;Device id: %s\n[mor_device_%s]\nname=mor_device_%s\ntype=friend\naccountcode=%s\nipaddr=%s\nhost=%s\n", row[0], tmp_buffer, tmp_buffer, row[1], tmp_buffer, tmp_buffer);

                    node = device_column_list_start;
                    i = 0;
                    while (node) {
                        if ((row[i + 4]) && (strlen(row[i + 4]))) {
                            sprintf(buff, "%s%s=%s\n", buff, node->name, row[i + 4]);
                        }
                        node = node->next;
                        i++;
                    }

                    if (row[1]) {
                        device_id = atoi(row[1]);
                    } else {
                        device_id = 0;
                    }

                    device_codecs(codecs_string, device_id);
                    sprintf(buff, "%s%s", buff, codecs_string);

                    // output to asterisk
                    printf(buff);
                }
            }
            mysql_free_result(result);
        }
    }

    return 0;
}

/* construct sql to retrieve device data */
/* use all available columns from devices table, exclude known columns, not used by Asterisk (MOR custom fields) */

int sql_construct(){

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";
    int i;

    sprintf(device_sql, "SELECT id, accountcode, allow, ipaddr");
    sprintf(device_range_sql, "SELECT id, accountcode, allow, ipaddr");

    strcpy(sqlcmd, "SELECT column_name FROM information_schema.columns WHERE table_name = 'devices' GROUP BY column_name ORDER BY 'ordinal_position';");

    if (mysql_query(&mysql, sqlcmd)) {
        // printf("%s\n", mysql_error(&mysql));
        return 1;
    } else { // query succeeded, process any data returned by it
        result = mysql_store_result(&mysql);
        if(result) {  // there are rows
            i = 0;
            while ((row = mysql_fetch_row(result))) {
                /* exceptions */
                if (!strcmp(row[0], "id")) {}
                else if (!strcmp(row[0], "accountcode")) {}
                else if (!strcmp(row[0], "allow")) {}
                else if (!strcmp(row[0], "ipaddr")) {}
                else if (!strcmp(row[0], "host")) {}
                else if (!strcmp(row[0], "allow_duplicate_calls")) {}
                else if (!strcmp(row[0], "amaflags")) {}
                else if (!strcmp(row[0], "ani")) {}
                else if (!strcmp(row[0], "anti_resale_auto_answer")) {}
                else if (!strcmp(row[0], "block_callerid")) {}
                else if (!strcmp(row[0], "callerid_advanced_control")) {}
                else if (!strcmp(row[0], "call_limit")) {}
                else if (!strcmp(row[0], "change_failed_code_to")) {}
                else if (!strcmp(row[0], "cid_from_dids")) {}
                else if (!strcmp(row[0], "cid_number")) {}
                else if (!strcmp(row[0], "control_callerid_by_cids")) {}
                else if (!strcmp(row[0], "description")) {}
                else if (!strcmp(row[0], "devicegroup_id")) {}
                else if (!strcmp(row[0], "device_type")) {}
                else if (!strcmp(row[0], "disallow")) {}
                else if (!strcmp(row[0], "fake_ring")) {}
                else if (!strcmp(row[0], "faststart")) {}
                else if (!strcmp(row[0], "forward_did_id")) {}
                else if (!strcmp(row[0], "forward_to")) {}
                else if (!strcmp(row[0], "grace_time")) {}
                else if (!strcmp(row[0], "h245tunneling")) {}
                else if (!strcmp(row[0], "istrunk")) {}
                else if (!strcmp(row[0], "latency")) {}
                else if (!strcmp(row[0], "location_id")) {}
                else if (!strcmp(row[0], "max_timeout")) {}
                else if (!strcmp(row[0], "pin")) {}
                else if (!strcmp(row[0], "primary_did_id")) {}
                else if (!strcmp(row[0], "process_sipchaninfo")) {}
                else if (!strcmp(row[0], "qf_tell_balance")) {}
                else if (!strcmp(row[0], "qf_tell_time")) {}
                else if (!strcmp(row[0], "record")) {}
                else if (!strcmp(row[0], "recording_email")) {}
                else if (!strcmp(row[0], "recording_keep")) {}
                else if (!strcmp(row[0], "recording_to_email")) {}
                else if (!strcmp(row[0], "record_forced")) {}
                else if (!strcmp(row[0], "repeat_rtime_every")) {}
                else if (!strcmp(row[0], "save_call_log")) {}
                else if (!strcmp(row[0], "server_id")) {}
                else if (!strcmp(row[0], "tell_balance")) {}
                else if (!strcmp(row[0], "tell_rtime_when_left")) {}
                else if (!strcmp(row[0], "temporary_id")) {}
                else if (!strcmp(row[0], "time_limit_per_day")) {}
                else if (!strcmp(row[0], "user_id")) {}
                else if (!strcmp(row[0], "use_ani_for_cli")) {}
                else if (!strcmp(row[0], "vmexten")) {}
                else if (!strcmp(row[0], "voicemail_active")) {}
                else if (!strcmp(row[0], "works_not_logged")) {}
                else if (!strcmp(row[0], "lastms")) {}
                else if (!strcmp(row[0], "fullcontact")) {}
                else if (!strcmp(row[0], "tell_time")) {}
                else if (!strcmp(row[0], "name")) {}
                else if (!strcmp(row[0], "cps_call_limit")) {}
                else if (!strcmp(row[0], "cps_period")) {}
                else if (!strcmp(row[0], "timerb")) {}
                else if (!strcmp(row[0], "callerid_number_pool_id")) {}
                else if (!strcmp(row[0], "op")) {}
                else if (!strcmp(row[0], "op_active")) {}
                else if (!strcmp(row[0], "op_tariff_id")) {}
                else if (!strcmp(row[0], "op_routing_algorithm")) {}
                else if (!strcmp(row[0], "op_routing_group_id")) {}
                else if (!strcmp(row[0], "op_capacity")) {}
                else if (!strcmp(row[0], "tp")) {}
                else if (!strcmp(row[0], "tp_active")) {}
                else if (!strcmp(row[0], "tp_tariff_id")) {}
                else if (!strcmp(row[0], "tp_capacity")) {}
                else if (!strcmp(row[0], "copy_name_to_number")) {}
                else if (!strcmp(row[0], "tell_rate")) {}
                // else if (!strcmp(row[0], "")) {}
                else {
                    /* after all exceptions lets add this field */
                    sprintf(device_sql, "%s, `%s`", device_sql, row[0]);
                    sprintf(device_range_sql, "%s, `%s`", device_range_sql, row[0]);

                    /* also to the dynamic list */
                    node = (device_column_node *)malloc(sizeof(device_column_node));

                    if(device_column_list_start == NULL) {
                        device_column_list_start = node;
                    }

                    strcpy(node->name, row[0]);
                    node->next = NULL;

                    if(end_node) {
                        end_node->next = node;
                    }
                    end_node = node;
                }

                i++;
            }
            mysql_free_result(result);
        } else { // mysql_store_result() returned nothing; should it have?
            if(mysql_field_count(&mysql) == 0) {

            } else { // mysql_store_result() should have returned data
                // printf("%s\n", mysql_error(&mysql));
                return 1;
            }
        }
    }

    sprintf(device_sql, "%s FROM devices WHERE device_type = 'SIP' AND ipaddr LIKE '%%/%%'", device_sql);
    sprintf(device_range_sql, "%s FROM devices WHERE device_type = 'SIP' AND ipaddr LIKE '%%-%%'", device_range_sql);

    return 0;
}

/* free memory allocated for Dynamic list(s) */

void dynamic_list_free(){

    int i = 0;

    device_column_node *current, *next_node;

    current = device_column_list_start;
    while (current != NULL) {
        next_node = current->next;

        free (current);
        current = next_node;

        i++;
    }

    // printf("\nDevice Column Nodes freed: %i\n", i);
}


int device_codecs(char *codecs_string, int device_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";
    int i;

    char buff[2048] = "disallow=all\n";

    // ================= codecs ==================

    sprintf(sqlcmd,"SELECT codecs.name FROM codecs JOIN devicecodecs ON (devicecodecs.codec_id = codecs.id AND devicecodecs.device_id = %i);", device_id);

    // my_debug(sqlcmd);
    // if(SHOW_SQL) printf("SQL: %s\n", sqlcmd);

    if (mysql_query(&mysql,sqlcmd)) {
        return 1;
    } else { // query succeeded, process any data returned by it
        result = mysql_store_result(&mysql);
        if(result) { // there are rows
            i = 0;
            while((row = mysql_fetch_row(result))) {

                // make Asterisk configuration
                sprintf(buff, "%sallow=%s\n", buff, row[0]);

                // my_debug(buff);

                // make Asterisk extensions.conf configuration

                /*
                sprintf(buff, "");
                if((row[7]) && (strlen(row[7])) ) {
                    sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Set(CALLERID(all)=%s)\nexten => _X.,3,Goto(mor,${EXTEN},1)\n", row[1], row[1], row[7]);
                } else {
                    sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Goto(mor,${EXTEN},1)\n", row[1], row[1]);
                }
                */

                // fprintf(file,"%s\n",buff);

                // my_debug(buff);

                // printf("register => test:test@212.59.21.2:5060/1244\n");

                // if(DEBUG) printf("Campaign id: %i, name: %s, type: %s, status: %s, time: %s-%s, retries: %i, r.time: %i, wait: %i, usrid: %i, devid: %i, numbers: %i\n", campaigns[i].id, campaigns[i].name, campaigns[i].campaign_type, campaigns[i].status, campaigns[i].start_time, campaigns[i].stop_time, campaigns[i].max_retries, campaigns[i].retry_times, campaigns[i].wait_time, campaigns[i].user_id, campaigns[i].device_id, campaigns[i].active_numbers);

                i++;
            }
            mysql_free_result(result);
        } else { // mysql_store_result() returned nothing; should it have?
            if(mysql_field_count(&mysql) == 0) {

            } else {
                return 1;
            }
        }
    }

    strcpy(codecs_string, buff);

    return 0;
}

void read_config() {
    FILE    *file;
    char var[200], val[200];

    file = fopen("/var/lib/asterisk/agi-bin/mor.conf", "r");

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;

    calls_one_time = 20;
    cron_interval  = 10;

    /* Read values from conf file */
    while (fscanf(file, "%s = %s", var, val) != EOF) {

        if (!strcmp(var, "host")) {
            strcpy(dbhost, val);
        } else {
        if (!strcmp(var, "db")) {
            strcpy(dbname, val);
        } else {
        if (!strcmp(var, "user")) {
            strcpy(dbuser, val);
        } else  {
        if (!strcmp(var, "secret")) {
            strcpy(dbpass, val);
        } else {
        if (!strcmp(var, "port")) {
            dbport = atoi(val);
        } else {
        if (!strcmp(var, "show_sql")) {
            SHOW_SQL = atoi(val);
        } else {
        if (!strcmp(var, "debug")) {
            DEBUG = atoi(val);
        } else {
        if (!strcmp(var, "server_id")) {
            server_id = atoi(val);
        } else {
        } } } } } } } }

    }

    fclose(file);

    // if(DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %i, SHOW_SQL: %i, DEBUG: %i, server_id\n", dbhost, dbname, dbuser, dbpass, dbport, SHOW_SQL, DEBUG);
}

static int mysql_connect() {
    char my_database[50];
    char error[512];

    strcpy(my_database, dbname);

    if (strlen(dbhost) && strlen(dbuser) && strlen(dbpass) && strlen(my_database)) {
        if(!mysql_init(&mysql)) {
            my_debug("Insufficient memory to allocate MySQL resource.\n");
            return 0;
        }

        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, my_database, dbport, NULL, 0)) {
            // if(DEBUG) printf("Successfully connected to database.\n");
            return 1;
        } else {
            sprintf(error, "Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
            sprintf(error, "Cannot Connect: %s\n", mysql_error(&mysql));
            my_debug(error);
            return 0;
        }
    } else {
        if(mysql_ping(&mysql) != 0) {
            my_debug("Failed to reconnect. Check debug for more info.\n");
            sprintf(error, "Server Error: %s\n", mysql_error(&mysql));
            my_debug(error);
            return 0;
        }

        if(mysql_select_db(&mysql, my_database) != 0) {
            sprintf(error, "Unable to select database: %s. Still Connected.\n", my_database);
            my_debug(error);
            sprintf(error, "Database Select Failed: %s\n", mysql_error(&mysql));
            my_debug(error);
            return 0;
        }

        // if(DEBUG) printf("DB connected.\n");
        return 1;
    }
}
