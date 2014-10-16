# Network Power Consumption: This perl script is used to sum all listen and transmit ticks for all nodes from the output of powertrace lines in the plugin 'Contiki Test Editor' 
# Parameters: change the no of nodes below: $totalnodes and $resultdir
# Usage: perl network_power_consumption.pl logfile: where logfile is the log of all printfs from Cooja, plugin 'Contiki Test Editor'

#!/usr/bin/perl

$totalnodes = 20; $resultdir="/home/user/ftp/log/"; 
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


# call to the required fuction   
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
		if ($line =~ m/\d+:(\d+):\w*\s+\d+\s+P\s+\d+\.\d+\s+(\d+\s+){9}(\d+)\s+(\d+)/) { 
			$totalTransmit = $totalTransmit + $3;	
			$totalListen = $totalListen + $4;
		} 
	}
	printf "ENERGY CONSUMPTION\n";
	printf "===================================================================================================\n";
	printf "Nodes" . "\t" . "Total Transmit ticks" . "\t" . "Total Listen ticks" . "\t" . "Total Consumption(ticks)\n";
	$row = sprintf  "%-7s %-23.3f %-23.3f %-12.3f\n" ,$totalnodes, $totalTransmit ,$totalListen, $totalTransmit + $totalListen;	
	printf $row; 
	$row = sprintf  "%-.3f, %-.3f, %-.3f\r\n" ,$totalTransmit ,$totalListen, $totalTransmit + $totalListen;	# comma delimeted list
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
		} 
		if ($line=~ m/(\d+):\d+:DIO joined dag/) {
			$lastDIOjoinedDAG = $1;		
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

	$DIOsent = 0;$DISsent = 0;$DAOsent = 0;
	# DIO sent: first dio sent time from the first line, pattern: 4592116:1:DIO sent
	# DIO joined: last node joined time from the last line, pattern: 4571481:7:DIO joined dag
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
@send =(); $num = 0;
sub savelatency {
# save nodenr,packetnr,time
printf "inside save \n";
	 $nodenr= $_[0]; $packetnr= $_[1]; $time = $_[2];
	$send{$nodenr}=({$packetnr => $time});
	
#	printf $send[$nodenr]{$packetnr} . "\n";
$num = keys %send;
	printf "num: " . $num . "\n";
	for (my $i=2; $i <= $num; $i++) {
		foreach $key ( keys %{$send{$i}}) {
			#printf $send{$i}{$key} . "\n";
		}
	}
}

sub printlatency {
printf "inside latency \n";
	for (my $i=0; $i < scalar (@send); $i++) {
		foreach $key ( keys %{$send[$i]}) {
			printf $send[$i]{$key} . "\n";
		}
	}

}
savelatency(2,1,111);
printf $send{2}{1} . "\n";
savelatency(2,2,222);
printf $send{2}{1} . "\n";
printf $send{2}{2} . "\n";
savelatency(3,2,333);
printf $send{2}{1} . "\n";
printf $send{2}{2} . "\n";
printf $send{3}{2} . "\n";
savelatency(3,1,444);
printf $send{2}{1} . "\n";
printf $send{2}{2} . "\n";
printf $send{3}{2} . "\n";
printf $send{3}{1} . "\n";

printlatency();
#print @send;

#---------------------------------------------------------------------------
sub networklatency {
	# set the output  (result) file name 
	$resultlog="network_latency.log"; 
	open ($fh_resultlog,">>",$resultlog) or die $!; 
	open ($fh_logfile,$logfile) or die $!; 

	$sCounter = 0; $rCounter = 0;
	# 534188412:4:DATA send to 1 'Hello 8'            nodeid, seqno  
	# 534706491:1:DATA recv from 4 'Hello 8'
	foreach $line(<$fh_logfile>){	
		if ($line =~ m/(\d+):(\d+):DATA send to 1 'Hello (\d+)'/)  { 
			$time = $1; $nodenr=$2; $packetnr=$3;
			# save packet, time in array of hash send
			$send[$nodenr]= ($sendhash{$packetnr=>$time});
			# $send[$nodenr][$packetnr] =  $time;
			# $sumTransmit{$1}=$sumTransmit{$1} + $3;
			$sCounter++;
		} else {
			if ($line=~ m/(\d+):\d+:DATA recv from (\d+) 'Hello (\d+)'/) {
				$time = $1; $nodenr=$2; $packetnr=$3; 
				# save packet,time in array of hash receive
				$receive[$nodenr] = ({packet => $packetnr,  time  => $time});
				$rCounter++;	
			} 
		}
	}
	printf "NETWORK LATENCY\n";
	printf "===================================================================================================\n";
	
	# foreach $key (keys $send[0]sendhash{}) {
		# printf "%-15s %-15s \n",$key,$sendhash{$key};
	# }
	#foreach $key (keys $send[2]=>%sendhash{}) {
		#printf "yup : %-15s\n", $send[2]=>$sendhash{2};
		#printf "yup : %-15s\n", $send[3]=>$sendhash{3};
		#printf "yup : %-15s\n", $send[2]=>$sendhash{14};
#	}
	

	
	
	
	
	#my $array_elements = scalar (@send);

	#for (my $i=0; $i < $array_elements; $i++)	{
	#	print $send[$i]{'time'}."\t" . $send[$i]{'packet'} . "\n";
	#}
	
	close $fh_resultlog; close $fh_logfile;
	system("cp","$resultlog","$resultdir");
}

















