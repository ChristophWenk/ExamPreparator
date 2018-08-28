use v5.24;
use strict;
use warnings;
use diagnostics;

my $filename = "../resources/MasterFiles/short_exam_master_file.txt";
open(my $inFile, "<", $filename) or die "Could not open file.";
my $text;
{
    local $/ = undef;
    $text = readline($inFile);
}

say $text;