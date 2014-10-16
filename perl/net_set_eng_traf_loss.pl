# About: 
# Energy: sum all listen and transmit ticks for all nodes from the output of powertrace lines in the plugin 'Contiki Test Editor' 
# Network Setup Time: find time of first DIO sent and last DIO joined
# Network Traffic: count DIS, DIO, DAO
# Latency: compute latency of packets send from each node to sink
# Parameters: change the no of nodes below: $totalnodes and $resultdir
# Usage: perl network_power_consumption.pl logfile: where logfile is the log of all printfs from Cooja, plugin 'Contiki Test Editor'

#!/usr/bin/perl

$totalnodes = 20; $resultdir="/home/user/ftp/"; 
# assign the array ARGV to string separating each item by space
$mystring=join(" ",@ARGV); 
# just for debug 
# print "mystring=" .$mystring ."\n";
# extract logfile name, probably pwrline.log, format of input file is : string.string 
# if ($mystring=~m/(\w+\.\w+)/) {$logfile=$1;} elsif ($mystring=~m/\s(-)($|\s)/){$logfile=$1;}
$logfile= @ARGV[0];
# you can pipe the input (logfile) file 
if ($logfile eq "" || $logfile eq "-" ){
	open ($fh_pipedlog,'>', "pipedlog.log") or die $!; 
	foreach $line (<STDIN>) {
		print $fh_pipedlog $line; 
	}
	close $fh_pipedlog;
	# update filelog
	$logfile="pipedlog.log";
	print "Received log from pipe.\n";
} 


# call to the required function   
 networksetuptime();
 energy();
 networktraffic();
 networklatency();

#---------------------------------------------------------------------------
sub energy {
	# set the output  (result) file name 
	$resultlog="network_energy_consumption.log"; 
	open ($fh_resultlog,">>", $resultlog) or die $!; 
	open ($fh_logfile,$logfile) or die $!; 
	# 30430435:8: 3848 P 0.18 0 29186 953862 11348 10053 31922172 31172 29186 953862 11348 10053 31922172 31172 (radio 2.17% / 2.17% tx 1.15% / 1.15% listen 1.02% / 1.02%)
	# select the node id and transmit,listen ticks using Perl regex
	foreach $line(<$fh_logfile>){	
		if ($line =~ m/\d+:\d+:\w*\s+\d+\s+P\s+\d+\.\d+\s+(\d+\s+){7}(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) { 
		#if ($line =~ m/\d+:\d+:\w*\s+\d+\s+P\s+\d+\.\d+\s+(\d+\s+){9}(\d+)\s+(\d+)/) { 
			$totalcpu = $totalcpu + $2;
			$totallpm = $totallpm + $3;
			$totalTransmit = $totalTransmit + $4;	
			$totalListen = $totalListen + $5;
		} 
	}
	printf "ENERGY CONSUMPTION\n";
	printf "===================================================================================================\n";
	printf "Nodes" . "\t" . "Total Transmit ticks" . "\t" . "Total Listen ticks" . "\t" . "Total Consumption(ticks)\tTotal cpu\tTotal lpm\tTotal Time\t%Radio ON Time\n";
	$row = sprintf  "%-7s %-23d %-23d %-31d %-15d %-15d %-23d %-23.3f\n" ,$totalnodes, $totalTransmit ,$totalListen, $totalTransmit + $totalListen, $totalcpu, $totallpm, $totalcpu + $totallpm, (($totalTransmit + $totalListen)/($totalcpu + $totallpm)) * 100 ;	
	printf $row; 
	$row = sprintf  "%-d,%-d,%-d\r\n" , $totalTransmit, $totalListen,$totalcpu + $totallpm ;	# comma delimeted list
	print $fh_resultlog  $row;
	printf "\n\n";
	
	close $fh_resultlog; close $fh_logfile;
	system("cp","$resultlog","$resultdir");
}

#---------------------------------------------------------------------------
sub networksetuptime {
	# set the output  (result) file name 
	$resultlog="network_setup_time.log"; 
	open ($fh_resultlog,">>",$resultlog) or die $!; 
	open ($fh_logfile,$logfile) or die $!; 

	$firstDIOsent = 0;
	# DIO sent: first dio sent time from the first line, pattern: 4592116:1:DIO sent
	# DIO joined: last node joined time from the last line, pattern: 4571481:7:DIO joined dag
	foreach $line(<$fh_logfile>){	
		if ($line =~ m/(\d+):\d+:DIO sent/)  { 
			if ($firstDIOsent eq 0 ) { $firstDIOsent = $1;	}
		} else {
						if ($line=~ m/(\d+):\d+:DIO joined dag/) {
							$lastDIOjoinedDAG = $1;		
						}
				}
	}
	printf "NETWORK SETUP TIME\n";
	printf "===================================================================================================\n";
	printf "First DIO" . "\t" . "Last DIO joined DAG\tSetup Time(ms)\n";
	$row = sprintf  "%-15.3f %-23.3f %-15.3f\n" ,$firstDIOsent, $lastDIOjoinedDAG, $lastDIOjoinedDAG-$firstDIOsent ;
	printf $row; 
	$row = sprintf  "%-.3f, %-.3f, %-.3f\r\n" ,$firstDIOsent, $lastDIOjoinedDAG, $lastDIOjoinedDAG-$firstDIOsent; 
	print $fh_resultlog  $row;	
	printf "\n\n";
	
	close $fh_resultlog; close $fh_logfile;
	system("cp","$resultlog","$resultdir");
}

#---------------------------------------------------------------------------
sub networktraffic {
	# set the output  (result) file name 
	$resultlog="network_traffic.log"; 
	open ($fh_resultlog,">>",$resultlog) or die $!; 
	open ($fh_logfile,$logfile) or die $!; 
	# General Idea: Find the corresponding lines and get the value of DIS,DIO,DAO
		# just sum the no of these values in the loop
	$DIOsent = 0;$DISsent = 0;$DAOsent = 0;
	foreach $line(<$fh_logfile>){	
		if ($line =~ m/(\d+):\d+:DIO sent/)  { 
			$DIOsent = $DIOsent + 1;
		} else {
			if ($line=~ m/(\d+):\d+:DIS sent/) {
				$DISsent = $DISsent + 1;	
			} else {
				if ($line=~ m/(\d+):\d+:DAO sent/) {
					$DAOsent = $DAOsent + 1;	
				}
			}
		}
	}
	printf "NETWORK TRAFFIC\n";
	printf "===================================================================================================\n";
	printf "DIO\t\tDIS\t\tDAO\n";
	$row = sprintf  "%-15d %-15d %-15d\n" ,$DIOsent, $DISsent, $DAOsent ;
	printf $row; 
	$row = sprintf  "%-d, %-d, %-d\r\n" ,$DIOsent, $DISsent, $DAOsent ;
	print $fh_resultlog  $row;	
	printf "\n\n";
	
	close $fh_resultlog; close $fh_logfile;
	system("cp","$resultlog","$resultdir");
}

#---------------------------------------------------------------------------
# Network Latency
{  # start of outer block
	# $send{0}={0 => 0}; 
	my $num = 0;
	sub saveSendTime {
		 # save nodenr,packetnr,time
		 $nodenr= $_[0]; $packetnr= $_[1]; $time = $_[2];
		 if (exists  $send{$nodenr}) {
		 	$send{$nodenr}->{$packetnr} = $time; # if the element exists in send hash then add it to the 2nd hash only
		 } else {
		 	$send{$nodenr}= {$packetnr => $time}; # if the element does not exist in send hash, then add to both hashes 
		 }	
	}

	sub printLostPackets {
		# $num = keys %send; printf "num of keys: " . $num . "\n";
		foreach $out (sort keys %send) {
			# printf "node: $out \n";
			foreach $key ( sort keys %{$send{$out}}) {
#				printf "node: $out packet: $key time: $send{$out}{$key}\n";
				$lostpackets = $lostpackets + 1;
			}
		}
		printf 
		return $lostpackets;
	}
	
	sub lookupSendTime {
		$nodenr= $_[0]; $packetnr= $_[1];  $time = $_[2];
		# look
		if (exists $send{$nodenr}{$packetnr}) { 
			$sendTime = $send{$nodenr}{$packetnr}; # for compute latency
			delete($send{$nodenr}{$packetnr}); # if matches then delete, no need to keep it any more
			return($sendTime);
		}
		return(-1);
	}
	

} # end of outer block


sub networklatency {
	# set the output  (result) file name 
	$resultlog="network_latency.log"; 
	open ($fh_resultlog,">>",$resultlog) or die $!; # open log file for the result
	open ($fh_logfile,$logfile) or die $!; # open the log file (from cooja)to be processed for latency

	# General Idea: when we send the DATA we save node, seqno/packetnr, time to a table 'send'
		# when we recv DATA we simply lookup send table and find the sendTime and then computes latency
		# and delete that entry from send table, at the end printing send table gives lost packets
		
	# 534188412:4:DATA send to 1 'Hello 8'            
	# 534706491:1:DATA recv from 4 'Hello 8'
	foreach $line(<$fh_logfile>){	
		if ($line =~ m/(\d+):(\d+):DATA send to 1 'Hello (\d+)'/)  { # line can be either sending or receiving
			$nodenr=$2; $packetnr=$3; $time = $1; # save nodenr,packetnr,time	
			$noSendPackets = $noSendPackets + 1;	
			# printf "DATA send line:$line\n";
			saveSendTime($nodenr, $packetnr, $time ); # save this sending time of each packet to the hash %send
		} else { # line can be either sending or receiving
			if ($line=~ m/(\d+):\d+:DATA recv from (\d+) 'Hello (\d+)'/) {
				$nodenr=$2; $packetnr=$3; $time = $1; # save nodenr,packetnr,time		
				#printf "DATA recv line:$line\n";
				# check if send table has a corresponding sendTime, if yes then calculate latency
				$sendTime = lookupSendTime($nodenr, $packetnr,$time);
				if ( $sendTime > -1) { # we have a match in sendTable
#					# printf "latency for node:$nodenr, packet:$packetnr = %d\n", $time - $sendTime;
					$counter = $counter + 1;
					$totalLatency = $totalLatency + ($time - $sendTime);
				}
			} 
		}
	} # end of foreach
	
	# print loss packets
#	printf "lost packets are:\n";
	$lostpackets = printLostPackets();
	printf "NETWORK LATENCY\n";
	printf "=================\n";
	$row = sprintf  "Average Latency(us)\tno of SendPackets\tLost Packets\n %-22d %-23d %-15d\n" ,$totalLatency / $counter, $noSendPackets, $lostpackets;
	printf $row; 
	$row = sprintf  "%-d,%-d\r\n" ,$totalLatency / $counter, $lostpackets;
	print $fh_resultlog  $row;	
	close $fh_resultlog; close $fh_logfile;
	system("cp","$resultlog","$resultdir");
}

