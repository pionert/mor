<?php 
	// Author:        Ricardas Stoma
	// Company:       Kolmisoft
	// Year:          2013
	// About:         Script parses GET requests from C monitoring script and exports data to MySQL query file




	// --------------
	// USER VARIABLES
	// --------------
	
	$path       = "/var/www/html/monitor/query.sql";
	$batch_size = 200;

	// ----------------
	// SCRIPT VARIABLES
	// ----------------

	// ip address
	$ip = $_SERVER['REMOTE_ADDR'];

	// default data values
	$cpu_cores   = -1;
	$cpu_load    = -1;
	$ram_total   = -1;
	$ram_used    = -1;
	$ram_free    = -1;
	$ram_buffers = -1;
	$mysql       = -1;
	$httpd       = -1;
	$asterisk    = -1;
	$hdd         = -1;

	// ------------
	// SCRIPT START
	// ------------

	// get data
	if(isset($_GET['cpu_cores'])) $cpu_cores     = $_GET['cpu_cores'];
	if(isset($_GET['cpu_load'])) $cpu_load       = $_GET['cpu_load'];
	if(isset($_GET['ram_total'])) $ram_total     = $_GET['ram_total'];
	if(isset($_GET['ram_used'])) $ram_used       = $_GET['ram_used'];
	if(isset($_GET['ram_free'])) $ram_free       = $_GET['ram_free'];
	if(isset($_GET['ram_buffers'])) $ram_buffers = $_GET['ram_buffers'];
	if(isset($_GET['mysql'])) $mysql             = $_GET['mysql'];
	if(isset($_GET['httpd'])) $httpd             = $_GET['httpd'];
	if(isset($_GET['asterisk'])) $asterisk       = $_GET['asterisk'];
	if(isset($_GET['hdd'])) $hdd                 = $_GET['hdd'];

	$string = "$cpu_cores,$cpu_load,$ram_total,$ram_used,$ram_free,$ram_buffers,$mysql,$httpd,$asterisk,$hdd,(SELECT IF(EXISTS(SELECT id FROM servers WHERE ip='$ip'),(SELECT id FROM servers WHERE ip='$ip'),-1))";

	// check if file exist
	if(!file_exists($path)) {
		// if not, create
		$file = fopen($path, "w");
		flock($file, LOCK_EX);
		fprintf($file, "-- 000");
		flock($file, LOCK_UN);
		fclose($file);
	}

	// get data count
	$count = 0;
	$file  = fopen($path, "r+");
	flock($file, LOCK_EX);
	fseek($file, -3, SEEK_END);
	$count = fgets($file, 4);

	// if count is 0, insert header
	if($count == 0) {
		fseek($file, -6, SEEK_END);
		fprintf($file, "INSERT INTO server_monitorings(cpu_cores,cpu_load,ram_total,ram_used,ram_free,ram_buffers,mysql_service,httpd_service,asterisk_service,hdd,server_id) VALUES \n($string);\n");
	} else if($count == $batch_size) {
		fseek($file, -6, SEEK_END);
		fprintf($file, "INSERT INTO server_monitorings(cpu_cores,cpu_load,ram_total,ram_used,ram_free,ram_buffers,mysql_service,httpd_service,asterisk_service,hdd,server_id) VALUES \n($string);\n");
	} else {
		fseek($file, -8, SEEK_END);
		fprintf($file, ", \n($string);\n");
	}

	$count++;

	fseek($file, 0, SEEK_END);

	if($count - 1 == $batch_size) {
		fprintf($file, "-- 001");
	} else {
		fprintf($file, "-- %03d", $count);
	}

	flock($file, LOCK_UN);
	fclose($file);
?>
