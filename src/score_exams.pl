#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';

my $master_filename = "resources/MasterFiles/short_exam_master_file.txt";
my %master_questions = get_master_questions($master_filename);

sub get_master_questions($filename) {

    open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

    my %questions;
    my $question;

    while (my $row = readline($filehandle)) {

        $row = trim($row);

        if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
            #say "question: " . $row;
            $question = $row;
        }
        elsif(substr($row,0,1) eq '[' && defined($question)) {
            #say "option:   " . $row;
            push @{ $questions{$question} }, $row; # append option to anonymous array
        }
        else {
            #say "__skip line" . $row
        }
    }
    return %questions;
}

for my $current_question ( keys %master_questions ) {
    say "$current_question";
    for my $i ( 0 .. $#{ $master_questions{$current_question} } ) {
        say "$master_questions{$current_question}[$i]";
    }
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
