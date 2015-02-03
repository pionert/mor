/*
*
*	MOR Record audio file script
*	Copyright Mindaugas Kezys / Kolmisoft 2009
*
*	v1.0    2015-01-20    Initial X6 script version
*
*
*/


#define SCRIPT_NAME    "mor_record_file"
#define SCRIPT_VERSION "1.0"

#include "mor_functions.c"


// VARIABLES


int server_id = 1;
char uniqueid[128] = "";
int src_device_id = 0;
int src_user_id = 0;

int dst_device_id = 0;
int dst_user_id = 0;
int visible_to_user = 1;
int visible_to_dst_user = 1;

// server details

int use_external_server = 0;
char server_ip[20] = "";
int server_port = 22;
char server_login[30] = "root";
double server_max_space = 100;

// call details

int call_id = 0;
char call_calldate[30] = "";
char call_src[128] = "";
char call_dst[128] = "";
int call_user_id = 0;

// other vars

char full_file_name_wav[512] = "";
char full_file_name_mp3[512] = "";
long local_mp3_size = 0;
long remote_mp3_size = 0;


// FUNCTION DECLARATIONS


void get_server_details();
void get_device_details(int device_id, int *user_id);
void get_call_details();
int file_exists(char *filename);
long file_size(char* filename);


// MAIN FUNCTION


int main(int argc, char *argv[]) {

    char buff[2048] = "";

    mor_init("Starting MOR X6 Record File script\n");

    // assign variables
    if (argv[1]) {
        strcpy(uniqueid, argv[1]);
    }
    if (argv[2]) {
        src_device_id = atoi(argv[2]);
    }
    if (argv[3]) {
        dst_device_id = atoi(argv[3]);
    }
    if (argv[4]) {
        visible_to_user = atoi(argv[4]);
    }
    if (argv[5]) {
        visible_to_dst_user = atoi(argv[5]);
    }

    // get server_id
    if (mor_get_variable("server_id", buff)) {
        mor_log("server_id not found in %s\n", CONFPATH);
    } else if (strlen(buff)) {
        server_id = atoi(buff);
    }

    // set filenames
    sprintf(full_file_name_wav, "/var/spool/asterisk/monitor/%s.wav", uniqueid);
    sprintf(full_file_name_mp3, "/var/spool/asterisk/monitor/%s.mp3", uniqueid);

    // info to log file
    mor_log("Uniqueid: %s, src_device_id: %d, dst_device_id: %d, visible_to_user: %d, visible_to_dst_user: %d, server_id: %d\n",
        uniqueid, src_device_id, dst_device_id, visible_to_user, visible_to_dst_user, server_id);

    // check for errors
    if (!file_exists(full_file_name_wav)) {
		mor_log("No recording %s found, aborting...\n", full_file_name_wav);
		return 0;
    }

    if (!strlen(uniqueid)) {
		mor_log("No filename/uniqueid provided, aborting...\n");
		return 0;
    }

    if (!strlen(uniqueid)) {
		mor_log("No filename/uniqueid provided, aborting...\n");
		return 0;
    }

    if ((!src_device_id) && (!dst_device_id)) {
		mor_log("No src and/or dst device id provided, aborting...\n");
		return 0;
    }

    // collect data
    get_server_details();
    get_call_details();

    if (!call_id) {
		mor_log("Call not found, aborting...\n");
		return 0;
    }

    // get device details
    get_device_details(src_device_id, &src_user_id);
    get_device_details(dst_device_id, &dst_user_id);

    if (!file_exists(full_file_name_wav)) {
		mor_log("Error uploading WAV file - WAV file not found\n");
    } else {
        // execute
        if (use_external_server) {

    	  	// using external server
    	  	mor_log("Using external server\n");

            // log into db
            sprintf(buff, "INSERT INTO recordings (call_id, datetime, src, dst, src_device_id, dst_device_id, uniqueid, size, user_id, "
                "dst_user_id, visible_to_user, visible_to_dst_user, local) "
                "VALUES (%d, '%s', '%s', '%s', '%d', '%d', '%s', '0', '%d', '%d', '%d', '%d', '0')",
            call_id, call_calldate, call_src, call_dst, src_device_id, dst_device_id, uniqueid, src_user_id,
            dst_user_id, visible_to_user, visible_to_dst_user);

            // send query
            mor_log("%s\n", buff);
    	  	mor_mysql_query(buff);
            sprintf(full_file_name_mp3, "/usr/local/mor/recordings/%s.mp3", uniqueid);

            // copy file to remote server
    		sprintf(buff, "/usr/bin/scp -P %d %s %s@%s:/tmp/%s.wav", server_port, full_file_name_wav, server_login, server_ip, uniqueid);
    		mor_log("%s\n", buff);
    		system(buff);

    		// execute mor_remote_record script
    		sprintf(buff, "/usr/bin/ssh %s@%s -p %d -f /usr/local/mor/mor_record_remote %s", server_login, server_ip, server_port, uniqueid);
    		mor_log("%s\n", buff);
    		system(buff);

        } else {

            // converting and storing file locally
            mor_log("Converting and storing file locally\n");
            sprintf(buff, "/usr/local/bin/lame --resample 44.1 -b 32 -a %s %s", full_file_name_wav, full_file_name_mp3);
            mor_log("%s\n", buff);
            system(buff);

            local_mp3_size = file_size(full_file_name_mp3);
            mor_log("MP3 size: %li\n", local_mp3_size);

            // log into db
            sprintf(buff, "INSERT INTO recordings (call_id, datetime, src, dst, src_device_id, dst_device_id, uniqueid, size, user_id, dst_user_id, "
                "visible_to_user, visible_to_dst_user, local) VALUES (%d, '%s', '%s', '%s', '%d', '%d', '%s', '%li', '%d', '%d', '%d', '%d', '1')",
            call_id, call_calldate, call_src, call_dst, src_device_id, dst_device_id, uniqueid, local_mp3_size, src_user_id, dst_user_id,
            visible_to_user, visible_to_dst_user);

            mor_log("%s\n", buff);
            mor_mysql_query(buff);

            // rec sending/deleting over email script
            mor_log("Executing recording email/deleting control script\n");
            sprintf(buff, "/usr/local/mor/mor_record_control %s 1", uniqueid);
            mor_log("%s\n", buff);
            system(buff);

        }

        // delete uploaded wav file
        sprintf(buff, "rm %s", full_file_name_wav);
        mor_log("%s\n", buff);
        system(buff);

    }

    mor_log("Script completed\n");
    mor_log("\n");
    return 0;

}


// FUNCTIONS


void get_device_details(int device_id, int *user_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";

    if (!device_id) {
    	mor_log("No details retrieved for device (id = 0)\n");
    	return;
    }


    sprintf(sqlcmd, "SELECT user_id FROM devices WHERE id = %d", device_id);

	if (mor_mysql_query(sqlcmd)) {
	    return;
	}

    result = mysql_store_result(&mysql);
    if (result) {
		while ((row = mysql_fetch_row(result))) {
		    if (row[0]) *user_id = atoi(row[0]);
		    mor_log("Device details retrieved: device id: %d, user id: %d\n", device_id, *user_id);
    	}
	    mysql_free_result(result);
	}

}


void get_server_details() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT (SELECT value FROM conflines WHERE name = 'Recordings_addon_Use_External_Server' AND owner_id = 0),	"
        "(SELECT value FROM conflines WHERE name = 'Recordings_addon_IP' AND owner_id = 0),	"
        "(SELECT value FROM conflines WHERE name = 'Recordings_addon_Login' AND owner_id = 0), "
        "(SELECT value FROM conflines WHERE name = 'Recordings_addon_Port' AND owner_id = 0), "
        "(SELECT value FROM conflines WHERE name = 'Recordings_addon_Max_Space' AND owner_id = 0)");

	if (mysql_query(&mysql,sqlcmd)) {
	    return;
	}

    result = mysql_store_result(&mysql);
    if (result) {
		while ((row = mysql_fetch_row(result))) {
		    if (row[0]) use_external_server = atoi(row[0]);
		    if (row[1]) strcpy(server_ip, row[1]);
		    if (row[2]) strcpy(server_login, row[2]);
		    if (row[3]) server_port = atoi(row[3]);
		    if (row[4]) server_max_space = atof(row[4]);

		    mor_log("Server details retrieved: enabled: %d, IP: %s, port: %d, login: %s, max space: %f\n",
                use_external_server, server_ip, server_port, server_login, server_max_space);
    	}
		mysql_free_result(result);
    }

}


void get_call_details() {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT id, calldate, src, dst, user_id FROM calls "
        "WHERE uniqueid = '%s' AND calldate BETWEEN from_unixtime('%s'-86400) AND from_unixtime('%s'+86400)", uniqueid, uniqueid, uniqueid);

	if (mor_mysql_query(sqlcmd)) {
	    return;
	}

	result = mysql_store_result(&mysql);
    if (result) {
		while ((row = mysql_fetch_row(result))) {
		    if (row[0]) call_id  = atoi(row[0]);
		    if (row[1]) strcpy(call_calldate, row[1]);
		    if (row[2]) strcpy(call_src, row[2]);
		    if (row[3]) strcpy(call_dst, row[3]);
		    if (row[4]) call_user_id = atoi(row[4]);
		    mor_log( "Call details retrieved: id: %d, calldate: %s, src: %s, dst: %s, user_id: %d\n", call_id, call_calldate, call_src, call_dst, call_user_id);
    	}
		mysql_free_result(result);
	}

}


int file_exists(char *filename) {
	FILE *file;
    file = fopen(filename, "r");
	if (file != NULL) {
		fclose(file);
		return 1;
	}
	return 0;
}


long file_size(char* filename) {
	struct stat stbuf;
	stat(filename, &stbuf);
	return stbuf.st_size;
}
