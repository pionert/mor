/*
*
*	MOR Asterisk Remote Record script
*	Copyright Mindaugas Kezys / Kolmisoft 2009-2012
*
*	v0.1.1		2012-04-06	Debug to db connection
*	v0.1.0
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
int calls_one_time, cron_interval;
int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;
int server_id = 1;

static MYSQL	mysql;

char full_filename_wav[256] = "";
char mp3_in_tmp[256] = "";
char src[256] = "";
//char dst[256] = "";

char final_folder[256] = "/usr/local/mor/recordings/";
char final_dst[256] = "";
long int mp3_size = 0;



/* Function declarations */

//int generate_registry(char *prov_type);

void read_config();
static int mysql_connect();


int file_exists(char *filename){
  FILE *file;

  if (file = fopen(filename, "r")) {
    fclose(file);
    return 1;
  }
  return 0;
}


long file_size(char* filename)
{
    struct stat stbuf;
    stat(filename, &stbuf);
    return stbuf.st_size;
}



void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_file.log","a+");
    fprintf(file,"%s - %s\n", src, msg);
    fclose(file);
}

void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_remote.log","a+");
    fprintf(file,"%s - %i\n", src, msg);
    fclose(file);
}



main(int argc, char *argv[]) {

    struct tm tm;
    struct timeval t0, t1;
    char mdate[20];
    char mtime[20];
    time_t t;
    suseconds_t	ut0, ut1;
//    FILE *file;
//    char size_file_name[40] = "";

    /* Get current time */
    gettimeofday(&t0, NULL);
    t=t0.tv_sec;
    ut0=t0.tv_usec;
    localtime_r(&t, &tm);
    strftime(mdate, 128, DATE_FORMAT, &tm);
    strftime(mtime, 128, TIME_FORMAT, &tm);

    char buff[2048] = "";

    // assign variables

    if (argv[1])
        strcpy(src, argv[1]);
//    if (argv[2])
//        strcpy(dst, argv[2]);

    // info to log file
    //my_debug("");
    sprintf(buff, "Date: %s %s, src/file name/uniqueid: %s", mdate, mtime, src);
    my_debug(buff);


    // check for errors

    if (!strlen(src)) {
        my_debug("No source provided, aborting...");
        return 0;
    }


    sprintf(full_filename_wav, "/tmp/%s.wav", src);
    my_debug(full_filename_wav);

    sprintf(mp3_in_tmp, "/tmp/%s.mp3", src);
    my_debug(mp3_in_tmp);


    if (!file_exists(full_filename_wav)){
        sprintf(buff, "No source WAV file %s found, aborting...", full_filename_wav);
	my_debug(buff);
        return 0;
    }



    sprintf(final_dst, "%s%s.mp3", final_folder, src);
    my_debug(final_dst);

    // convert file

    sprintf(buff, "/usr/local/bin/lame --resample 44.1 -b 32 -a %s %s", full_filename_wav, mp3_in_tmp);
    my_debug(buff);
    system(buff);


    if (!file_exists(mp3_in_tmp)){
        my_debug("Error converting WAV to MP3");
        return 0;
    } else {
        // move to correct location
        sprintf(buff, "mv %s %s", mp3_in_tmp, final_folder);
        my_debug(buff);
        system(buff);
    }

    mp3_size = file_size(final_dst);
    sprintf(buff, "MP3 size: %li", mp3_size);
    my_debug(buff);


    // delete uploaded wav file
    sprintf(buff, "rm %s", full_filename_wav);
    my_debug(buff);
    system(buff);

/*
    sprintf(size_file_name, "/tmp/%s", src);
    file = fopen(size_file_name,"a+");
    fprintf(file,"%li", mp3_size);
    fclose(file);
*/


    // connect to db

    read_config();

    if (!mysql_connect()) {
        my_debug("Cannot connect to DB, aborting...");
	return 0;
    }

    // update size of recording
    sprintf(buff,"UPDATE recordings SET size = '%li' WHERE uniqueid = '%s';", mp3_size, src);
    my_debug(buff);
    mysql_query(&mysql,buff);


    // rec sending/deleting over email script
    my_debug("Executing recording email/deleting control script");
    sprintf(buff, "/usr/local/mor/mor_record_control %s 0", src);
    my_debug(buff);
    system(buff);


    gettimeofday(&t1, NULL);
    ut1=t1.tv_usec;

    mysql_close(&mysql);

    my_debug("Script completed.\n\n");


}



/* Functions */


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
	    //strcpy(dbport, val);
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
