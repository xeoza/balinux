#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use JSON::XS;

my $filename;
my $ss = '';
my $netstat = '';

GetOptions ("file=s" => \$filename,
	    "ss" => \$ss,
	    "netstat" => \$netstat);

my %hash;
my $line;
my $cnt = 0;

if ($netstat) {
    $line = <>;
    $line = <>;
    while (<>) {
        $line = $_; 
	$line =~ s/\s+/ /g;
	my @line_splitted = split / /, $line;
	$line_splitted[3] =~ s/^.*://g;
	$line_splitted[4] =~ s/^.*://g;
	$hash{$cnt++} = {
	    "proto" => $line_splitted[0],
	    "local_port" => $line_splitted[3],
	    "foreign_port" => $line_splitted[4],
	    "state" => $line_splitted[5]
	}
    }        
}
elsif ($ss) {
    $line = <>;
    while (<>) {
	$line = $_;
        $line =~ s/\s+/ /g;
        my @line_splitted = split / /, $line;
	if ($line_splitted[1] eq "LISTEN") {
	    print $line_splitted[4]."\n";
	    $line_splitted[4] =~ s/^.*?:([0-9]+)$/$1/g;
	    $hash{$cnt++} = {
                "proto" => $line_splitted[0],
	        "port" => $line_splitted[4],
		"state" => $line_splitted[1]
	    }
        }
    }
}

my $json_text = JSON::XS->new->allow_nonref->encode(\%hash);

open(my $fh, '>', $filename);
print $fh $json_text;
close $fh;

