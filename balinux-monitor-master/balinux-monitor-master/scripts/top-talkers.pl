use strict;
use warnings;
use Time::HiRes;

use Getopt::Long;
use JSON::XS;

my $filename;

GetOptions ("file=s" => \$filename);

STDOUT->autoflush(1);

my $proto;
my $ip_src;
my $port_src;
my $ip_dst;
my $port_dst;
my $length;

my %hash;
my $cnt = 0;

while (<>) {
    if ( m/
	^.* 
	\ proto\ (?<proto>\w+)\ 
	.*
	\ length\ (?<length>\d+)
	.*$
    /x || m/
	^[.\n\s]*
	(?<ip_src>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\.(?<port_src>\d{1,5})
	\ >\ 
        (?<ip_dst>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\.(?<port_dst>\d{1,5})
	.*$
    /x || m/
        ^[.\n\s]*
        (?<ip_src>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
        \ >\ 
        (?<ip_dst>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
        .*
        \ length\ (?<length>\d+)
        .*$
    /x 
    ) {
	if ($+{proto}) {
	    $proto = $+{proto};
	    $length = $+{length};
	}
	elsif ($+{ip_dst} and $+{port_dst}) {
	    $ip_src = $+{ip_src};
	    $ip_dst = $+{ip_dst};
	    $port_src = $+{port_src};
	    $port_dst = $+{port_dst};
	
	    $hash{$cnt} = {
		"proto" => $proto,
		"ip_src" => $ip_src,
		"ip_dst" => $ip_dst,
		"port_src" => $port_src,
		"port_dst" => $port_dst,
		"length" => $length
	    };
	    $cnt++;
	} 
	elsif ($+{ip_dst}) {
            $ip_src = $+{ip_src};
            $ip_dst = $+{ip_dst};
	    
	    $hash{$cnt} = {
                "proto" => $proto,
                "ip_src" => $ip_src,
                "ip_dst" => $ip_dst,
		"length" => $length
            };      
            $cnt++;
	}
    }
}


my $json_text = JSON::XS->new->allow_nonref->encode(\%hash);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$hour = sprintf("%02d", $hour);
$min = sprintf("%02d", $min);
$sec = sprintf("%02d", $sec);

$filename .= "$year-$mon-$mday+$hour:$min:$sec"; 

open(my $fh, '>', $filename);
print $fh $json_text;
close $fh;




