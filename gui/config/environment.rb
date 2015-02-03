# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
 ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.6'

RAILS_ROOT = "/home/mor"

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.server_settings = {
# :address => "mail.softcom.lt",
# :port => 25,
#  :domain => "norby",
#  :authentication => :login,
# :user_name => "test",
#  :password => "test",
#}
#ActionMailer::Base.perform_deliveries = true
#ActionMailer::Base.default_charset = "utf-8"

# WAP support
Mime::Type.register "text/vnd.wap.wml", :wml

# Include your application configuration below

ExceptionNotifier.exception_recipients = %w(support@kolmisoft.com)
ExceptionNotifier.email_prefix = "[CLIENT] "

Debug_File = "/tmp/mor_debug.txt"

Please_Login_Context = "please_login"
Default_Context = "mor"


Recordings_Folder = "http://127.0.0.1/billing/recordings/"

Actual_Dir = "/home/mor"
Web_Dir = "/billing"
Web_URL = "http://127.0.0.1"

Main_User_ID = 0

# ------- Functionality ------

F_BACKUPS = 0

# --------- ADDONS ---------

# Calling Cards
CC_Active = 1
CC_Single_Login = 0

#Auto-Dialer
AD_Active = 1
AD_sounds_path = "/var/lib/asterisk/sounds/mor/ad"

#Reseller Addon
RS_Active = 1

#SMS Addon
SMS_Active = 1

# Recording Addon
REC_Active = 1

# Payment Gateway Addon
PG_Active = 1

# Call Shop Addon
CS_Active = 1

