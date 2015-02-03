/*

    Cron script to retrieve peer information from Asterisk over AMI and store into DB

    Designed to use with MOR software by Kolmisoft, 2011-2014

    v1.9  2014-04-05    Fixed memory leaks and formatting
    v1.8  2012-09-07    Asterisk configuration variables are read from file
    v1.7  2012-07-09    core show version for ast18 support
    v1.6  2012-06-27    Removed Locking by Transaction
    v1.5  2012-06-06    Version/Uptime implementation
    v1.4  2012-06-06    Abort if cannot connect to Asterisk
    v1.3  2012-04-13    SQL debug
    v1.2  2012-04-13    Bugfix to do not overwrite status/server_id for device
    v1.1  2012.04.06    Update servers_id together with the device, allow dynamic registrations
    v1.0  2011.08.15    Initial release


*/

#include "libami.c"

/*      Main function   */

int main(int argc, char *argv[])
{

    int sock = 0;
    char ast_host[20] = "";
    int ast_port;
    char ast_user[50] = "";
    char ast_secret[50] = "";

    ast_packet *p = NULL;
    ast_packet *resp = NULL;
    ast_packet *ptr;
    char *retval;

    int error = 0;
    char buff[1024] = "";

    char datetime[100];
    time_t now;

    char status[100] = "";     /* device's status */

    /* DB connection */
    read_config();

    if (!mysql_connect()) {
        my_debug("ERROR! Not connected to database.");
        ami_destroy_packet_group(resp);
        return 1;
    } else {
        //my_debug("Successfully connected to database.");
    }

    //date time
    if (time(&now) != (time_t)(-1)) {
        struct tm *mytime = localtime(&now);

        if (mytime) {
            strftime(datetime, sizeof datetime, "%Y-%m-%d %T", mytime);
        }
    }

    sprintf(buff, "\n%s Peer status update started.", datetime);
    my_debug(buff);

    /* initial AMI values - read later from conf file */
    strcpy(ast_host, "127.0.0.1");
    ast_port = 5038;
    strcpy(ast_user, "mor");
    strcpy(ast_secret, "morsecret");

    // retrieve AMI values from config file
    if (read_asterisk_config(0, &ast_port, ast_user, ast_secret)) {
        // retrieve AMI values from MySQL database
        if (read_asterisk_config(1, &ast_port, ast_user, ast_secret)) {
            sprintf(buff, "Cannot read Asterisk configuration variables. Using default values.");
            my_debug(buff);
        }
    }

    if (!error) {
        sock = asterisk_connect(ast_host, ast_port);

        if (sock <= 0) {
            sprintf(buff, "Unable to connect to asterisk server %s:%i", ast_host, ast_port);
            my_debug(buff);
            error = 1;
        }
    }


    if (!error) {

        p = ami_login(sock, ast_user, ast_secret, NULL, NULL);

        if (p == NULL) {
            sprintf(buff, "Error logging in");
            my_debug(buff);
            error = 1;
        }

        ami_destroy_packet(p);
        p = NULL;

    }

    /* get server version */


    if (!error) {

        if (DEBUG) {
            my_debug("Getting version");
        }

        resp = ami_server_version(sock, NULL);

        if (!resp) {
            my_debug("ERROR: Unable to retrieve server version response from server");
            return 1;
        }

    }

    retval = ami_get_packet_item_value(resp, "Response");

    if (!retval || strcasecmp(retval, "Success") != 0) {
        sprintf(buff, "Received an error from asterisk: %s", ami_get_packet_item_value(resp, "Message"));
        my_debug(buff);
        ami_destroy_packet_group(resp);
        return 1;
    }

    char version[100] = "";
    strcpy(version, ami_get_packet_item_value(resp, "Version"));
    sprintf(buff, "Version: %s", version);
    my_debug(buff);

    if (resp) {
        ami_destroy_packet_group(resp);
    }


    /* get server uptime */


    if (!error) {

        if (DEBUG) {
            my_debug("Getting version");
        }

        resp = ami_command(sock, "core show uptime", NULL);

        if (!resp) {
            my_debug("ERROR: Unable to retrieve server uptime response from server");
            return 1;
        }

    }

    retval = ami_get_packet_item_value(resp, "Response");

    if (!retval || strcasecmp(retval, "Success") != 0) {
        sprintf(buff, "Received an error from asterisk: %s", ami_get_packet_item_value(resp, "Message"));
        my_debug(buff);
        ami_destroy_packet_group(resp);
        return 1;
    }

    char uptime[200] = "";
    strcpy(uptime, &ami_get_packet_item_value(resp, "Chunk1")[31]);
    uptime[strlen(uptime) - 2] = '\0';

    sprintf(buff, "Uptime: %s", uptime);

    my_debug(buff);

    if (resp) {
        ami_destroy_packet_group(resp);
    }

    /* get SIP peers */

    if (!error) {

        if (DEBUG) {
            my_debug("Initializing Peers");
        }

        resp = ami_sip_peers(sock, NULL);

        if (!resp) {
            my_debug("ERROR: Unable to retrieve sip peers list response from server");
            return 1;
        }
    }


    if (error) {
        my_debug("Aborting...");
        return 1;
    }

    retval = ami_get_packet_item_value(resp, "Response");

    if (!retval || strcasecmp(retval, "Success") != 0) {
        sprintf(buff, "Received an error from asterisk: %s", ami_get_packet_item_value(resp, "Message"));
        my_debug(buff);
        ami_destroy_packet_group(resp);
        return 1;
    }

    if (DEBUG) {
        sprintf(buff, "Server_id: %i", server_id);
        my_debug(buff);
    }


    /* start mysql transaction */
    //mysql_query(&mysql, "START TRANSACTION;");


    /* update server's version and uptime */
    sprintf(buff, "UPDATE servers SET version = '%s', uptime = '%s' WHERE id = '%i';", version, uptime, server_id);
    mysql_query(&mysql, buff);


    /* clean current reg_status values for devices on this server */
    sprintf(buff, "UPDATE devices SET reg_status = NULL WHERE server_id = '%i';", server_id);
    mysql_query(&mysql, buff);


    ptr = resp->next;

    while (ptr) {

        /* end of data */
        if (!strcasecmp(ami_get_packet_item_value(ptr, "Event"), "PeerlistComplete")) {
            break;
        }


        if (DEBUG) {

            sprintf(buff, "Event: %s", ami_get_packet_item_value(ptr, "Event"));
            my_debug(buff);

            sprintf(buff, "Channeltype: %s", ami_get_packet_item_value(ptr, "Channeltype"));
            my_debug(buff);

            sprintf(buff, "ObjectName: %s", ami_get_packet_item_value(ptr, "ObjectName"));
            my_debug(buff);

            sprintf(buff, "ChanObjectType: %s", ami_get_packet_item_value(ptr, "ChanObjectType"));
            my_debug(buff);

            sprintf(buff, "IPaddress: %s", ami_get_packet_item_value(ptr, "IPaddress"));
            my_debug(buff);

            sprintf(buff, "IPport: %s", ami_get_packet_item_value(ptr, "IPport"));
            my_debug(buff);

            sprintf(buff, "Dynamic: %s", ami_get_packet_item_value(ptr, "Dynamic"));
            my_debug(buff);

            sprintf(buff, "Natsupport: %s", ami_get_packet_item_value(ptr, "Natsupport"));
            my_debug(buff);

            sprintf(buff, "ACL: %s", ami_get_packet_item_value(ptr, "ACL"));
            my_debug(buff);

            sprintf(buff, "Status: %s", ami_get_packet_item_value(ptr, "Status"));
            my_debug(buff);

            my_debug("-------------");

        } // DEBUG

        /* update devices's reg_status based on its name */

        strcpy(status, ami_get_packet_item_value(ptr, "Status"));
        status[2] = '\0';

        if (!strcmp(status, "OK")) {
            /* always change device status to OK and it's server_id, because it means that device is registered to this server */
            sprintf(buff, "UPDATE devices SET reg_status = '%s', server_id = '%i'  WHERE name = '%s';", ami_get_packet_item_value(ptr, "Status"), server_id, ami_get_packet_item_value(ptr, "ObjectName"));
        } else {
            /* only change status which is not OK when device is registered on this server */
            sprintf(buff, "UPDATE devices SET reg_status = '%s' WHERE name = '%s' AND server_id = '%i';", ami_get_packet_item_value(ptr, "Status"), ami_get_packet_item_value(ptr, "ObjectName"), server_id);
        }

        mysql_query(&mysql, buff);


        if (DEBUG) {
            my_debug(buff);
        }


        ptr = ptr->next;
    }

    if (resp) {
        ami_destroy_packet_group(resp);
    }

    /* end sql transaction */
    //mysql_query(&mysql, "COMMIT;");


    mysql_close(&mysql);
    mysql_library_end();

    if (sock) {
        asterisk_close(sock);
    }


    //date time
    if (time(&now) != (time_t)(-1)) {
        struct tm *mytime = localtime(&now);

        if (mytime) {
            strftime(datetime, sizeof datetime, "%Y-%m-%d %T", mytime);
        }
    }

    sprintf(buff, "%s Peer status update completed.", datetime);
    my_debug(buff);

    return 0;

}
