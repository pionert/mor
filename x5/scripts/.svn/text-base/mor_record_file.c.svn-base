/*
*
*	MOR Record audio file script
*	Copyright Mindaugas Kezys / Kolmisoft 2009
*
*	v0.1.1
*
*	2013-04-09	Select speedup for calls
*
*/


#include <mysql.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <sys/stat.h>

/* Defines */

#define DATE_FORMAT "%Y-%m-%d"
#define TIME_FORMAT "%T"
#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S"


/* Structures */

/* Variables */

char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;

int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;

static MYSQL	mysql;

int server_id = 1;


// specific vars

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

/* Function declarations */

void get_server_details();
void get_device_details(int device_id, int *user_id);
void get_call_details();

void read_config();
static int mysql_connect();



void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_file.log","a+");
    fprintf(file,"%s - %s\n", uniqueid, msg);
    fclose(file);
}

void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_file.log","a+");
    fprintf(file,"%s - %i\n", uniqueid, msg);
    fclose(file);
}


int file_exists(char *filename){
  FILE *file;

  if (file = fopen(filename, "r")) {
    fclose(file);
    return 1;
  }
  return 0;
}

long file_size(char* filename){

  struct stat stbuf;
  stat(filename, &stbuf);
  return stbuf.st_size;
}


main(int argc, char *argv[]) {


    struct tm tm;
    struct timeval t0, t1;
    char mdate[20];
    char mtime[20];
    time_t t;
    suseconds_t	ut0, ut1;

    char buff[2048] = "";


    /* Get current time */
    gettimeofday(&t0, NULL);
    t=t0.tv_sec;
    ut0=t0.tv_usec;
    localtime_r(&t, &tm);
    strftime(mdate, 128, DATE_FORMAT, &tm);
    strftime(mtime, 128, TIME_FORMAT, &tm);


    // assign variables

    if (argv[1])
        strcpy(uniqueid, argv[1]);
    if (argv[2])
        src_device_id = atoi(argv[2]);
    if (argv[3])
        dst_device_id = atoi(argv[3]);
    if (argv[4])
        visible_to_user = atoi(argv[4]);
    if (argv[5])
        visible_to_dst_user = atoi(argv[5]);


    sprintf(full_file_name_wav, "/var/spool/asterisk/monitor/%s.wav", uniqueid);
    sprintf(full_file_name_mp3, "/var/spool/asterisk/monitor/%s.mp3", uniqueid);


    // info to log file
    //my_debug("");
    sprintf(buff, "Date: %s %s, uniqueid: %s, src_device_id: %i, dst_device_id: %i, visible_to_user: %i, visible_to_dst_user: %i", mdate, mtime, uniqueid, src_device_id, dst_device_id, visible_to_user, visible_to_dst_user);
    my_debug(buff);


    // check for errors

    if (!file_exists(full_file_name_wav)){
	sprintf(buff, "No recording %s found, aborting...", full_file_name_wav);
	my_debug(buff);
	return 0;
    }


    if (!strlen(uniqueid)) {
	my_debug("No filename/uniqueid provided, aborting...");
	return 0;
    }


    if (!strlen(uniqueid)) {
	my_debug("No filename/uniqueid provided, aborting...");
	return 0;
    }

    if ((!src_device_id) && (!dst_device_id)) {
	my_debug("No src and/or dst device id provided, aborting...");
	return 0;
    }


    // connect to db

    read_config();

    if (!mysql_connect())
	return 0;

    // collect data

    get_server_details();

    get_call_details();

    if (!call_id) {
	my_debug("Call not found, aborting...");
        mysql_close(&mysql);
	return 0;
    }


    get_device_details(src_device_id, &src_user_id);
    get_device_details(dst_device_id, &dst_user_id);


    if (!file_exists(full_file_name_wav)){

	my_debug("Error uploading WAV file - WAV file not found");

    } else {

      // execute

      if (use_external_server){
	  // using external server
	  my_debug("Using external server");

          // log into db
          sprintf(buff,"INSERT INTO recordings (call_id, datetime, src, dst, src_device_id, dst_device_id, uniqueid, size, user_id, dst_user_id, visible_to_user, visible_to_dst_user, local) VALUES (%i, '%s', '%s', '%s', '%i', '%i', '%s', '0', '%i', '%i', '%i', '%i', '0');", call_id, call_calldate, call_src, call_dst, src_device_id, dst_device_id, uniqueid, src_user_id, dst_user_id, visible_to_user, visible_to_dst_user);
	  my_debug(buff);
	  mysql_query(&mysql,buff);

          sprintf(full_file_name_mp3, "/usr/local/mor/recordings/%s.mp3", uniqueid);

	  // copy file to remote server
	  sprintf(buff, "/usr/bin/scp -P %i %s %s@%s:/tmp/%s.wav", server_port, full_file_name_wav, server_login, server_ip, uniqueid);
	  my_debug(buff);
	  system(buff);

          // execute mor_remote_record script
	  sprintf(buff, "/usr/bin/ssh %s@%s -p %i -f /usr/local/mor/mor_record_remote %s", server_login, server_ip, server_port, uniqueid);
	  my_debug(buff);
	  system(buff);


      } else {
	  // converting and storing file locally
	  my_debug("Converting and storing file locally");

	  sprintf(buff, "/usr/local/bin/lame --resample 44.1 -b 32 -a %s %s", full_file_name_wav, full_file_name_mp3);
	  my_debug(buff);
	  system(buff);


	  local_mp3_size = file_size(full_file_name_mp3);
	  sprintf(buff, "MP3 size: %li", local_mp3_size);
	  my_debug(buff);

          // log into db
          sprintf(buff,"INSERT INTO recordings (call_id, datetime, src, dst, src_device_id, dst_device_id, uniqueid, size, user_id, dst_user_id, visible_to_user, visible_to_dst_user, local) VALUES (%i, '%s', '%s', '%s', '%i', '%i', '%s', '%li', '%i', '%i', '%i', '%i', '1');", call_id, call_calldate, call_src, call_dst, src_device_id, dst_device_id, uniqueid, local_mp3_size, src_user_id, dst_user_id, visible_to_user, visible_to_dst_user);
	  my_debug(buff);
          mysql_query(&mysql,buff);

          // rec sending/deleting over email script
	  my_debug("Executing recording email/deleting control script");
	  sprintf(buff, "/usr/local/mor/mor_record_control %s 1", uniqueid);
	  my_debug(buff);
	  system(buff);

      }

      // delete uploaded wav file

      sprintf(buff, "rm %s", full_file_name_wav);
      my_debug(buff);
      system(buff);

    }


    // bye

    mysql_close(&mysql);

    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;
//    printf("Execution time: %f s\n\n", (float) (ut1-ut0)/1000000);

    //gets(NULL);

    my_debug("Script completed.\n\n");

}



/* Functions */
void get_device_details(int device_id, int *user_id){

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;

    char buff[2048] = "";

    if (!device_id){
	my_debug("No details retrieved for device (id = 0)");
	return;
    }


    sprintf(sqlcmd,"SELECT user_id FROM devices WHERE id = %i;", device_id);

        //if (SHOW_SQL)	printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))
	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{

		    if (row[0]) *user_id = atoi(row[0]);

		    sprintf(buff, "Device details retrieved: device id: %i, user id: %i", device_id, *user_id);
		    my_debug(buff);

		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}

}


void get_server_details(){


    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;

    char buff[2048];

    sprintf(sqlcmd,"SELECT (SELECT value FROM conflines WHERE name = 'Recordings_addon_Use_External_Server' AND owner_id = 0),	(SELECT value FROM conflines WHERE name = 'Recordings_addon_IP' AND owner_id = 0),	(SELECT value FROM conflines WHERE name = 'Recordings_addon_Login' AND owner_id = 0),	(SELECT value FROM conflines WHERE name = 'Recordings_addon_Port' AND owner_id = 0),	(SELECT value FROM conflines WHERE name = 'Recordings_addon_Max_Space' AND owner_id = 0);");

        //if (SHOW_SQL)	printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))
	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{

		    if (row[0]) use_external_server = atoi(row[0]);
		    if (row[1]) strcpy(server_ip, row[1]);
		    if (row[2]) strcpy(server_login, row[2]);
		    if (row[3]) server_port = atoi(row[3]);
		    if (row[4]) server_max_space = atof(row[4]);

		    sprintf(buff, "Server details retrieved: enabled: %i, IP: %s, port: %i, login: %s, max space: %f", use_external_server, server_ip, server_port, server_login, server_max_space);

		    my_debug(buff);

		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}


}



void get_call_details(){

    MYSQL_RES	*result;
    MYSQL_ROW	row;
    char sqlcmd[2048] = "";
    int res = 0, i;

    char buff[2048];

    sprintf(sqlcmd,"SELECT id, calldate, src, dst, user_id FROM calls WHERE uniqueid = '%s' AND calldate BETWEEN from_unixtime('%s'-86400) AND from_unixtime('%s'+86400);", uniqueid, uniqueid, uniqueid);


        //if (SHOW_SQL)	printf("SQL: %s\n", sqlcmd);

	if (mysql_query(&mysql,sqlcmd))
	{
	    // error
	    res = -1;
	}
	else // query succeeded, process any data returned by it
	{
	    result = mysql_store_result(&mysql);
	    if (result)  // there are rows
	    {
	        i = 0;
		while ((row = mysql_fetch_row(result)))
		{


		    if (row[0]) call_id  = atoi(row[0]);
		    if (row[1]) strcpy(call_calldate, row[1]);
		    if (row[2]) strcpy(call_src, row[2]);
		    if (row[3]) strcpy(call_dst, row[3]);
		    if (row[4]) call_user_id = atoi(row[4]);

		    sprintf(buff, "Call details retrieved: id: %i, calldate: %s, src: %s, dst: %s, user_id: %i", call_id, call_calldate, call_src, call_dst, call_user_id);

		    my_debug(buff);

		    i++;
    		}
		mysql_free_result(result);
	    }
	    else  // mysql_store_result() returned nothing; should it have?
	    {
	        if(mysql_field_count(&mysql) == 0)
	        {	        }
	        else // mysql_store_result() should have returned data
	        {
		    res = -1;
		}
	    }
	}


}


void read_config(){
    FILE	*file;
    char var[200], val[200];

    file = fopen("/var/lib/asterisk/agi-bin/mor.conf", "r");

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;
    //strcpy(dbport, "3306");

//    calls_one_time = 20;
//    cron_interval = 10;

    /* Read values from conf file */
    while (fscanf(file, "%s = %s", var, val) != EOF) {

	if (!strcmp(var, "host")) {
	    strcpy(dbhost, val);
	}
	if (!strcmp(var, "db")) {
	    strcpy(dbname, val);
	}
	if (!strcmp(var, "user")) {
	    strcpy(dbuser, val);
	}
	if (!strcmp(var, "secret")) {
	    strcpy(dbpass, val);
	}
	if (!strcmp(var, "port")) {
	    dbport = atoi(val);
	}
	if (!strcmp(var, "show_sql")) {
	    SHOW_SQL = atoi(val);
	}
	if (!strcmp(var, "debug")) {
	    DEBUG = atoi(val);
	}
	if (!strcmp(var, "server_id")) {
	    server_id = atoi(val);
	}

    }

    fclose(file);

//    my_debug("server_id");
//    my_debug_int(server_id);

//    if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %i, SHOW_SQL: %i, DEBUG: %i, server_id\n", dbhost, dbname, dbuser, dbpass, dbport, SHOW_SQL, DEBUG);

}


static int mysql_connect()
{
    char my_database[50];

    strcpy(my_database, dbname);

    if(dbhost && dbuser && dbpass && my_database) {
        if(!mysql_init(&mysql)) {
	    printf("Insufficient memory to allocate MySQL resource.\n");
    	    return 0;
	}
        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, my_database, dbport, NULL, 0)) {
	    //if (DEBUG) printf("Successfully connected to database.\n");
	    return 1;
        } else {
	    printf("Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
	    printf("Cannot Connect: %s\n", mysql_error(&mysql));
	    return 0;
        }
    } else {
	if(mysql_ping(&mysql) != 0) {
	    printf("Failed to reconnect. Check debug for more info.\n");
	    printf("Server Error: %s\n", mysql_error(&mysql));
	    return 0;
        }

        if(mysql_select_db(&mysql, my_database) != 0) {
	    printf("Unable to select database: %s. Still Connected.\n", my_database);
	    printf("Database Select Failed: %s\n", mysql_error(&mysql));
	    return 0;
        }

        //if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}
