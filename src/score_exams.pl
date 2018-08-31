#!/usr/bin/perl perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '';
use src::statistics qw(createStatistics);
use Text::Levenshtein qw(distance);

#====================================================================
# Score Exams
#====================================================================

#usage
#perl src/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/SampleResponses/*
#perl src/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/SampleResponses/20170828-092520-FHNW_entrance_exam-ID006431

# check console input
if (@ARGV < 2) {
    say "Missing parameters. Usage:";
    say "$0 <master-file> [response-files]";
    exit (1);
}
# enable windows * file selection
my @args = ($^O eq 'MSWin32') ? map { glob } @ARGV : @ARGV;
my ($master_filename, @student_filenames) = @args;

my (%master_questions, %student_questions);  # structure:
#                                               { question1 => {
#                                                      option1 => selected,
#                                                      option2 => selected,
#                                                      option3 => selected,
#                                                      option4 => selected,
#                                                      option5 => selected },
#                                                 question2 => {
#                                                      option1 => selected,
#                                                      option2 => selected,
#                                                      option3 => selected,
#                                                      option4 => selected,
#                                                      option5 => selected }
#
#                                                 }
my (%master_answers, %student_answers);     # structure:   { question1 => answer1, question2 => answer2 }
my @student_score;                #structure: [count_correct, count_answered]
my %students_scores;              #structure: {student1 => [count_correct, count_answered],
#                                              student2 => [count_correct, count_answered] }
my %students_answers;             #structure: {student1 => { question1 => answer1, question2 => answer2, .. },
#                                              student2 => { question1 => answer1, question2 => answer2, .. }
#                                             }
#====================================================================
# Main processing
#====================================================================
# get master data
%master_questions = get_data_from_file($master_filename);
%master_answers   = get_answers(%master_questions);

# get data for each student
for my $student_filename (@student_filenames){
    %student_questions = get_data_from_file($student_filename);
    %student_questions = sanitize_student_data($student_filename, %student_questions);
    %student_answers   = get_answers(%student_questions);
    @student_score     = check_answers(%student_answers);

    # collect student score for statistics
    $students_scores{$student_filename} = [ @student_score ];
    # collect student answers for misconduct check
    $students_answers{$student_filename} = {%student_answers};
}

# Call statistics module
createStatistics(%students_scores);

#====================================================================
# Subroutine Definitions
#====================================================================

sub get_data_from_file($filename) {

    open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

    my %questions;
    my $current_question;
    my %current_options;
    #process file row by row
    while (my $row = readline($filehandle)) {
        #####################################
        #todo: remove trim and adjust if regex
        #####################################
        $row =~ s/^\s+|\s+$//g;           # trim
        # if row starts with a number > its a question
        if(substr($row,0,1) =~ /^\d/) {
            $current_question = $row;
        }
        #if row starts with a "_" try to save a question with all options
        elsif((substr($row,0,1) eq '_' || substr($row,0,1) eq '=')
                &&
                defined($current_question)){
            $questions{$current_question} = { %current_options };
            %current_options = ();
            $current_question = undef;
        }
        #add option to current question
        elsif(substr($row,0,1) eq '[' && defined($current_question)) {
            if ($row =~ m/^(\[\S\])/ ) {
                $row =~ s/^(\[\S\]) //; #remove brackets before option
                $current_options{$row} = 1;
            }
            else {
                $row =~ s/^(\[[ ]\]) //;
                $current_options{$row} = 0;
            }
        }
    }
    return %questions;
}

sub sanitize_student_data($current_student_filename, %student_questions){

    say "... checking $current_student_filename";
    # go through all master question and check if they are present in students file
    for my $current_master_question (keys %master_questions)
    {
        # missing question
        if(!defined($student_questions{$current_master_question})){
            say "missing question : " . $current_master_question;
            #try to match question and replace with another question
            my @student_questions = ( keys %student_questions );
            my $matching_question = lookup_similar_string($current_master_question,@student_questions);

            if($matching_question){ # question matched
                say "used this instead: $matching_question";
                #replace matching question with master question
                $student_questions{$current_master_question} = delete $student_questions{$matching_question};
            }
            else {
                next; # no matching question, skip all following options
            }
        }
        # check missing option
        for my $current_master_option ( keys %{ $master_questions{$current_master_question} } ) {

            if (!defined($student_questions{$current_master_question}{$current_master_option})) {
                say "missing answer   : $current_master_option";
                #try to match option and replace with another option
                my @student_options = ( keys %{$student_questions{$current_master_question} });
                my $matching_option = lookup_similar_string($current_master_option,@student_options);

                if($matching_option){ # option matched
                    say "used this instead: $matching_option";
                    #replace matching option with master option
                    $student_questions{$current_master_question}{$current_master_option}
                        = delete $student_questions{$current_master_question}{$matching_option};
                }
            }
        }
    }
    return %student_questions;
}

sub get_answers(%questions){
    my %answers;
    # go through all questions and save the selected option in %answers
    for my $current_question (keys %questions) {
        $answers{$current_question} = undef;
        # go through all options
        for my $current_option ( keys %{ $questions{$current_question} } ) {
            #option selected > save as answer
            if( $questions{$current_question}{$current_option}
                && !defined($answers{$current_question})){
                $answers{$current_question} = $current_option;
            }
            #more than one option selected > answer not valid
            elsif( $questions{$current_question}{$current_option}
                && defined($answers{$current_question})){
                $answers{$current_question} = undef;
                last; # duplicate selection, other options are ignored
            }
        }
    }
    return %answers;
}

sub check_answers(%current_student_answers){
    my $answered = 0;
    my $answered_correct = 0;

    # go through all master answers and compare with current student answers
    for my $current_question (keys %master_answers){
        # student answer matches master answer
        if(defined($current_student_answers{$current_question})
                &&     $master_answers{$current_question}
                    eq $current_student_answers{$current_question}) {
            $answered++;
            $answered_correct++;
        }
        # student answer mismatches master answer
        elsif(defined($current_student_answers{$current_question})){
            $answered++;
        }
    }
    return ($answered_correct,$answered);
}

sub lookup_similar_string($string_to_find, @library) {

    my $normalized_string_to_find = normalize_string($string_to_find);

    # go through all string in array and find first similar
    for my $current_string (@library) {
        my $normalized_current_string = normalize_string($current_string);

        #calculate Levenshtein distance
        my $distance = distance($normalized_current_string, $normalized_string_to_find);

        #if distance is less then 10% of string length > string similar
        if ($distance*10 < (length($normalized_string_to_find))) {
            return $current_string;
        }
    }
    return '';
}

sub normalize_string($string){

    # stopwords to be removed from string
    my $stopwords = 'the|a|an|of|on|in|by|at|is|\'s|are|that|they|for|to|it';

    $string =~ s/\b(?:$stopwords)\b//g;  # remove stop words;
    $string =~ s/^\s+|\s+$//g;           # trim
    $string =~ s/\s{2,}/ /g;             # replace multiple spaces with one space;
    $string = lc($string);               # to lower case

    return $string;
}