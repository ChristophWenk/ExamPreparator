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
my %student_answers = get_answers(%student_questions);

check_missing_content(%student_answers);

sub check_missing_content(%student){
    for my $current_question (keys %master_questions) {
        if(!defined($student{$current_question})){
            say "missing question: " . $current_question;
                last;
        }
        for my $current_option ( 0 .. $#{ $master_questions{$current_question} } ) {
            #if (!defined($student{$current_question}[$current_option]) ) {
                say "missing option: " . $master_questions{$current_question}[$current_option];
            #}

        }
    }
}

sub get_answers(%questions){
    my %answers;

    for my $current_question (keys %questions) {

        $answers{$current_question} = undef;

        for my $current_option ( 0 .. $#{ $questions{$current_question} } ) {
            #if option selected
            if (substr($questions{$current_question}[$current_option], 0, 3) eq '[X]'
              && !defined($answers{$current_question}) ) {
                $answers{$current_question} = $questions{$current_question}[$current_option];
            }
            # more than one option selected, answer no valid
            elsif(substr($questions{$current_question}[$current_option], 0, 3) eq '[X]'
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

    while (my $row = readline($filehandle)) {

        $row = trim($row);

        if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
            $current_question = $row;
        }
        elsif(substr($row,0,1) eq '[' && defined($current_question)) {
            push @{ $questions{$current_question} }, $row; # append option to anonymous array
        }
        else { #say "__skip line" . $row
        }
    }
    return %questions;
}

#print Dumper(%master_questions);
#print Dumper(%student_questions);
#say "\n###########\n#########\n###########\n############\n";
#print Dumper(%master_answers);
#print Dumper(%student_answers);

#for my $current_question ( keys %master_questions ) {
#    say "$current_question";
#    for my $i ( 0 .. $#{ $master_questions{$current_question} } ) {
#        say "$master_questions{$current_question}[$i]";
#    }
#}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };


#====================================================================
# Statistics
#====================================================================

# Load the values...
my %studentScores = (student1 => 13, student2 => 19, student3 => 8, student4 => 8);

my @studentScoresArray = values %studentScores;

# Get amount of students with minimum grade
my @minimalGradeStudents = grep {$_ eq min(@studentScoresArray)} %studentScores;
my $minimalGradeStudentsCount = @minimalGradeStudents;

# Get amount of students with maximum grade
my @maximumGradeStudents = grep {$_ eq max(@studentScoresArray)} %studentScores;
my $maximumGradeStudentsCount = @maximumGradeStudents;

say "Average number of questions answered:....." . mean(@studentScoresArray);
say "                             Minimum:....." . min(@studentScoresArray);
say "                             Maximum:....." . max(@studentScoresArray);

say "Average number of correct answers:........" . mean(@studentScoresArray);
say "                             Minimum:....." . min(@studentScoresArray) . "   ($minimalGradeStudentsCount Student(s))";
say "                             Maximum:....." . max(@studentScoresArray) . "   ($maximumGradeStudentsCount Student(s))";