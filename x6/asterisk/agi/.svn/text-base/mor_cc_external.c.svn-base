/*
*
*	MOR Acc2User AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2010
*
*	v0.1
*
* 	2010.07.27 v0.1 Release
*
*	This AGI takes data from MOR core and modifies TELL BALANCE, TELL TIME, REAL TIMEOUT for Calling Card engine
* 	This allows for Users to change this script and control these values in the way they want it and make fancy ways how CC engine works
*	Main purpose of this script is to give Users of MOR power to create different ways to 
*		trick CC Users to hear what balance/time they have or to kill their calls from time to time to maximise profit
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "mor_agi_functions.c"


    /* variables(vars) */

    /* common vars */
    int accountcode;
    int card_id = 0;
    int card_group_id = 0;
    char card_pin[100] = "";
    char card_number[100] = "";
    float card_balance = 0;

    char script_type[100] = "";

    /* script type specific vars */
    float card_tell_balance = 0;
    
    int card_tell_time = 0;
    int card_real_timeout = 0;
    int card_timeout = 0;


    /* functions */
    void read_vars_from_mor_core();
    void modify_vars();
    void send_vars_to_mor_core();




/*	Main function	*/

int main(int argc, char *argv[])
{

	/* init environment */	
	AGITool_Init(&agi);
	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR CC External Script started.", 0);


	/* Read channel variables from MOR Core */
	/* These values later can be used in manipulating data */
	read_vars_from_mor_core();

	/* Change variables */
	modify_vars();
	
	/* Send modified variables back to MOR Core */
	send_vars_to_mor_core();

	

	
	/* detroy environment */
	AGITool_verbose(&agi, &res, "MOR CC External Script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);
	AGITool_Destroy(&agi);
	return 0;
}




/* This function is most important - it modifies variables which will be later sent to MOR Core */
void modify_vars(){

    char buff[2048];
    char str[2048];

    float old_card_tell_balance = 0;

    int old_card_tell_time = 0;
    int old_card_timeout = 0;

    /* Here we will modify what balance to tell to User which his Card has, e.g. it sends value to Tell Balance function in MOR Core */
    /* It can be used to trick Calling Card Owner to think he has more money on his Card than he really has */
    if (!strcmp(script_type, "before_tell_balance")){

	/* Save old Card Tell Balance just for informational purposes */
	old_card_tell_balance = card_tell_balance;	    
	/* Change value card_tell_balance to anything you want, we will keep it unchanged in this demo script */
	card_tell_balance = card_tell_balance + 0;
    
	sprintf(str, "Tell balance changed from: %f to: %f", old_card_tell_balance, card_tell_balance);
        AGITool_verbose(&agi, &res, str, 0);
	
    }




    if (!strcmp(script_type, "before_tell_time")){


	/* Here we will modify what time to tell to User which his Card has, e.g. it sends value to Tell Time function in MOR Core */
	/* It can be used to trick Calling Card Owner to think he has more time on his Card than he really has */
	

	/* Save old Card Tell Time just for informational purposes */
	old_card_tell_time = card_tell_time;	    
	/* Change value card_tell_time to anything you want, we will keep it unchanged in this demo script */
	card_tell_time = card_tell_time + 0;
    
	sprintf(str, "Tell time changed from: %i to: %i seconds", old_card_tell_time, card_tell_time);
        AGITool_verbose(&agi, &res, str, 0);


	/* ------------------------------------------------------------------------------------------------------ */
	


	/* Here we will modify the REAL duration of the call which will be used by MOR Core */
        /* Timeout */
	/* How long call will last in reality in MOR Core */
        /* This value can be changed and it will be passed back to MOR Core */
	/* It can be used to shorten some of the calls randomly or even drop some of them "occasionally" */ 
	
	/* IMPORTANT: timeout <= 0 cannot exist, call will terminate, be carefull to not put it higher then value from MOR Core - otherwise you will take loss */

	/* Save old Card Timeout just for informational purposes */
	old_card_timeout = card_timeout;	    
	/* Change value card_timeout to anything you want, we will keep it unchanged in this demo script */
	card_timeout = card_timeout - 0;
    
	sprintf(str, "Call timeout changed from: %i to: %i seconds", old_card_timeout, card_timeout);
        AGITool_verbose(&agi, &res, str, 0);

	if (old_card_timeout < card_timeout){
    	    sprintf(str, "WARNING! New timeout is greater then original timeout - you will take loss for sure!", old_card_timeout, card_timeout);
    	    AGITool_verbose(&agi, &res, str, 0);
        }

    }

}





void send_vars_to_mor_core(){

    char buff[2048];
    char str[2048];

    if (!strcmp(script_type, "before_tell_balance")){
        sprintf(buff, "%f", card_tell_balance);
	AGITool_set_variable(&agi, &res, "MOR_CC_TELL_BALANCE", buff);
    }


    if (!strcmp(script_type, "before_tell_time")){
        sprintf(buff, "%i", card_tell_time);
	AGITool_set_variable(&agi, &res, "MOR_CC_TELL_TIME", buff);

        sprintf(buff, "%i", card_timeout);
	AGITool_set_variable(&agi, &res, "MOR_CC_TIMEOUT", buff);

    }


}





void read_vars_from_mor_core(){


	char buff[2048];
	char str[2048];


	/* Accountcode */
	accountcode = atoi(AGITool_ListGetVal(agi.agi_vars, "agi_accountcode"));
	sprintf(str, "Accountcode: %i", accountcode);
	AGITool_verbose(&agi, &res, str, 0);
    
	/* Card ID */
        AGITool_get_variable2(&agi, &res, "MOR_CC_ID", buff, sizeof(buff));
        if (buff) {
            card_id = atoi(buff);        
            sprintf(str, "Card ID: %i", card_id);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* Card Group ID */
        AGITool_get_variable2(&agi, &res, "MOR_CC_GROUP_ID", buff, sizeof(buff));
        if (buff) {
            card_group_id = atoi(buff);        
            sprintf(str, "Card Group ID: %i", card_id);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* Card NUMBER */
        AGITool_get_variable2(&agi, &res, "MOR_CC_NUMBER", buff, sizeof(buff));
        if (buff) {
            strcpy(card_number, buff);        
            sprintf(str, "Card NUMBER: %s", card_number);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* Card PIN */
        AGITool_get_variable2(&agi, &res, "MOR_CC_PIN", buff, sizeof(buff));
        if (buff) {
            strcpy(card_pin, buff);        
            sprintf(str, "Card PIN: %s", card_pin);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* Card Balance */
        AGITool_get_variable2(&agi, &res, "MOR_CC_BALANCE", buff, sizeof(buff));
        if (buff) {
            card_balance = atof(buff);        
            sprintf(str, "Card Balance: %f", card_balance);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* Script Type */
        AGITool_get_variable2(&agi, &res, "MOR_CC_TYPE", buff, sizeof(buff));
        if (buff) {
            strcpy(script_type, buff);        
            sprintf(str, "Script type: %s", script_type);
            AGITool_verbose(&agi, &res, str, 0);
        }

	/* read specific vars for 'before_tell_balance' type script */
	if (!strcmp(script_type, "before_tell_balance")){

	    /* Tell Balance */
    	    AGITool_get_variable2(&agi, &res, "MOR_CC_TELL_BALANCE", buff, sizeof(buff));
    	    if (buff) {
        	card_tell_balance = atof(buff);        
        	sprintf(str, "Tell balance: %f", card_tell_balance);
        	AGITool_verbose(&agi, &res, str, 0);
    	    }
	
	}


	/* read specific vars for 'before_tell_time' type script */
	if (!strcmp(script_type, "before_tell_time")){

	    /* Tell Time */
	    /* This time will be told to the final user */
    	    AGITool_get_variable2(&agi, &res, "MOR_CC_TELL_TIME", buff, sizeof(buff));
    	    if (buff) {
        	card_tell_time = atoi(buff);        
        	sprintf(str, "Tell time: %i seconds", card_tell_time);
        	AGITool_verbose(&agi, &res, str, 0);
    	    }

	    /* Real Timeout */
	    /* how long user can talk counted based on his balance */
	    /* this variable is used to calculate Tell Time in MOR Core like this: Real Timeout * Ghost Time Percent, use this for your own calculations here if you wish */
    	    /* you can count Ghost Time Percent used in MOR Core like this: Ghost Time Percent = Tell Time / Real Timeout */
    	    AGITool_get_variable2(&agi, &res, "MOR_CC_REAL_TIMEOUT", buff, sizeof(buff));
    	    if (buff) {
        	card_real_timeout = atoi(buff);        
        	sprintf(str, "Real Timeout: %i seconds", card_real_timeout);
        	AGITool_verbose(&agi, &res, str, 0);
    	    }
	
	    /* Timeout */
	    /* How long call will last in reality in MOR Core */
	    /* This value can be changed and it will be passed back to MOR Core */
	    /* It can be used to shorten some of the calls randomly or even drop some of them "occasionally" */ 
    	    AGITool_get_variable2(&agi, &res, "MOR_CC_TIMEOUT", buff, sizeof(buff));
    	    if (buff) {
        	card_timeout = atoi(buff);        
        	sprintf(str, "Timeout: %i seconds", card_timeout);
        	AGITool_verbose(&agi, &res, str, 0);
    	    }
	
	
	}


}



