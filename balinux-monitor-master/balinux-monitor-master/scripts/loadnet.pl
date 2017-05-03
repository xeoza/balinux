#!/bin/perl

use strict;
use warnings;

use Getopt::Long;
use JSON::XS;

my @input;
my $header = 0;
my %hash;

my $filename;

GetOptions ("file=s" => \$filename);

while (<>) {
    if ($header < 2) {
	$header++;
	next
    }
    push @input, $_
}

for my $line (@input) {
    $line =~ s/^\s+|\s+$//g;
    $line =~ s/\s+/ /g;
    my @line_splitted = split / /, $line;
    $hash{$line_splitted[0]} = {
	"Recieve" => {
	    "bytes" => $line_splitted[1],
	    "packets" => $line_splitted[2],
	    "errs" => $line_splitted[3],
	    "drop" => $line_splitted[4],
	    "fifo" => $line_splitted[5],
	    "frame" => $line_splitted[6],
	    "compressed" => $line_splitted[7],
	    "multicast" => $line_splitted[8]
	},
	"Transmit" => {	    
            "bytes" => $line_splitted[9],
            "packets" => $line_splitted[10],
            "errs" => $line_splitted[11],
            "drop" => $line_splitted[12],
            "fifo" => $line_splitted[13],
            "colls" => $line_splitted[14],
            "carrier" => $line_splitted[15],
            "compressed" => $line_splitted[16]
	}
    };
}

my $json_text = JSON::XS->new->allow_nonref->encode(\%hash);

open(my $fh, '>', $filename);
print $fh $json_text;
close $fh;
