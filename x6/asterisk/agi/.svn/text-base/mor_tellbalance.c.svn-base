/*
*
*	MOR TellBalance AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2008-2011
*
*	v0.1.15
*
* 	2011.03.14 v0.1.15 BUG fix - Tell cents
* 	2011.02.25 v0.1.14 BUG fix - Tell currency
* 	2011.02.11 v0.1.13 Tell cents/Tell Currency implemented
*	2010.11.15 v0.1.12 Sound structure changed
* 	2010.10.18 v0.1.11 BUG fix for proper tax handling and ghost balance support
*	2010.10.11 v0.1.10 BUG fix with ANIPIN currency/language retrieval
*	2010.09.27 v0.1.9 BUG fix with ANIPIN currency/language retrieval
* 	2010.01.11 v0.1.8 BUG fix with ANIPIN
* 	2010.01.08 v0.1.7 BUG fix with accountcode
* 	2009.11.24 v0.1.6 Support for ANIPIN dp with *
* 	2009.02.17 v0.1.5 +VAT
*	2009.02.01 v0.1.4 Ghost_percent disabled, card red by MOR_CARD_ID
* 	2008.07.15 v0.1.3 Handle balance < 0 (Tell "minus")
* 	2008.06.09 v0.1.2 Use mor_agi_functions
* 	2008.05.06 v0.1.1 Handle balance < 0 (*-1)
*
*	This AGI tells balance to user or card owner
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>


#include "mor_agi_functions.c"


    /* taxes */ 
    int tax_compound = 0; 
    //int tax1_enabled; // tax1 is always enabled 
    int tax2_enabled = 0; 
    int tax3_enabled = 0; 
    int tax4_enabled = 0; 
    float tax1_value = 0; 
    float tax2_value = 0; 
    float tax3_value = 0; 
    float tax4_value = 0; 


    int got_user = 0;
    int got_card = 0;

    int accountcode = 0;
    int card_id = 0;


    MYSQL_RES   *result;
    MYSQL_ROW   row;



void mor_get_taxes(); 
float mor_count_taxes(float amount); 



/*	Main function	*/

int main(int argc, char *argv[])
{
	char buff[100];
	char str[100];
	int i;

	time_t now;


	char *variable;
	char *value;

	// variables
	
	char extension[50];

	double balance;
	double vat_percent;
	double converted_balance;
	int dialplan_id;

	char currency[10];
	char language[10];
	double exchange_rate;
	char usercard[20];

	char callerid[30];
	char device_pin[30];

	int anipin = 0;
	
	int tell_cents = 1;
	char tell_currency[10] = "";
	
	//----------------

	char card_pin[30];
	double ghost_min_perc;

	int retries;

	int tell_minus = 0;

        float ghost_balance_perc = 0;



	// initial values
	strcpy(extension, "");
	balance = 0.0;
	vat_percent = 0.0;
	converted_balance = 0.0;
	dialplan_id = 0;
	strcpy(currency, "");
	strcpy(language, "en");
	exchange_rate = 1;
	strcpy(usercard, "");

	got_user = 0;
	strcpy(device_pin, "");

	strcpy(card_pin, "");
	ghost_min_perc = 100;
	got_card = 0;


//	strcpy(datetime,"");

	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR TellBalance AGI script started.", 0);


	// DB connection
	read_config();

//	sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
//	AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
			
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    AGITool_Destroy(&agi);
	    return 0;
	} else {
	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}


	// ANIPIN?

        AGITool_get_variable2(&agi, &res, "MOR_ANIPIN_USED", buff, sizeof(buff));
	if (buff) {
	    anipin = atoi(buff);

	    sprintf(str, "ANIPIN Used: %i", anipin);
	    AGITool_verbose(&agi, &res, str, 0);
	    
	}


	// Dial-Plan ID

        AGITool_get_variable2(&agi, &res, "MOR_DP_ID", buff, sizeof(buff));
	if (buff) {
	    dialplan_id = atoi(buff);

	    sprintf(str, "Dial Plan ID: %i", dialplan_id);
	    AGITool_verbose(&agi, &res, str, 0);
	}


	// Card ID

        AGITool_get_variable2(&agi, &res, "MOR_CARD_ID", buff, sizeof(buff));
	if (buff) {
	    card_id = atoi(buff);

	    sprintf(str, "Card ID: %i", card_id);
	    AGITool_verbose(&agi, &res, str, 0);
	}



	// tell cents
        AGITool_get_variable2(&agi, &res, "MOR_CC_TELL_CENTS", buff, sizeof(buff));
	if ((buff) && (strlen(buff))) {
	    tell_cents = atoi(buff);
	    sprintf(str, "Tell Cents Used: %i", tell_cents);
	    AGITool_verbose(&agi, &res, str, 0);
	}


	// tell currency
        AGITool_get_variable2(&agi, &res, "MOR_CC_TELL_CURRENCY", buff, sizeof(buff));
	if (buff) {
	    strcpy(tell_currency ,buff);
	    sprintf(str, "Tell Currecy Used: %s", tell_currency);
	    AGITool_verbose(&agi, &res, str, 0);
	}





//	if ((!card_id) && (!anipin)) {
	if ((!card_id) && (dialplan_id)) {	// search for Local user or ANIPIN, because they use Dial Plan to store Currency/language options
	
	// ------- get dp details -----

	sprintf(sqlcmd, "SELECT dialplans.data3, dialplans.data4, currencies.exchange_rate, dialplans.data5 FROM dialplans JOIN currencies ON (dialplans.data3 = currencies.name) WHERE dialplans.id = '%i';", dialplan_id);

//	sprintf(str, "SQL: %s", sqlcmd);
//	AGITool_verbose(&agi, &res, str, 0);
	
        if (mysql_query(&mysql,sqlcmd)) {    
    	    // error
            //res = -1;
        } else {
        // query succeeded, process any data returned by it
    	    result = mysql_store_result(&mysql);
    	    if (result) {
    	    // there are rows
        	//i = 0;
                while ((row = mysql_fetch_row(result))) {	
                    if (row[0]) strcpy(currency,row[0]); 
                    if (row[1]) strcpy(language,row[1]); 
                    if (row[2]) exchange_rate = atof(row[2]); 
                    if (row[3]) strcpy(usercard,row[3]); 
		    
            	}
        	mysql_free_result(result);
            } 
        }

//    	AGITool_set_variable(&agi, &res, "BLA", extension);

	sprintf(str, "Currency: %s, language: %s, exchange rate: %f, user or card: %s", currency, language, exchange_rate, usercard);
	AGITool_verbose(&agi, &res, str, 0);



	if (strcmp(language, "en")){
	    AGITool_set_variable(&agi, &res, "CHANNEL(language)", language);

	    sprintf(str, "Language changed to: %s",language);
	    AGITool_verbose(&agi, &res, str, 0);
	        
	}


	} else { // card_id > 0 (anipin uses DP, so currency/language is set in DP values)

	    if (card_id){
		sprintf(usercard, "%s", "card"); 
	    } else {
		sprintf(usercard, "%s", "user"); 
	    }

	    sprintf(sqlcmd, "SELECT name, exchange_rate FROM currencies WHERE id = '1';");
	
    	    if (mysql_query(&mysql,sqlcmd)) {    
    		// error
        	//res = -1;
    	    } else {
    	    // query succeeded, process any data returned by it
    		result = mysql_store_result(&mysql);
    		if (result) {
    		// there are rows
        	    //i = 0;
            	    while ((row = mysql_fetch_row(result))) {	
                	if (row[0]) strcpy(currency,row[0]); 
            		if (row[2]) exchange_rate = atof(row[1]); 		    
            	    }
        	    mysql_free_result(result);
        	} 
    	    }

	    sprintf(str, "Currency: %s, exchange rate: %f, user or card: %s", currency, exchange_rate, usercard);
    	    AGITool_verbose(&agi, &res, str, 0);
    
	}



	AGITool_answer(&agi, &res);


	if (!strcmp(usercard, "user")){


	    // =========== search by Accountcode ==============

    	    // Account Code

	    if (!anipin){
		accountcode = atoi(AGITool_ListGetVal(agi.agi_vars, "agi_accountcode"));
	    } else {

    		AGITool_get_variable2(&agi, &res, "MOR_ANIPIN_USED", buff, sizeof(buff));
		if (buff) {
		    AGITool_get_variable2(&agi, &res, "MOR_DEVICE_ID", buff, sizeof(buff));
		    accountcode = atoi(buff);
		
		    if (!accountcode){
			accountcode = atoi(AGITool_ListGetVal(agi.agi_vars, "agi_accountcode"));
		    }
		    
		}
	    
	    }

	    sprintf(str, "Accountcode: %i", accountcode);
	    AGITool_verbose(&agi, &res, str, 0);


	    // ------- get user details -----

	    sprintf(sqlcmd, "SELECT users.balance, users.vat_percent FROM devices JOIN users ON (devices.user_id = users.id) WHERE devices.id = '%i';", accountcode);

	    //	sprintf(str, "SQL: %s", sqlcmd);
    	    //	AGITool_verbose(&agi, &res, str, 0);
	
    	    if (mysql_query(&mysql,sqlcmd)) {    
    		// error
    	    } else {
    	    // query succeeded, process any data returned by it
    		result = mysql_store_result(&mysql);
    		if (result) {
    		    // there are rows
        	    //i = 0;
            	    while ((row = mysql_fetch_row(result))) {	
                	if (row[0]) balance = atof(row[0]); 
                	if (row[1]) vat_percent = atof(row[1]);
            		got_user = 1;
		    }
        	    mysql_free_result(result);
        	} 
    	    }



	    // ================== search by CallerID using ANI ==========
	    if (!got_user){


    	        // CallerID
    		AGITool_get_variable2(&agi, &res, "CALLERID(num)", buff, sizeof(buff));
		if (buff) {
		    strcpy(callerid, buff);
		} else {
		    strcpy(callerid, "");		
		}


		if (strlen(callerid) > 0){

		    sprintf(str, "User not found by accountcode, will search using ANI by CallerID: %s", callerid);
		    AGITool_verbose(&agi, &res, str, 0);


		    sprintf(sqlcmd, "SELECT users.balance, users.vat_percent FROM devices JOIN users ON (devices.user_id = users.id) JOIN callerids ON (callerids.device_id = devices.id) WHERE callerids.cli = '%s';", callerid);

		    //sprintf(str, "SQL: %s", sqlcmd);
    		    //AGITool_verbose(&agi, &res, str, 0);
	
    		    if (mysql_query(&mysql,sqlcmd)) {    
    			// error
    		    } else {
    			// query succeeded, process any data returned by it
    			result = mysql_store_result(&mysql);
    			if (result) {
    			    // there are rows
        		    //i = 0;
            		    while ((row = mysql_fetch_row(result))) {	
                		if (row[0]) balance = atof(row[0]); 
    	            		if (row[1]) vat_percent = atof(row[1]);                		
            			got_user = 1;
			    }
        		    mysql_free_result(result);
        		} 
    		    }
		}    
	    }


	    // ================== search user by PIN ==========
	    if (!got_user){


		AGITool_verbose(&agi, &res, "User not found by CallerID using ANI, will ask PIN now", 0);



		retries = 0;
		do {
		    

		    // ask device pin 
		    AGITool_get_data(&agi, &res, "mor/ivr_voices/enter_pin", 10000, 30);
	
		    strcpy(device_pin, res.result);
		    sprintf(str, "PIN entered: %s", device_pin);
		    AGITool_verbose(&agi, &res, str, 0);


		    // ------- get user details -----

		    if (strlen(device_pin) > 0){

			sprintf(sqlcmd, "SELECT users.balance, users.vat_percent FROM devices JOIN users ON (devices.user_id = users.id) WHERE devices.pin = '%s';", device_pin);

			//sprintf(str, "SQL: %s", sqlcmd);
    			//AGITool_verbose(&agi, &res, str, 0);
	
    			if (mysql_query(&mysql,sqlcmd)) {    
    			    // error
    			} else {
    			    // query succeeded, process any data returned by it
    			    result = mysql_store_result(&mysql);
    			    if (result) {
    			        // there are rows
            			while ((row = mysql_fetch_row(result))) {	
                		    if (row[0]) balance = atof(row[0]); 
    	            		    if (row[1]) vat_percent = atof(row[1]);     
            			    got_user = 1;
				}
        			mysql_free_result(result);
        		    } 
    			}
		
		    }
	    
		    if (!got_user){	    
			AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/auth_failed");
		    }


		    retries += 1;
		} while ((!got_user)&&(retries < 3));
	    }


	    if (got_user){
		sprintf(str, "User found! Balance: %f, vat_percent: %f", balance, vat_percent);
		AGITool_verbose(&agi, &res, str, 0);
	    }
	


	} else {
	    // card
	    

	    retries = 0;
	    do {
		    

		// ------- get card details -----


		
		if (!card_id){
    		    // ask card pin because we do not know card_id
		    AGITool_get_data(&agi, &res, "mor/ivr_voices/enter_pin", 10000, 30);
	
		    strcpy(card_pin, res.result);
		    sprintf(str, "PIN entered: %s", card_pin);
		    AGITool_verbose(&agi, &res, str, 0);


		    sprintf(sqlcmd, "SELECT cards.balance, cardgroups.ghost_min_perc, cardgroups.vat_percent, cardgroups.ghost_balance_perc FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) WHERE cards.pin = '%s';", card_pin);
		} else {
		    // we know card_id so we can find card right away!

		    sprintf(sqlcmd, "SELECT cards.balance, cardgroups.ghost_min_perc, cardgroups.vat_percent, cardgroups.ghost_balance_perc FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) WHERE cards.id = '%i';", card_id);
		}
	


		//	sprintf(str, "SQL: %s", sqlcmd);
    		//	AGITool_verbose(&agi, &res, str, 0);
	
    		if (mysql_query(&mysql,sqlcmd)) {    
    		    // error
        	    //res = -1;
    		} else {
    		    // query succeeded, process any data returned by it
    		    result = mysql_store_result(&mysql);
    		    if (result) {
    			// there are rows
        		//i = 0;
            		while ((row = mysql_fetch_row(result))) {	
                	    if (row[0]) balance = atof(row[0]); 
                	    if (row[1]) ghost_min_perc = 100;	//atof(row[1]); 
                	    if (row[2]) vat_percent = atof(row[2]); 
                	    if (row[3]) ghost_balance_perc = atof(row[3]); 
                	    
            		    got_card = 1;
			}
        		mysql_free_result(result);
        	    } 
    		}
		
	    
		if (got_card){

		    sprintf(str, "Balance: %f, ghost min perc: %f %, vat_percent: %f, ghost_balance_perc: %f", balance, ghost_min_perc, vat_percent, ghost_balance_perc);
		    AGITool_verbose(&agi, &res, str, 0);

		    // should not be counted here
		    //balance = (balance + (balance / 100 * vat_percent));
		    
		    balance = balance / 100 * ghost_balance_perc;

		    sprintf(str, "Balance with Ghost balance percent: %f", balance);
		    AGITool_verbose(&agi, &res, str, 0);


		} else {
	    
		    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/auth_failed");
		}


		retries += 1;
	    } while ((!got_card)&&(retries < 3));
	    

	
	}






	
	if ( (got_user) || (got_card) ){


	    mor_get_taxes();

	    // calculate vat
	    //balance = (balance + (balance / 100 * vat_percent));

	    balance = mor_count_taxes(balance);
	    

	    // Convert balance
	    if (exchange_rate)
		converted_balance = balance * exchange_rate;
	    else
		converted_balance = balance;

	    sprintf(str, "Balance with TAX: %f, Converted balance: %f %s", balance, converted_balance, currency);
	    AGITool_verbose(&agi, &res, str, 0);


	    /* currency conversion */ 
    	    if ((strcmp(currency, tell_currency)) && (strlen(tell_currency)) ) { 

	        converted_balance = mor_convert_currency(converted_balance, currency, tell_currency); 
                strcpy(currency, tell_currency); 
		
	    }
	    

	    if (converted_balance < 0){
		converted_balance = converted_balance * (-1);
		tell_minus = 1;	
	    }



	// Tell balance
	
	    div_t resultm; 
	    char curr_many[100], curr_one[100], curr_cents[100]; 


	    resultm.quot = converted_balance;
	    resultm.rem = rint((converted_balance - resultm.quot)*100);
	
    	    //formating sound files based on currency
    	    sprintf(curr_many, "mor/ivr_voices/%s_many", currency);
	    sprintf(curr_one, "mor/ivr_voices/%s_one", currency);
	    sprintf(curr_cents, "mor/ivr_voices/%s_cents", currency);


	    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/you_have");

	    if (tell_minus)
		AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/minus");


	    if (resultm.quot > 0) {
		AGITool_say_number(&agi, &res, resultm.quot, "");
	    } 

	    
	    if ( resultm.quot == 1 ) {
		AGITool_exec(&agi, &res, "PLAYBACK", curr_one);
	    } else
	        if (resultm.quot > 1) {
		    AGITool_exec(&agi, &res, "PLAYBACK", curr_many);
		}	    

	
	    if (tell_cents) {
	
		if (resultm.quot > 0 && resultm.rem > 0) {
		    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/and");
		}
	
		if ( resultm.rem > 0) {
		    AGITool_say_number(&agi, &res, resultm.rem, "");		
		    AGITool_exec(&agi, &res, "PLAYBACK", curr_cents);
		}		
	    
	    }


	    // zero balance	    
	    if (( resultm.quot == 0) && ( resultm.rem == 0)) {
		AGITool_say_number(&agi, &res, resultm.rem, "");		
		AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/balance_empty");

	    }		
	    


	}



	AGITool_verbose(&agi, &res, "MOR TellBalance AGI script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);
	mysql_close(&mysql);  

	return 0;
}



void mor_get_taxes(){


    char sqlcmd[2048] = "";
//    MYSQL_RES   *result;
//    MYSQL_ROW   row;
//   int res=0;
                    

    char buff[1024] = "";


    if (got_user){
	/* sql for user */
        sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN users ON (taxes.id = users.tax_id) JOIN devices ON (devices.user_id = users.id) WHERE devices.id = %i;", accountcode);        
    } else {
	/* sql for card */
	sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN cardgroups ON (taxes.id = cardgroups.tax_id) JOIN cards ON (cards.cardgroup_id = cardgroups.id) WHERE cards.id = %i;", card_id);	
    }


//	    sprintf(buff, "SQL: %s\n", sqlcmd);
//	    AGITool_verbose(&agi, &res, buff, 0);

    		if (mysql_query(&mysql,sqlcmd)) {    
    		    // error
        	    //res = -1;
    		} else {
    		    // query succeeded, process any data returned by it
    		    result = mysql_store_result(&mysql);
    		    if (result) {
    			// there are rows
        		//i = 0;
            		while ((row = mysql_fetch_row(result))) {	

			    //row[0] id
			    if (row[1]) tax_compound = atoi(row[1]);
			    if (row[2]) tax2_enabled = atoi(row[2]);
			    if (row[3]) tax3_enabled = atoi(row[3]);
			    if (row[4]) tax4_enabled = atoi(row[4]);
	    		    if (row[5]) tax1_value = atof(row[5]);
			    if (row[6]) tax2_value = atof(row[6]);
			    if (row[7]) tax3_value = atof(row[7]);
			    if (row[8]) tax4_value = atof(row[8]);


			}
        		mysql_free_result(result);
        	    } 
    		}


	    sprintf(buff, "Compound tax: %i, Enabled? tax2: %i, tax3: %i, tax4: %i, Values: tax1: %f, tax2: %f, tax3: %f, tax4: %f\n", tax_compound, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value);
	    AGITool_verbose(&agi, &res, buff, 0);
	
}


/* returns amount with taxes  */
float mor_count_taxes(float amount){


    float new_amount = amount;

    /* tax1 calculation */
    new_amount += amount / 100 * tax1_value;
    
    /* tax2 calculation */
    if (tax2_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax2_value;
	} else {
	    new_amount += amount / 100 * tax2_value;
	}

    /* tax3 calculation */
    if (tax3_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax3_value;
	} else {
	    new_amount += amount / 100 * tax3_value;
	}

    /* tax4 calculation */

    if (tax4_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax4_value;
	} else {
	    new_amount += amount / 100 * tax4_value;
	}

    return new_amount;

}
