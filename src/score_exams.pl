#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;

my $master_filename = "resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt";
my %master_questions = get_questions_with_options($master_filename);
my %master_answers = get_answers(%master_questions);


my $student_filename =  "resources/SampleResponses/20170828-092520-FHNW_entrance_exam-ID006431";
my %student_questions = get_questions_with_options($student_filename);
check_missing_content(%student_questions);

my %student_answers = get_answers(%student_questions);
check_answers(%student_answers);


sub check_answers(%current_student_answers){
    #print Dumper(%answers);
    for my $current_question (keys %master_answers){
        if(defined($current_student_answers{$current_question})  &&
            $master_answers{$current_question} eq $current_student_answers{$current_question}){
            say $master_answers{$current_question};
            say $current_student_answers{$current_question};
            say "######################### correct!";
        }
        elsif(defined($current_student_answers{$current_question})){
            say $master_answers{$current_question};
            say $current_student_answers{$current_question};
            say "######################### wrong!";
        } else{
            say $master_answers{$current_question};
            say "######################### missing!";
        }

    }
}

sub check_missing_content(%student){
    for my $current_question (keys %master_questions)
    {
        #missing question
        if(!defined($student{$current_question})){
            say "missing question: " . $current_question;
                next;
        }
        for my $current_option ( keys %{ $master_questions{$current_question} } ) {
            #missing option
            if (!defined($student{$current_question}{$current_option})) {
                say "missing option for question : $current_option";
            }
        }
     }
}

sub get_answers(%questions){
    my %answers;

    for my $current_question (keys %questions) {

        $answers{$current_question} = undef;

        for my $current_option ( keys %{ $questions{$current_question} } ) {
            #new answer
            if( $questions{$current_question}{$current_option}
            && !defined($answers{$current_question})){
                $answers{$current_question} = $current_option;
            }
            #anwer already available
            elsif( $questions{$current_question}{$current_option}
                && defined($answers{$current_question})){
                $answers{$current_question} = undef;
                last;
            }
        }
    }
    return %answers;
}

sub get_questions_with_options($filename) {

    open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

    my %questions;
    my $current_question;
    my %current_options;

    while (my $row = readline($filehandle)) {

        $row = trim($row);

        if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
            $current_question = $row;
        }
        elsif((substr($row,0,1) eq '_' || substr($row,0,1) eq '=')  && defined($current_question)){ # save question with options
            $questions{$current_question} = { %current_options };
            %current_options = ();
            $current_question = undef;
        }
        elsif(substr($row,0,1) eq '[' && defined($current_question)) { #add option
            if ($row =~ m/^(\[\S\])/ ) {
                $row =~ s/^(\[\S\]) //;
                $current_options{$row} = 1;
            }
            else {
                $row =~ s/^(\[[ ]\]) //;
                $current_options{$row} = 0;
            }
        }
        else { #say "__skip line" . $row
        }
    }
    return %questions;
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };