#! /usr/bin/env perl
#====================================================================
# @title  'statistics'
# @author Christoph Wenk, Dimitri Muralt
# @date   30.08.2018
# @desc   This script get a hash as an input and creates various statistic
#         lists with it. It then puts those messages to STDOUT for the
#         user to read.
#
#         Callable by other scripts. Needs hash as input with the following
#         structure:
#         (StudentFile => [
#                           CorrectAnswers,
#                           TotalAnswersGiven
#                         ]
#         )
#
#         The script solves part 3 of the assignment.
#====================================================================
use v5.28;
use strict;
use warnings;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;
use Statistics::Descriptive;
use Exporter qw(import);
use utf8;
use open ':std', ':encoding(UTF-8)';

our @EXPORT_OK = qw(create_statistics);

#====================================================================
# Definitions
#====================================================================
# Constants
my $score_threshold = 0.5; # Score < 50%
my $total_amount_of_questions = 20; # Max amount of questions
my $bottom_cohort_threshold = 25; # Lowest percentile

# Content lists
my %student_scores;
my @correct_answers_list;
my @total_answers_list;
my %student_statistics_list; # Structure: (StudentFile => [
#                                                           CorrectAnswers,
#                                                           TotalAnswersGiven,
#                                                           ScoreBelowThresholdFlag,
#                                                           BottomCohortFlag,
#                                                           BelowMeanFlag
#                                                       ]
#                                         )

# Variables
my $stat = Statistics::Descriptive::Full->new();
my $lowest_percentile;
my $stdv;
my $minimal_questions_answered_count;
my $maximum_questions_answered_count;
my $minimum_correctly_given_answers_count;
my $maximum_correctly_given_answers_count;
my $student_string;

#====================================================================
# Main Processing
#====================================================================
sub create_statistics {
    %student_scores = @_;
    # Create statistic arrays
    for my $key (sort keys %student_scores) {
        my $correct_answers = $student_scores{$key}[0];
        my $total_answers = $student_scores{$key}[1];

        push @correct_answers_list, $correct_answers; # Collect the amount of correct answers given by the student
        push @total_answers_list, $total_answers; # Collect the total amount of answers given by the student

        $student_statistics_list{$key}[0] = $correct_answers;
        $student_statistics_list{$key}[1] = $total_answers;
    }
    # Calculate percentile and standard deviation
    $stat->add_data(@correct_answers_list);
    if ((my $length = @correct_answers_list /$bottom_cohort_threshold) >= 1) { # Percentile only makes sense when there are enough people to calculate it.
        $lowest_percentile = $stat->percentile($bottom_cohort_threshold);     # E.g.: 25% Percentile of 3 people does not exit. There need to be at least 4 people.
    }
    else {
        $lowest_percentile = -1;
    }
    $stdv = $stat->standard_deviation();

    do_checks();
    do_basic_statistics();
    put_output();
}

#====================================================================
# Subroutine Definitions
#====================================================================
sub do_checks {
    for my $key (sort keys %student_scores) {
        # Check if student is under the specified threshold
        if (($student_scores{$key}[0] / $total_amount_of_questions) < $score_threshold) {
            $student_statistics_list{$key}[2] = 1;
        }
        else {
            $student_statistics_list{$key}[2] = 0;
        }

        # Check if student belongs to lowest percentile
        if ($student_scores{$key}[0] <= $lowest_percentile) {
            $student_statistics_list{$key}[3] = 1;
        }
        else {
            $student_statistics_list{$key}[3] = 0;
        }

        # Check if student's score is > 1 stdv below mean
        if ($student_scores{$key}[0] < mean(@correct_answers_list)) {
            $student_statistics_list{$key}[4] = 1;
        }
        else {
            $student_statistics_list{$key}[4] = 0;
        }
    }
}

sub do_basic_statistics {
    # Get amount of students with minimum amount of questions answered
    $minimal_questions_answered_count = grep {$_ == min(@total_answers_list)} @total_answers_list;

    # Get amount of students with maximum amount of questions answered
    $maximum_questions_answered_count = grep {$_ == max(@total_answers_list)} @total_answers_list;

    # Get amount of students with minimum of correctly given answers
    $minimum_correctly_given_answers_count = grep {$_ == min(@correct_answers_list)} @correct_answers_list;

    # Get amount of students with maximum of correctly given answers
    $maximum_correctly_given_answers_count = grep {$_ == max(@correct_answers_list)} @correct_answers_list;
}

#====================================================================
# Screen Output Subroutines
#====================================================================
sub put_output {
    say "";
    # print individual score of each student
    say "#============================================================#";
    say "# Statistics                                                 #";
    say "#============================================================#";
    say "Individual scores:";
    for my $current_score (sort keys %student_scores){
        say "    $current_score" . format_dots(length($current_score)) . sprintf("%02d",$student_scores{$current_score}[0]) . "/" . sprintf("%02d",$student_scores{$current_score}[1]);
    }

    say "";
    say "Average number of questions answered:..... " . sprintf("%.0f",mean(@total_answers_list));
    $student_string = format_students($minimal_questions_answered_count);
    say "                             Minimum:..... " . sprintf("%2s",min(@total_answers_list)) . "   ($minimal_questions_answered_count $student_string)";
    $student_string = format_students($maximum_questions_answered_count);
    say "                             Maximum:..... " . sprintf("%2s",max(@total_answers_list)) . "   ($maximum_questions_answered_count $student_string)";
    say "";

    say "Average number of correct answers:........ " . sprintf("%.0f",mean(@correct_answers_list));
    $student_string = format_students($minimum_correctly_given_answers_count);
    say "                          Minimum:........ " . sprintf("%2s",min(@correct_answers_list)) . "   ($minimum_correctly_given_answers_count $student_string)";
    $student_string = format_students($maximum_correctly_given_answers_count);
    say "                          Maximum:........ " . sprintf("%2s",max(@correct_answers_list)) . "   ($maximum_correctly_given_answers_count $student_string)";
    say "";

    say "Results below expectation:";
    for my $key (sort keys %student_statistics_list) {
        if ($student_statistics_list{$key}[2] == 1) {
            say "    $key" . format_dots(length($key)) . sprintf("%02d",$student_statistics_list{$key}[0]) . "/" . sprintf("%02d",$student_statistics_list{$key}[1]) . "  (score < 50%)";
        }
        elsif ($student_statistics_list{$key}[3] == 1) {
            say "    $key" . format_dots(length($key)) . sprintf("%02d",$student_statistics_list{$key}[0]) . "/" . sprintf("%02d",$student_statistics_list{$key}[1]) . "  (bottom 25% of cohort)";
        }
        elsif ($student_statistics_list{$key}[4] == 1) {
            say "    $key" . format_dots(length($key)) . sprintf("%02d",$student_statistics_list{$key}[0]) . "/" . sprintf("%02d",$student_statistics_list{$key}[1]) . "  (score > 1σ below mean)";
        }
    }
}

sub format_students($count) {
    if ($count == 1) {return "student";} else {return "students";}
}

sub format_dots($string_length) {
    my $dots = "      ";
    my $i=0;
    while ($i < 90-$string_length) {
        substr($dots,$i,$i) = ".";
        $i++;
    }
    return $dots;
}

# True statement needed for use-statement (module import/export)
42;