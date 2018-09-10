#! /usr/bin/env perl
#====================================================================
# @title  'score_exams'
# @author Dimitri Muralt, Christoph Wenk
# @date   31.08.2018
# @desc   This script reads in a master file and takes a list of response files.
#         It then compares the response files against the master file and reports
#         any missing questions or answers in the response files. The matching allows
#         for slight changes in the questions or answers and is able match them regardless.
#         The response files will be scored and the statistics module will be
#         called in the end.
#
#         Call syntax: bin/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/Responses/[response_file]
#                      bin/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/Responses/*
#
#         The script solves part 1b, 2, 4 of the assignment.
#====================================================================
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';
use Statistics::statistics qw(createStatistics);
use Text::Levenshtein qw(distance);

#====================================================================
# Score Exams
#====================================================================

# check console input
if (@ARGV < 2) {
    say "Missing parameters. Usage:";
    say "$0 <master-file> [response-files]";
    exit (1);
}
# Enable windows * file selection
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
my @student_answers_keys;                   # structure:   [ [question1_option_selected, bool_correctness],
#                                                            [question2_option_selected, bool_correctness]
#                                                          ]
my %students_scores;              #structure: {student1 => [count_answered_correct, count_answered],
#                                              student2 => [count_answered_correct, count_answered] }
my %students_answers_keys;             #structure: {student1 => [ [bool_correctness, question1_option_selected],
#                                                                 [bool_correctness, question2_option_selected] ],
#                                                   student2 => [ [bool_correctness, question1_option_selected],
# #                                                               [bool_correctness, question2_option_selected] ]
#                                                  }
#
#====================================================================
# Main processing
#====================================================================
# get master data
%master_questions = get_data_from_file($master_filename);
%master_answers   = get_answers(%master_questions);

# get data for each student
for my $student_filename (@student_filenames){
    %student_questions        = get_data_from_file($student_filename);
    %student_questions        = sanitize_student_data($student_filename, %student_questions);
    %student_answers          = get_answers(%student_questions);
    @student_answers_keys     = check_answers(%student_answers);

    # collect student score count for statistics
    $students_scores{$student_filename}       = get_count_answered(@student_answers_keys);
    # collect student answers for misconduct check
    $students_answers_keys{$student_filename} = [ @student_answers_keys ];
}

# Call statistics module
 create_statistics(%students_scores);
# Call misconduct subroutine
 detect_misconduct (%students_answers_keys);


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
        $row =~ s/^\s+|\s+$//g;           # trim
        # if row starts with a number > its a question
        if(substr($row,0,1) =~ /^\d/) {
            $row =~ s/^\d+.\s?//g; #remove brackets before option
            $current_question = $row;
        }
        #if row starts with a "_" or "=" try to save a question with all options
        elsif((substr($row,0,1) eq '_' || substr($row,0,1) eq '=')
                &&
                defined($current_question)){
            $questions{$current_question} = { %current_options };
            %current_options = ();
            $current_question = undef;
        }
        #add option to current question
        elsif(substr($row,0,1) eq '[' && defined($current_question)) {
            if ($row =~ m/^(\[\s?\S\s?\])/ ) {
                $row =~ s/^(\[\s?\S\s?\]) //; #remove brackets before option
                $current_options{$row} = 1;
            }
            else {
                $row =~ s/^(\[[\s]\]|\[\]) //;
                $current_options{$row} = 0;
            }
        }
    }
    return %questions;
}

sub sanitize_student_data($current_student_filename, %student_questions){

    say "... checking $current_student_filename";
    # go through all master questions and check if they are present in students file
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

sub get_answers(%questions_with_selected_options){
    my %answers;
    # go through all questions and save the selected option in %answers
    for my $current_question (keys %questions_with_selected_options) {
        $answers{$current_question} = undef;
        # go through all options
        for my $current_option ( keys %{ $questions_with_selected_options{$current_question} } ) {
            #option selected > save as answer
            if( $questions_with_selected_options{$current_question}{$current_option}
                && !defined($answers{$current_question})){
                $answers{$current_question} = $current_option;
            }
            #more than one option selected > answer not valid
            elsif( $questions_with_selected_options{$current_question}{$current_option}
                && defined($answers{$current_question})){
                $answers{$current_question} = undef;
                last; # duplicate selection, other options are ignored
            }
        }
    }
    return %answers;
}

sub check_answers(%current_student_answers){

    my @current_student_answers_keys;

    # go through all master answers alphabetically and compare with current student answers
    for my $current_question (sort keys %master_answers){
        # student answer matches master answer
        if(defined($current_student_answers{$current_question})
                && $master_answers{$current_question} eq $current_student_answers{$current_question})
        {
            push @current_student_answers_keys, [1, $current_student_answers{$current_question}];
        }
        # student answer mismatches master answer
        elsif(defined($current_student_answers{$current_question})){
            push @current_student_answers_keys, [0, $current_student_answers{$current_question}];
        }
        #student answer not filled out correctly
        else{
            push @current_student_answers_keys, [0, ''];
        }
    }
    return @current_student_answers_keys;
}

sub get_count_answered(@current_student_answers_keys){
    my $count_answered = 0;
    my $count_answered_correct = 0;

    for my $i ( 0 .. $#current_student_answers_keys ) {
        #answer filled out correctly
        if($current_student_answers_keys[$i]->[0]){
            $count_answered_correct++;
        }
        #answer filled out
        if($current_student_answers_keys[$i]->[1]){
            $count_answered++;
        }
    }
    return [$count_answered_correct, $count_answered];
}

sub detect_misconduct (%students_answers_keys){
    say "#============================================================#";
    say "# Possible Misconduct                                        #";
    say "#============================================================#";

    my @suspicious_students = get_students_with_errors_more_then(5);
    my $count_questions_in_test = scalar(@{$students_answers_keys{(keys %students_answers_keys)[0]}});

    ####################################################################
    # compare each student with 5 or more errors to all other students
    #      step    1) compare student_1        with (student_2..last)
    #      step    2) compare student_2        with (student_3..last)
    #        ...
    #      step last) compare student_prelast  with student_last
    ####################################################################
    # iterate through all students
    # "@students - 1" because in the last step the student_prelast is compared to the others
    for (my $student_index = 0; $student_index < @suspicious_students - 1; $student_index++){ # "@students - 1" because
        #say "guilty ". @students[$student_index];
        # compare current_student to all subsequent students
        for (my $compare_student_index = $student_index+1; $compare_student_index < @suspicious_students - 1; $compare_student_index++) {
            my $count_same_correct_answers = 0;
            my $count_same_wrong_answers = 0;
            for my $i (0 .. $count_questions_in_test - 1) {
                # both correct answer
                if( $students_answers_keys{$suspicious_students[$student_index]}->        [$i][0] == 1
                 && $students_answers_keys{$suspicious_students[$compare_student_index]}->[$i][0] == 1)
                {
                    $count_same_correct_answers++;
                }
                #both same wrong answer
                elsif(      $students_answers_keys{$suspicious_students[$student_index]}->        [$i][0] == 0  # both wrong
                    &&      $students_answers_keys{$suspicious_students[$compare_student_index]}->[$i][0] == 0
                    &&      $students_answers_keys{$suspicious_students[$student_index]}->        [$i][1]   # both same
                        eq  $students_answers_keys{$suspicious_students[$compare_student_index]}->[$i][1]
                    &&      $students_answers_keys{$suspicious_students[$student_index]}->        [$i][1] ne  '')# both not null
                {
                    $count_same_wrong_answers++;
                }
            }
            ####################################################################
            # print misconduct probability
            #
            # probability is computed as follows:
            #
            # 1)   1 -                                    # 1 is the highest possible probability
            # 2)   0.25 ** $count_same_wrong_answers      # 0.25 is the probability to select a wrong answer.
            #                                             # it's very suspicious when students select the same wrong answer.
            # 3)   * $count_questions_in_test
            #           / $count_same_correct_answers     # ratio of total questions in test and same correct answers
            #                                             # of two students. probability increases when ratio of same
            #                                             # correct answers is higher.
            # 4)   * 100                                  # only for formatting
            ####################################################################
            # compute probability if a student has at least 4 same wrong anwsers ans another
            my $probability = 0;
            if($count_same_wrong_answers >= 4) {
                $probability = 1 -                                              # 1 ist max probability
                    0.25 ** $count_same_wrong_answers                              # wrong answers in power
                        * ($count_questions_in_test / $count_same_correct_answers) # ratio question total and correct answers
                        * 100;                                                     # visual correction
            }
            # print misconduct if probability > 0.3
            if($probability > 0.3){
                say "    " . $suspicious_students[$student_index].        "............. probability:  ". sprintf("%.2f", $probability)
                    ."  (same correct/wrong: ". $count_same_correct_answers."/". $count_same_wrong_answers.")";
                say "and " . $suspicious_students[$compare_student_index];
            }
        };
    };
}

sub get_students_with_errors_more_then($max_errors){

    my @suspicious_students;
    #iterate through all students sorted by name
    for my $current_student (sort keys %students_answers_keys){
        my $error_count = 0;
        # go through answers and count errors
        for my $i (0 .. @{$students_answers_keys{$current_student}} - 1) {
            # if error
            if(!$students_answers_keys{$current_student}->[$i][0]){
                $error_count++;
                if($error_count >= $max_errors) {
                    push @suspicious_students, $current_student;
                    last; # at least 5 errors, save student and continue with next student
                };
            };
        };
    };
    return @suspicious_students;
}
