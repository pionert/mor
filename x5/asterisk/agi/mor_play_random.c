
/*
*
*    MOR Play Random AGI script
*    Copyright Ričardas Stoma / Kolmisoft 2014
*
*    v0.1
*
*    2014.04.14 v0.1 Release
*
*    This AGI script plays random file from directory passed in arguments
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "mor_agi_functions.c"

#define SOUND_PATH "/home/mor/public/ivr_voices"

int main(int argc, char *argv[]) {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char query[1024] = "";
    char sound_file[1024] = "";
    char buffer[1024] = "";
    char voice[128] = "";

    if (argc != 2) {
        AGITool_verbose(&agi, &res, "Wrong number of argments", 0);
        return 1;
    }

    if (!strlen(argv[1])) {
        AGITool_verbose(&agi, &res, "Voice name is empty", 0);
        return 1;
    } else {
        strcpy(voice, argv[1]);
    }

    /* init environment */
    AGITool_Init(&agi);
    AGITool_verbose(&agi, &res, "MOR Play Random script started", 0);

    // DB connection
    read_config();

    if (!mysql_connect()) {
        AGITool_verbose(&agi, &res, "ERROR! Not connected to database", 0);
        AGITool_Destroy(&agi);
        return 0;
    }

    sprintf(query, "SELECT SUBSTRING(path, 1, CHAR_LENGTH(path) - 4) from ivr_voices INNER JOIN ivr_sound_files ON ivr_sound_files.ivr_voice_id = ivr_voices.id WHERE ivr_voices.voice = '%s' ORDER BY RAND() LIMIT 1", voice);

    if (!mysql_query(&mysql, query)) {
        result = mysql_store_result(&mysql);
        if (result) {
            while ((row = mysql_fetch_row(result))) {
                if (row[0]) strcpy(buffer, row[0]);
            }
            mysql_free_result(result);
        }
    }

    if (strlen(buffer)) {
        sprintf(sound_file, "%s/%s/%s", SOUND_PATH, voice, buffer);
        AGITool_exec(&agi, &res, "PLAYBACK", sound_file);
    } else {
        AGITool_verbose(&agi, &res, "Random sound file not found", 0);
    }

    /* detroy environment */
    AGITool_verbose(&agi, &res, "MOR Play Random script stopped", 0);
    AGITool_Destroy(&agi);
    return 0;

}
