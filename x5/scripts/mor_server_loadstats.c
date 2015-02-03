// Author:        Ricardas Stoma
// Company:       Kolmisoft
// Year:          2013
// About:         Daemon for system load monitoring

#define SCRIPT_VERSION "1.5"
#define SCRIPT_NAME    "mor_server_loadstats"

#include "mor_functions.c"

// DEFINITIONS

#define TMP_TOP_LOG_DIR "/tmp/mor_server_top_load_tmp.txt"
#define TMP_IOS_LOG_DIR "/tmp/mor_server_iostat_load_tmp.txt"
#define SERVERCONFPATH  "/etc/mor/system.conf"
#define DATA_AVG_COUNT  5

// GLOBAL VARIABLES

// statistics
float cpu_load      = 0;
float average_load  = 0;
float mysql_load    = 0;
float ruby_load     = 0;
float asterisk_load = 0;
float hdd_load      = 0;

// load limits
typedef struct load_struct {
    float cpu_load;
    float average_load;
    float mysql_load;
    float asterisk_load;
    float ruby_load;
    float hdd_load;
} load_t;

load_t avg[DATA_AVG_COUNT];
load_t gui;
load_t db;

// server ID
int server_id = 0;
int core_present = 0;
int gui_present = 0;
int db_present = 0;

// delete loadstats older than x days
int delete_older_than = 0;

// is load OK?
int load_ok = 1;
int last_load_ok = 0;

// time variables
time_t rawtime;
struct tm current_time;
int last_hour = 0;
int last_minute = 0;

// FUNCTION DECLARATIONS

int get_pipe_value(float *value, char *cmd);
int get_system_data();
int write_data_to_database();
int _get_server_id(const char *path);
int get_server_id();
void get_loadstats_limits();
int check_limits(load_t server, int type);
int update_load_status(int status);
int delete_old_loadstats();
void calculate_avg();

// MAIN FUNCTION

int main(void) {

    // error file
    FILE *tmp_errorfile = fopen(LOG_PATH, "a+");

    if (tmp_errorfile == NULL) {
        return 1;
    }

    if (mor_check_process_lock()) {
        fprintf(tmp_errorfile, "Process locked!\n");
        fclose(tmp_errorfile);
        exit(1);
    }

    fclose(tmp_errorfile);

    // Our process ID and Session ID
    pid_t pid, sid;

    // Fork off the parent process
    pid = fork();
    if (pid < 0) {
        exit(1);
    }

    // If we got a good PID, then we can exit the parent process.
    if (pid > 0) {
        exit(0);
    }

    // Change the file mode mask
    umask(0);

    // Create a new SID for the child process
    sid = setsid();
    if (sid < 0) {
        // Log the failure
        exit(1);
    }

    // Change the current working directory
    if ((chdir("/")) < 0) {
        // Log the failure
        exit(1);
    }

    // Close out the standard file descriptors
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);

    mor_init("Starting MOR Server Load Stats daemon\n");

    // get server_id
    get_server_id();

    mor_log("Server id: %d\n", server_id);

    memset(&gui, 0, sizeof(load_t));
    memset(&db, 0, sizeof(load_t));
    memset(&avg, 0, DATA_AVG_COUNT * sizeof(load_t));

    // get initial limits
    get_loadstats_limits();

    // The Big Loop
    while (1) {

        time(&rawtime);
        localtime_r(&rawtime, &current_time);

        // get data from top and iostat
        if (get_system_data()) {
            mor_log("get_system_data() error\n");
            exit(1);
        }

        // default values
            cpu_load = -1;
            average_load = -1;
            mysql_load = -1;
            asterisk_load = -1;
            ruby_load = -1;
            hdd_load = -1;

        // get user cpu usage
        if (get_pipe_value(&cpu_load, "cat " TMP_TOP_LOG_DIR "| grep 'Cpu(s)' | tail -n 1 | awk '{print $2}'")) {
            exit(1);
        }
        // get cpu average load
        if (get_pipe_value(&average_load, "cat " TMP_TOP_LOG_DIR " | grep -o 'load average: [0-9\\.]\\+' | tail -n 1  | grep -o '[0-9\\.]\\+'")) {
            exit(1);
        }
        if (db_present) {
            // get mysql cpu usage
            if (get_pipe_value(&mysql_load, "cat " TMP_TOP_LOG_DIR " | grep -v 'safe' | grep 'mysqld' | sort -n | tail -n 1 | awk '{print $9}'")) {
                exit(1);
            }
        }
        if (gui_present) {
            // get ruby cpu usage
            if (get_pipe_value(&ruby_load, "cat " TMP_TOP_LOG_DIR " | grep 'ruby' | sort -n | tail -n 1 | awk '{print $9}'")) {
                exit(1);
            }
        }
        // get asterisk cpu usage
        if (core_present) {
            if (get_pipe_value(&asterisk_load, "cat " TMP_TOP_LOG_DIR " | grep -v 'safe' | grep 'asterisk' | sort -n | tail -n 1 | awk '{print $9}'")) {
                exit(1);
            }
        }
        // get sda usage
        if (get_pipe_value(&hdd_load, "cat " TMP_IOS_LOG_DIR " | awk -v RS='' '/Device/{a=$0}END{print a}' | awk '{print $12}' | sort -n | tail -n 1 | tr ',' '.'")) {
            exit(1);
        }

        calculate_avg();

        // write data
        if (write_data_to_database()) {
            exit(1);
        }

        int current_load_ok = 1;

        // check load limits for DB server
        if (db_present) {
            if (check_limits(db, 0)) {
                current_load_ok = 0;
            }
        }
        // check load limits for GUI server
        if (gui_present) {
            if (check_limits(gui, 1)) {
                current_load_ok = 0;
            }
        }

        // modify real load_ok value
        if (current_load_ok == 0) {
            load_ok = 0;
        } else {
            load_ok = 1;
        }

        // did load_ok value changed?
        if (load_ok != last_load_ok) {
            mor_log("Updating LOAD OK from %d to %d\n", last_load_ok, load_ok);
            if (update_load_status(load_ok)) {
                exit(1);
            }
            last_load_ok = load_ok;
        }

        // remove tmp file
        unlink(TMP_TOP_LOG_DIR);
        unlink(TMP_IOS_LOG_DIR);

        // execute every minute
        if (last_minute != current_time.tm_min) {
            get_server_id();
            get_loadstats_limits();
            mor_log("Server type: GUI (%d), CORE (%d), DB (%d), load_ok: %d, delete loadstats older than: %d (days)\n", gui_present, core_present, db_present, last_load_ok, delete_older_than);
            mor_log("Current stats: %0.2f (cpu), %0.2f (average), %0.2f (mysql), %0.2f (asterisk), %0.2f (ruby), %0.2f (hdd)\n", cpu_load, average_load, mysql_load, asterisk_load, ruby_load, hdd_load);
            if (db_present) mor_log("Current limits [DB]: %0.2f (cpu), %0.2f (average), %0.2f (mysql), %0.2f (asterisk), %0.2f (hdd)\n", db.cpu_load, db.average_load, db.mysql_load, db.asterisk_load, db.hdd_load);
            if (gui_present) mor_log("Current limits [GUI]: %0.2f (cpu), %0.2f (average), %0.2f (asterisk), %0.2f (ruby), %0.2f (hdd)\n", gui.cpu_load, gui.average_load, gui.asterisk_load, gui.ruby_load, gui.hdd_load);
            last_minute = current_time.tm_min;
        }

        // execute every hour
        if (last_hour != current_time.tm_hour) {
            mor_log("Deleting old server loadstats from database\n");
            if (delete_old_loadstats()) {
                exit(1);
            }
            last_hour = current_time.tm_hour;
        }

    }

    mysql_close(&mysql);
    mysql_library_end();
    return 0;
}

int get_system_data() {

    FILE *pipe1 = NULL;
    FILE *pipe2 = NULL;

    // save top output to tmp file
    pipe1 = popen("top -b -n 2 > " TMP_TOP_LOG_DIR, "r");

    if (pipe1 == NULL) {
        return 1;
    }

    // save iostat output to tmp file
    pipe2 = popen("iostat -dx 3 2 > " TMP_IOS_LOG_DIR, "r");

    if (pipe2 == NULL) {
        return 1;
    }

    // wait for 2 iterations to complete
    sleep(4);

    // close pipes
    pclose(pipe1);
    pclose(pipe2);

    return 0;

}

int get_pipe_value(float *value, char *cmd) {

    char buffer[256] = { 0 };
    FILE *pipe = NULL;

    memset(buffer, 0, 256);

    pipe = popen(cmd, "r");

    if (pipe == NULL) {
        mor_log("Error while executing %s\n", cmd);
        return 1;
    }

    fgets(buffer, 256, pipe);
    buffer[strlen(buffer) - 1] = 0;
    *value = atof(buffer);

    pclose(pipe);

    return 0;

}

int write_data_to_database() {

    char query[1024] = { 0 };
    sprintf(query, "INSERT INTO server_loadstats(server_id, cpu_general_load, cpu_loadstats1, cpu_mysql_load, cpu_ruby_load, cpu_asterisk_load, hdd_util) VALUES(%d, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)", server_id, cpu_load, average_load, mysql_load, ruby_load, asterisk_load, hdd_load);
    if (mor_mysql_query(query)) {
        mor_mysql_reconnect();
    }

    return 0;

}

int get_server_id() {

    // get server_id
    if (_get_server_id(SERVERCONFPATH)) {
        mor_log("Cannot read server configuration from: " SERVERCONFPATH " or server_id is not set\n");
        exit(1);
    }

    // just to be sure
    if (server_id == 0) {
        mor_log("Server ID is not set\n");
        exit(1);
    }

    return 0;
}

// get server ID

int _get_server_id(const char *path) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    FILE *pipe;
    char buffer[256] = "";
    char cmd[1024] = { 0 };
    char sqlcmd[1024] = { 0 };

    sprintf(cmd, "cat %s | grep 'server_id' | tr '=' '\\n' | tail -n 1", path);

    pipe = popen(cmd, "r");

    if (!pipe) {
        return 1;
    }

    fgets(buffer, 256, pipe);
    buffer[strlen(buffer) - 1] = 0;
    server_id = atoi(buffer);

    pclose(pipe);

    if (server_id == 0) return 1;

    sprintf(sqlcmd, "SELECT gui, db, core, load_ok FROM servers WHERE id = %d", server_id);

    if (mor_mysql_query(sqlcmd)) {
        mor_mysql_reconnect();
        return 0;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        row = mysql_fetch_row(result);
        if (row[0] && row[1] && row[2] && row[3]) {
            gui_present = atoi(row[0]);
            db_present = atoi(row[1]);
            core_present = atoi(row[2]);
            last_load_ok = atoi(row[3]);;
        }
    }

    mysql_free_result(result);

    return 0;
}

// get loadstats limits from conflines

void get_loadstats_limits() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    if (mor_mysql_query("SELECT value, name FROM conflines WHERE name IN ('gui_hdd_utilisation', 'gui_cpu_general_load', 'gui_cpu_loadstats', 'gui_cpu_ruby_process', 'gui_cpu_asterisk_process', 'db_hdd_utilisation', 'db_cpu_general_load', 'db_cpu_loadstats', 'db_cpu_mysql_process', 'db_cpu_asterisk_process', 'Delete_Server_Load_stats_older_than')")) {
        mor_mysql_reconnect();
        return;
    }

    result = mysql_store_result(&mysql);
    if (result) {
        while ((row = mysql_fetch_row(result)) != NULL) {
            if (row[0]) {

                // gui limits
                if (strcmp(row[1], "GUI_HDD_utilisation") == 0) gui.hdd_load = atof(row[0]);
                if (strcmp(row[1], "GUI_CPU_General_load") == 0) gui.cpu_load = atof(row[0]);
                if (strcmp(row[1], "GUI_CPU_Loadstats") == 0) gui.average_load = atof(row[0]);
                if (strcmp(row[1], "GUI_CPU_asterisk_process") == 0) gui.asterisk_load = atof(row[0]);
                if (strcmp(row[1], "GUI_CPU_Ruby_process") == 0) gui.ruby_load = atof(row[0]);

                // db limits
                if (strcmp(row[1], "DB_HDD_utilisation") == 0) db.hdd_load = atof(row[0]);
                if (strcmp(row[1], "DB_CPU_General_load") == 0) db.cpu_load = atof(row[0]);
                if (strcmp(row[1], "DB_CPU_Loadstats") == 0) db.average_load = atof(row[0]);
                if (strcmp(row[1], "DB_CPU_MySQL_process") == 0) db.mysql_load = atof(row[0]);
                if (strcmp(row[1], "DB_CPU_asterisk_process") == 0) db.asterisk_load = atof(row[0]);

                // get older than variable (in days)
                if (strcmp(row[1], "Delete_Server_Load_stats_older_than") == 0) delete_older_than = atoi(row[0]);

            }
        }
    }

    if (delete_older_than < 0 || delete_older_than == 0) {
        mor_log("Incorrect 'Delete Server Load Stats older than' value: %d\n", delete_older_than);
    }

    mysql_free_result(result);

}

// check if current server load values exceed limits

int check_limits(load_t server, int type) {

    char typestr[4] = "";

    if (type == 0) {
        sprintf(typestr, "DB");
    } else {
        sprintf(typestr, "GUI");
    }

    if (hdd_load > server.hdd_load && server.hdd_load > 0) {
        mor_log("%s hdd_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, hdd_load, server.hdd_load);
        return 1;
    }

    if (cpu_load > server.cpu_load && server.cpu_load > 0) {
        mor_log("%s cpu_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, cpu_load, server.cpu_load);
        return 1;
    }

    if (core_present) {
        if (asterisk_load > server.asterisk_load && server.asterisk_load > 0) {
            mor_log("%s asterisk_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, asterisk_load, server.asterisk_load);
            return 1;
        }
    }

    if (type == 0) {
        if (mysql_load > server.mysql_load && server.mysql_load > 0) {
            mor_log("%s mysql_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, mysql_load, server.mysql_load);
            return 1;
        }
    }

    if (average_load > server.average_load && server.average_load > 0) {
        mor_log("%s average_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, average_load, server.average_load);
        return 1;
    }

    if (type == 1) {
        if (ruby_load > server.ruby_load && server.ruby_load > 0) {
            mor_log("%s ruby_load exceeds limits (current value: %0.2f, limit: %0.2f\n", typestr, ruby_load, server.ruby_load);
            return 1;
        }
    }

    return 0;

}

int update_load_status(int status) {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd, "UPDATE servers SET load_ok = %d WHERE id = %d", status, server_id);
    if (mor_mysql_query(sqlcmd)) {
        mor_mysql_reconnect();
    }

    return 0;
}


int delete_old_loadstats() {

    char sqlcmd[1024] = "";
    sprintf(sqlcmd, "DELETE FROM server_loadstats WHERE datetime  < DATE_SUB(NOW(), INTERVAL %d DAY)", delete_older_than);
    if (mor_mysql_query(sqlcmd)) {
        mor_mysql_reconnect();
    }

    return 0;
}


/*
    Calculate average values for last X load stats
*/


void calculate_avg() {

    float avg_cpu_load = 0;
    float avg_average_load = 0;
    float avg_mysql_load = 0;
    float avg_asterisk_load = 0;
    float avg_ruby_load = 0;
    float avg_hdd_load = 0;
    int i = 0;

    // shift values
    memmove(&avg[1], &avg[0], (DATA_AVG_COUNT - 1) * sizeof(load_t));
    // copy new values
    avg[0].cpu_load = cpu_load;
    avg[0].average_load = average_load;
    avg[0].mysql_load = mysql_load;
    avg[0].asterisk_load = asterisk_load;
    avg[0].ruby_load = ruby_load;
    avg[0].hdd_load = hdd_load;
    // sum all values
    for (i = 0; i < DATA_AVG_COUNT; i++) {
        avg_cpu_load += avg[i].cpu_load;
        avg_average_load += avg[i].average_load;
        avg_mysql_load += avg[i].mysql_load;
        avg_asterisk_load += avg[i].asterisk_load;
        avg_ruby_load += avg[i].ruby_load;
        avg_hdd_load+= avg[i].hdd_load;
    }
    // calculate average
    avg_cpu_load = avg_cpu_load / DATA_AVG_COUNT;
    avg_average_load = avg_average_load / DATA_AVG_COUNT;
    avg_mysql_load = avg_mysql_load / DATA_AVG_COUNT;
    avg_asterisk_load = avg_asterisk_load / DATA_AVG_COUNT;
    avg_ruby_load = avg_ruby_load / DATA_AVG_COUNT;
    avg_hdd_load = avg_hdd_load / DATA_AVG_COUNT;

    // set new values
    cpu_load = avg_cpu_load;
    average_load = avg_average_load;
    if (db_present) mysql_load = avg_mysql_load;
    if (core_present) asterisk_load = avg_asterisk_load;
    if (gui_present) ruby_load = avg_ruby_load;
    hdd_load = avg_hdd_load;

}
