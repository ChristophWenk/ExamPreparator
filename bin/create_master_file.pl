#! /usr/bin/env perl
#====================================================================
# @title  'createMasterFile'
# @author Christoph Wenk, Dimitri Muralt
# @date   29.08.2018
# @desc   This script reads in an input questionnaire file located
#         in the 'resources' folder. The filename must be specified
#         by the user via the command line. The script then removes
#         any answers marked as correct answer (set [X] to [ ]),
#         randomizes the order of the answers and writes the output
#         to an output file located in 'out'.
#
#         Call syntax: createMasterFile <masterFile>
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
if (@ARGV < 1) {
    say "Missing parameters. Usage:";
    say "$0 <master-file> ";
    exit (1);
}

# Get current local timestamp
my $timestamp      = strftime "%Y%m%d-%H%M%S", localtime(time);


#====================================================================
# File definitions
#====================================================================

my ($input_file_name)  = @ARGV;
# Only for testing purposes
#my $inputFileName  = "short_exam_master_file.txt";

my $input_file_path  = "resources/MasterFiles/".$input_file_name;
my $output_file_name = qq($timestamp-$input_file_name);
my $output_file_path = "out/".$output_file_name;

# Create output path if it not exists
if ( !-d "../out/" ) {
    make_path "../out/" or die "Failed to create path: out/";
}

open(my $input_file_handle,  "<", $input_file_path)  or die "Could not open input file.";
open(my $output_file_handle, ">", $output_file_path) or die "Could not open output file.";


#====================================================================
# Main processing
#====================================================================
while (!eof $input_file_handle) {
    my $nextline = readline($input_file_handle);
    chomp($nextline);

    my @questions;

    while ($nextline =~ m/\[[^\]]*\]/) {
        if ($nextline =~ m/\[[Xx]\]/) {
            $nextline =~ s/\[[Xx]\]/\[ \] /;
            push @questions, $nextline;
        }
        else {
            push @questions, $nextline;
        }
        $nextline = readline($input_file_handle);
        chomp($nextline);
    }

    if ((my $nrOfQuestions = @questions) > 0) {
        my @shuffled_questions = shuffle @questions;

        for my $question (@shuffled_questions) {
            say {$output_file_handle} $question;
        }
    }
    say {$output_file_handle} $nextline;
}

#====================================================================
# Exit program
#====================================================================
close($input_file_handle) or die "Could not close input file.";
close($output_file_handle) or die "Could not close output file.";
exit(0);