# Author: Martynas Margis
# Year:   2010
# About:  Reports result of passed test to a test Brain
#
# Params:
# version - version of software that was tested (8, 9, trunk)
# revision - revision number that was tested. Any string.
# test - name of the test without a file extension.
# status - status of the test OK or FAILED
#
# Example:
# ruby lib/reporter.case 8 6000 cli OK
#
# Returns:
# Json status report that contains 2 params
# Always:
# Status - status of the report "RECEIVED" or "ERROR"
# Message - message explaining the error or containing some aditional information
#
# Example:
# {"status":"RECEIVED","message":""}
# {"status":"ERROR","message":"test_not_found"}
#

require 'rubygems'
require 'rest-client'
require 'net/http'
require 'yaml'

class Poster

  def initialize(version, revision, test, status, service_down, files_args = [])
    puts "initialize(version = #{version}, revision = #{revision}, test = #{test}, status = #{status})"
    puts File.expand_path('../config.yml', __FILE__)
    @config = YAML::load( File.open(File.expand_path('../config.yml', __FILE__)))["reporter"]
    @debug = (@config["debug"].to_i == 1)
    puts "INITIALIZING" if @debug

    url = @config["url"]
    urn = @config["urn"]
    @uri = "#{url}/#{urn}"
    @version = version
    @revision = revision
    @test = test.gsub(".rb", "")
    @test = @test.gsub(/^.*\/selenium\/tests\//, "")
    @service_down =  service_down.to_s == 'OK' ? '' : service_down
    @files = {
      :my_debug => "",
      :crash_log=> "",
      :production_log=> "",
      :access_log=> "",
      :error_log=> "",
      :selenium_server_log=> "",
      :test_system_log=> "",
      :extra_log=> "",
      :test_log => ""}
    files_args.each{|file|
      arg = file.split(" ")
      @files[arg[0].to_sym] = arg[1].to_s if @files[arg[0].to_sym] == ""
    }
    # type = @test.scan(/(\.rb|\.case)/) # for future use when you want to submit not only .case but unit tests also.
    @test.gsub!(/(\.rb|\.case)$/, "")
    @status = status
    
    net_line = `/bin/netstat -nr | grep "^0.0.0.0"`.split(/\s+/)
    interface = net_line[7]
    net_line = `/sbin/ifconfig #{interface} | grep HWaddr`
    @mac = net_line.scan(/HWaddr (([a-zA-Z0-9][a-zA-Z0-9]:){5}[a-zA-Z0-9][a-zA-Z0-9])/)[0][0].upcase
    net_line = `/sbin/ifconfig #{interface} | grep 'inet addr:'`
    @ip = net_line.scan(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)[0]
  end

  def send_request
    if @debug
      puts "SENDING"
      puts "  >> Status: #{@status}"
      puts "  >> Test: #{@test}"
      puts "  >> URL : #{@uri.inspect}"
      puts "  >> IP : #{@ip}"
      puts "  >> Service down : #{@service_down}"
    end   
    request_hash = {
      :version => @version,
      :revision => @revision,
      :test => @test,
      :status => @status,
      :mac => @mac,
      :ip => @ip,
      :service_down => @service_down
    }
    if @debug
      puts "FILES"
      puts @files.inspect
    end

    @files.each{|key, value|
      if value and value.to_s != "" and File.exists?(value)
        request_hash[key] = File.read(value)
      else
        request_hash[key] = ""
      end
    }
    
    if @debug
      puts "FINAL REQUEST HASH ==============================="
      puts request_hash.inspect
    end
    begin
      res = RestClient.post(@uri, request_hash)
      puts res.body
    rescue Exception => e
      puts "Respons failed #{e.message}"
    end
  end

end

@help_text =
  "Wrong number of arguments. (#{ARGV.size} for 4)
Usage 'ruby reported.rb version revision test status' 'log_type log_file_path' .....
  version: version that was tested 9, 8, trunk
  revision : revision that was tested
  test : test file name without extension
  status: OK or FAILED
  service down: OK or Message
  log files: use format 'log_file_type log_file_path',
    supported log_file_types:
      my_debug, crash_log, production_log, access_log, error_log, selenium_server_log, test_system_log, extra_log
    log_file_path should contain no spaces

"

if ARGV.size < 5 or !["OK", "FAILED"].include?(ARGV[3])
  puts @help_text
else
  puts "OK #{ARGV.inspect}"
  
  p = Poster.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5..-1])
  p.send_request()
end