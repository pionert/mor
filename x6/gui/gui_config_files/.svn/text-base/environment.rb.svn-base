# -*- encoding : utf-8 -*-
# Load the rails application
require File.expand_path('../application', __FILE__)
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

# Initialize the rails application
Mor::Application.initialize!

#---------------
ExceptionNotifier_exception_recipients = %w(gui_crashes@kolmisoft.com)
ExceptionNotifier_email_prefix = "[CLIENT] "

Default_Language = "en"

Debug_File = "/var/log/mor/gui_debug.log"

Default_Context = "mor"

Actual_Dir = "/home/mor"
Web_Dir = Rails.env.to_s == 'production' ? "/billing" : ''
Web_URL = "http://127.0.0.1"

Main_User_ID = 0

SERVER_ID = 1

F_BACKUPS = 0
