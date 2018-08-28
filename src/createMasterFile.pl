use v5.24;
use strict;
use warnings;
use diagnostics;
use POSIX qw(strftime);

# Get current local timestamp
my $timestamp = strftime "%Y%m%d-%H%M%S", localtime(time);

#=====================
# File definitions
#=====================
# Only for testing purposes
my $inputFileName = "short_exam_master_file.txt";
#my $inputFileName = readline();
#chomp($inputFileName);

my $inputFilePath  = "resources/MasterFiles/".$inputFileName;
my $outputFileName = qq($timestamp-$inputFileName);
my $outputFilePath = "out/".$outputFileName;

open(my $inputFileHandler,  "<", $inputFilePath)  or die "Could not open input file.";
open(my $outputFileHandler, ">", $outputFilePath) or die "Could not open output file.";

#=====================
# Main processing
#=====================

say $outputFileName;








#=====================
# Exit program
#=====================
close($inputFileHandler) or die "Could not close input file.";
close($outputFileHandler) or die "Could not close output file.";
