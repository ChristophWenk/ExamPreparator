#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;
use Statistics::Descriptive;

#====================================================================
# Statistics
#====================================================================

# Load the values...
# students1 --> First entry: 13 correct answers, sendond entry: 18 answers given of 20.
my %studentScores = (student1 => [13,18], student2 => [19,20], student3 => [8,12], student4 => [8,20], student5 => [7,16]);

# Constants
my $scoreThreshold = 0.5; # Score < 50%
my $totalAmountOfQuestions = 20; # Max amount of questions
my $bottomCohortThreshold = 25;

# Content lists
my @correctAnswersList;
my @totalAnswersList;
my %studentStatisticsList; # Structure: (StudentFile => [
#                                                           CorrectAnswers,
#                                                           TotalAnswersGiven,
#                                                           ScoreBelowThresholdFlag,
#                                                           BottomCohortFlag
#                                                         ]
#                                         )
my $minimalQuestionsAnsweredCount;
my $maximumQuestionsAnsweredCount;
my $minimumCorrectlyGivenAnswersCount;
my $maximumCorrectlyGivenAnswersCount;

# Variables
my $stat = Statistics::Descriptive::Full->new();
my $lowestPercentile;


#====================================================================
# Main processing
#====================================================================
# Create statistic arrays
for my $key (sort keys %studentScores) {
    my $correctAnswers = $studentScores{$key}[0];
    my $totalAnswers = $studentScores{$key}[1];

    push @correctAnswersList, $correctAnswers; # Collect the amount of correct answers given by the student
    push @totalAnswersList, $totalAnswers; # Collect the total amount of answers given by the student

    $studentStatisticsList{$key}[0] = $correctAnswers;
    $studentStatisticsList{$key}[1] = $totalAnswers;
}

# Calculate Percentile
$stat->add_data(@correctAnswersList);
$lowestPercentile = $stat->percentile($bottomCohortThreshold);

doChecks();

createBasicStatistics();


#====================================================================
# Screen Output
#====================================================================
say "Average number of questions answered:....." . mean(@totalAnswersList);
say "                             Minimum:....." . min(@totalAnswersList) . "   ($minimalQuestionsAnsweredCount Student(s))";
say "                             Maximum:....." . max(@totalAnswersList) . "   ($maximumQuestionsAnsweredCount Student(s))";
say "";
say "Average number of correct answers:........" . mean(@correctAnswersList);
say "                             Minimum:....." . min(@correctAnswersList) . "   ($minimumCorrectlyGivenAnswersCount Student(s))";
say "                             Maximum:....." . max(@correctAnswersList) . "   ($maximumCorrectlyGivenAnswersCount Student(s))";
say "";
say "Results below expectation:";
for my $key (sort keys %studentStatisticsList) {
   if ($studentStatisticsList{$key}[2] == 1) {
       say "    $key.....$studentStatisticsList{$key}[0]/$studentStatisticsList{$key}[1]  (score < 50%)";
   }
   if ($studentStatisticsList{$key}[3] == 1) {
       say "    $key.....$studentStatisticsList{$key}[0]/$studentStatisticsList{$key}[1]  (bottom 25% of cohort)";
   }
}

#====================================================================
# Subroutine Definitions
#====================================================================
sub doChecks {
    for my $key (sort keys %studentScores) {
        # Check if student is under the specified threshold
        if (($studentScores{$key}[0] / $totalAmountOfQuestions) < $scoreThreshold) {
            $studentStatisticsList{$key}[2] = 1;
        }
        else {
            $studentStatisticsList{$key}[2] = 0;
        }

        # Check if student belongs to lowest percentile
        if ($studentScores{$key}[0] < $lowestPercentile) {
            $studentStatisticsList{$key}[3] = 1;
        }
        else {
            $studentStatisticsList{$key}[3] = 0;
        }
    }
}

sub createBasicStatistics {
    # Get amount of students with minimum amount of questions answered
    $minimalQuestionsAnsweredCount = grep {$_ == min(@totalAnswersList)} @totalAnswersList;

    # Get amount of students with maximum amount of questions answered
    $maximumQuestionsAnsweredCount = grep {$_ == max(@totalAnswersList)} @totalAnswersList;

    # Get amount of students with minimum of correctly given answers
    $minimumCorrectlyGivenAnswersCount = grep {$_ == min(@correctAnswersList)} @correctAnswersList;

    # Get amount of students with maximum of correctly given answers
    $maximumCorrectlyGivenAnswersCount = grep {$_ == max(@correctAnswersList)} @correctAnswersList;
}