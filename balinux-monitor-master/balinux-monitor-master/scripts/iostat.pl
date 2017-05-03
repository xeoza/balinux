use warnings;
use strict;

use Getopt::Long;
use JSON::XS;

my $filename;

GetOptions ("file=s" => \$filename);

my %hash;

my $line;
for my $i (0..2) { $line = <> };

while (<>) {
    $line = $_;   
    $line =~ s/^\s+|\s+$//g;
    $line =~ s/\s+/ /g;
    my @line_splitted = split / /, $line;

    $hash{$line_splitted[0]} = {
	"tps" => $line_splitted[1],
	"MB/s read" => $line_splitted[2],
	"MB/s write" => $line_splitted[3],
	"MB read" => $line_splitted[4],
	"MB write" => $line_splitted[5]
    } if ($line_splitted[0])
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$hour = sprintf("%02d", $hour);
$min = sprintf("%02d", $min);
$sec = sprintf("%02d", $sec);

$filename .= "$year-$mon-$mday+$hour:$min:$sec";

my $json_text = JSON::XS->new->allow_nonref->encode(\%hash);

open(my $fh, '>', $filename);
print $fh $json_text;
close $fh;

