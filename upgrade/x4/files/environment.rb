# -*- encoding : utf-8 -*-
# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Mor::Application.initialize!

#---------------
ExceptionNotifier_exception_recipients = %w(support@kolmisoft.com)
ExceptionNotifier_email_prefix = "[CLIENT] "

Default_Language = "en"
#---------------

Debug_File = "/tmp/mor_debug.log"

Please_Login_Context = "please_login"
Default_Context = "mor"

Recordings_Folder = "http://192.168.0.122/mor/recordings/"

Actual_Dir = "/home/mor"
Web_Dir = Rails.env.to_s == 'production' ? "/billing" : ''
Web_URL = "http://192.168.0.122"

Main_User_ID = 0

# ------- Functionality ------

F_BACKUPS = 0

# --------- ADDONS ---------


CC_Single_Login = 0
AD_sounds_path = "/var/lib/asterisk/sounds/mor/ad"
C2C_Active = 0
CALLC_Active = 0
CCLASS_Active = 0

AD_Active = 1
CC_Active = 1
RS_Active = 1
SMS_Active = 1
REC_Active = 1
PG_Active = 1
MA_Active = 1
CS_Active = 1
SKP_Active = 1
RSPRO_Active = 1




