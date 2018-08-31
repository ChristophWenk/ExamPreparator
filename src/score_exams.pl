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




#error handling filenames

#usage
#perl src/score_exams.pl FHNW_entrance_exam_master_file_2017.txt resources/SampleResponses/*
#perl src/score_exams.pl FHNW_entrance_exam_master_file_2017.txt resources/SampleResponses/20170828-092520-FHNW_entrance_exam-ID006431

#enable windows * file selection
my @args = ($^O eq 'MSWin32') ? map { glob } @ARGV : @ARGV;
my ($master_filename, @student_filenames) = @args;

my $master_file_path = "resources/MasterFiles/";
$master_filename  = $master_file_path . $master_filename;

my %master_questions = get_questions_with_options($master_filename);
my %master_answers = get_answers(%master_questions);

my %students_scores;
my %students_answers;

for my $student_filename (@student_filenames){
    my %student_questions = get_questions_with_options($student_filename);
    %student_questions = check_missing_content(%student_questions);


    my %student_answers = get_answers(%student_questions);

    #############################
    # miscounduct
    # Collect student answers
    #############################
    $students_answers{$student_filename} = {%student_answers};
    ##############################
    #Statistics
    #collect student score
    ##############################
    $students_scores{$student_filename} = [ check_answers(%student_answers) ];
}



#print student score
for my $current_score(sort keys %students_scores){
    say "$current_score..................$students_scores{$current_score}[0]/$students_scores{$current_score}[1]";
}

# Call statistics module
#createStatistics(%students_scores);

####################################################################
# Subroutines
####################################################################

sub check_answers(%current_student_answers){
    my $answered = 0;
    my $answered_correct = 0;

    for my $current_question (keys %master_answers){

        if(defined($current_student_answers{$current_question})
           &&
           $master_answers{$current_question}  eq $current_student_answers{$current_question})
        {
            # correct answer
            $answered++;
            $answered_correct++;
        }
        elsif(defined($current_student_answers{$current_question}))
        {
            #wrong answer
            $answered++;
        }
    }
    return ($answered_correct,$answered);
}

sub check_missing_content(%student){
    for my $current_master_question (keys %master_questions)
    {
        #missing question
        if(!defined($student{$current_master_question})){
            say "missing question : " . $current_master_question;

            #try to match and replace with another question
            for my $current_student_question(keys %student){
                print check_string_similarity($current_master_question, $student{$current_student_question});
                if(check_string_similarity($current_master_question, $student{$current_student_question})){
                    say "used this instead : $current_student_question";
                    last;
                }
                else{ # no

                }
            }
            next;

            #my %hash = (tom => ['sally', 'dave', 'jennie'],
            #    bertie => ['jean']);
            #print Dumper(%hash);
            #$hash{paul} = delete $hash{tom};
            #print Dumper(%hash);


        }
        for my $current_option ( keys %{ $master_questions{$current_master_question} } ) {
            #missing option
            if (!defined($student{$current_master_question}{$current_option})) {
                say "missing answer : $current_option";
            }
        }
     }
    return %student;
}

sub check_string_similarity ($string1, $string2){
    $string1 = normalize_string($string1);
    $string2 = normalize_string($string2);

    if($string1 eq $string2){
        return 1;
    }
    else {
        return 0;
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

sub normalize_string($string){

    my $stopwords = 'the|a|an|of|on|in|by|at|is|are|that|they|for|to|it';

    $string =~ s/\b(?:$stopwords)\b//g;  # remove stop words;
    $string =~ s/^\s+|\s+$//g;           # trim
    $string =~ s/\s{2,}/ /g;             # replace multiple spaces with one space;
    $string = lc($string);               # to lower case

    return $string;
}

sub get_questions_with_options($filename) {

    open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

    my %questions;
    my $current_question;
    my %current_options;

    while (my $row = readline($filehandle)) {



        #####################################
        #todo: remove trim and adjust if regex
        #####################################
        $row =~ s/^\s+|\s+$//g;           # trim

        if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
            $current_question = $row;
        }
        elsif((substr($row,0,1) eq '_' || substr($row,0,1) eq '=')
                &&
                defined($current_question)){ # save question with options
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
    }
    return %questions;
}