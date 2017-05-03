use strict;
use warnings;

use JSON::XS;
use Getopt::Long;

my $filename;

GetOptions ("file=s" => \$filename);

my %hash;

my $line = <>;
$line = <>;
$line = <>;

while ($line = <>) { 
    $line =~ s/^\s+|\s+$//g;
    $line =~ s/\s+/ /g;
    my @line_splitted = split / /, $line;
    $hash{$line_splitted[1]} = {
	"%usr"	    =>	$line_splitted[2],
	"%nice"	    =>	$line_splitted[3],
	"%sys"	    =>	$line_splitted[4],
	"%iowait"   =>	$line_splitted[5],
	"%irq"	    =>	$line_splitted[6],
	"%soft"	    =>	$line_splitted[7],
	"%steal"    =>  $line_splitted[8],
	"%guest"    =>	$line_splitted[9],
	"%gnice"    =>	$line_splitted[10],
	"%idle"	    =>	$line_splitted[11]
    }
}

my $json_text = JSON::XS->new->allow_nonref->encode(\%hash);

open(my $fh, '>', $filename);
print $fh $json_text;
close $fh;

