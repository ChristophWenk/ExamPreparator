#! /usr/bin/env perl
#====================================================================
# @title  'createMasterFile'
# @author Christoph Wenk
# @date   29.08.2018
# @desc   This script reads in an input questionnaire file located
#         in the 'resources' folder. The filename must be specified
#         by the user via the command line. The script then removes
#         any answers marked as correct answer (set [X] to [ ]),
#         randomizes the order of the answers and writes the output
#         to an output file located in 'out'.
#
#         Call syntax: createMasterFile [masterFile]
#
#         The script solves part 1a of the assignment.
#====================================================================

use v5.24;
use strict;
use warnings;
use diagnostics;
use POSIX qw(strftime);
use List::Util qw(shuffle);
use File::Path qw( make_path );

#====================================================================
# Preprocessing
#====================================================================
# Get current local timestamp
my $timestamp      = strftime "%Y%m%d-%H%M%S", localtime(time);

#====================================================================
# File definitions
#====================================================================
#my ($inputFileName)  = @ARGV;
# Only for testing purposes
my $inputFileName  = "short_exam_master_file.txt";
my $inputFilePath  = "resources/MasterFiles/".$inputFileName;
my $outputFileName = qq($timestamp-$inputFileName);
my $outputFilePath = "out/".$outputFileName;

# Create output path if it not exists
if ( !-d "out/" ) {
    make_path "out/" or die "Failed to create path: out/";
}

open(my $inputFileHandle,  "<", $inputFilePath)  or die "Could not open input file.";
open(my $outputFileHandle, ">", $outputFilePath) or die "Could not open output file.";

#====================================================================
# Main processing
#====================================================================
while (!eof $inputFileHandle) {
    my $nextline = readline($inputFileHandle);
    chomp($nextline);

            my @questions;

            while ($nextline =~ m/\[[^\]]*\]/) {
                if ($nextline =~ m/[Xx]/) {
                    $nextline =~ s/[Xx]/ /;
                    push @questions, $nextline;
                }
                else {
                    push @questions, $nextline;
                }
                $nextline = readline($inputFileHandle);
                chomp($nextline);
            }
            my @shuffledQuestions = shuffle @questions;
            for my $question (@shuffledQuestions) {
                say {$outputFileHandle} $question;
            }
            @questions = ();
            say {$outputFileHandle} $nextline;
    }

#====================================================================
# Subroutine definitions
#====================================================================


#====================================================================
# Exit program
#====================================================================
close($inputFileHandle) or die "Could not close input file.";
close($outputFileHandle) or die "Could not close output file.";