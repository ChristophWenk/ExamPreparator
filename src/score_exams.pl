#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;

#error handling filenames

#perl score_exams.pl FHNW_entrance_exam_master_file_2017.txt *

my ($master_filename, @student_filenames) = @ARGV;

my $master_file_path = "../resources/MasterFiles/";
$master_filename  = $master_file_path . $master_filename;

my %master_questions = get_questions_with_options($master_filename);
my %master_answers = get_answers(%master_questions);

my %students_scores;

for my $student_filename (@student_filenames){
    my $student_file_path = "../resources/SampleResponses/".$student_filename;

    my %student_questions = get_questions_with_options($student_file_path);
    check_missing_content(%student_questions);

    my %student_answers = get_answers(%student_questions);

    #collect student score
    $students_scores{$student_filename} = [ check_answers(%student_answers) ];
}

for my $current_score(sort keys %students_scores){
    say "$current_score..................$students_scores{$current_score}[0]/$students_scores{$current_score}[1]";
}

sub check_answers(%current_student_answers){

    my $answered = 0;
    my $answered_correct = 0;

    for my $current_question (keys %master_answers){
        # correct answer
        if(defined($current_student_answers{$current_question})  &&
                $master_answers{$current_question} eq $current_student_answers{$current_question}){
            $answered++;
            $answered_correct++;
        }
        #wrong answer
        elsif(defined($current_student_answers{$current_question})){
            $answered++;
        }
        # missing answer
        else {
        }
    }
    return ($answered_correct,$answered);

}

sub check_missing_content(%student){
    for my $current_question (keys %master_questions)
    {
        #missing question
        if(!defined($student{$current_question})){
            say "missing question : " . $current_question;
            next;
        }
        for my $current_option ( keys %{ $master_questions{$current_question} } ) {
            #missing option
            if (!defined($student{$current_question}{$current_option})) {
                say "missing answer : $current_option";
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