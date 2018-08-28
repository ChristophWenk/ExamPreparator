use v5.24;
use strict;
use warnings;
use diagnostics;
use POSIX qw(strftime);
use List::Util qw(shuffle);

#==============================
# Preprocessing
#==============================
# Get current local timestamp
my $timestamp = strftime "%Y%m%d-%H%M%S", localtime(time);

#==============================
# File definitions
#==============================
# Only for testing purposes
my $inputFileName = "short_exam_master_file.txt";
#my $inputFileName = readline();
#chomp($inputFileName);
my $inputFilePath  = "resources/MasterFiles/".$inputFileName;
my $outputFileName = qq($timestamp-$inputFileName);
my $outputFilePath = "out/".$outputFileName;

open(my $inputFileHandle,  "<", $inputFilePath)  or die "Could not open input file.";
open(my $outputFileHandle, ">", $outputFilePath) or die "Could not open output file.";

#==============================
# Main processing
#==============================
while (!eof $inputFileHandle) {
    my $nextline = readline($inputFileHandle);
    chomp($nextline);
    my $sanitizedRow = trim($nextline);

    if (substr($sanitizedRow,0,1) eq '[') {
        my @questions;
        while (substr($sanitizedRow,0,1) eq '[') {
            if (substr($sanitizedRow,0,3) eq '[x]' or substr($sanitizedRow,0,3) eq '[X]') {
                push @questions, $nextline;
            }
            else {
                push @questions, $nextline;
            }
            $nextline = readline($inputFileHandle);
            chomp($nextline);
            $sanitizedRow = trim($nextline);
        }
        my @shuffledQuestions = shuffle @questions;
        for my $question (@shuffledQuestions) {
            say {$outputFileHandle} $question;
        }
    }
    else {
        say {$outputFileHandle} $sanitizedRow;
    }
}

#==============================
# Subroutine definitions
#==============================
sub trim {
    my $s = shift; $s =~ s/^\s+|\s+$//g;
    return $s;
}

#==============================
# Exit program
#==============================
close($inputFileHandle) or die "Could not close input file.";
close($outputFileHandle) or die "Could not close output file.";