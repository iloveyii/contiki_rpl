# This perl script is used to copy the powertrace lines from the plugin Contiki Test Editor to a file pwrline.log

#!/usr/bin/perl
# set the output file name 
$fpwrline="pwrline.log"; 
# assign the array ARGV to string separating each item by space, just for debug 
$mystring=join(" ",@ARGV); print "mystring=" .$mystring ."\n";
# extract logfile name 
if ($mystring=~m/(\w+\.\w+)/) {$logfilepath=$1;} elsif ($mystring=~m/\s(-)($|\s)/){$logfilepath=$1;}
# you can pipe the input file 
if ($logfilepath eq "" || $logfilepath eq "-" ){
	open ($fhpipelog,'>', "pipelog.log") or die $!; 
	foreach $line (<STDIN>) {
		print $fhpipelog $line; 
	}
	close $fhpipelog;
	# update filelog
	$logfilepath="pipelog.log";
	print "Received log from pipe.\n";
}

# call to the required fuction   
powertrace_lines();



#---------------------------------------------------------------------------
sub powertrace_lines{
	open ($fhpwrline,'>', $fpwrline) or die $!; 
	open ($fhlog,$logfilepath) or die $!; 

	# pattern: 38379728:8:str 4868 P
	# copy the lines starting from the pattern above taking care of str variable (both blank and set to some string)

	foreach $line(<$fhlog>){
		if ($line =~ m/\d+:\d+:\w*\s+\d+\s+P/) {
			print $fhpwrline "$line";
			print  "$line\n";
		}
	} 

}
