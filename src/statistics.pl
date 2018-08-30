#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;

#====================================================================
# Statistics
#====================================================================

# Load the values...
# students1 --> First entry: 13 correct answers, sendond entry: 18 answers given of 20.
my %studentScores = (student1 => [13,18], student2 => [19,20], student3 => [8,12], student4 => [8,20]);

# Constants
my $scoreThreshold = 0.5; # Score < 50%
my $totalAmountOfQuestions = 20; # Max amount of questions

# Content lists
my @correctAnswersList;
my @totalAnswersList;
my %belowScoreThreshold;

# Create statistic arrays
for my $key (sort keys %studentScores) {
    my $correctAnswers = $studentScores{$key}[0];
    my $totalAnswers = $studentScores{$key}[1];

    push @correctAnswersList, $correctAnswers; # Collect the amount of correct answers given by the student
    push @totalAnswersList, $totalAnswers; # Collect the total amount of answers given by the student

    if (($studentScores{$key}[0] / $totalAmountOfQuestions) < $scoreThreshold) { # Collect all students below a given threshold
        $belowScoreThreshold{$key}[0] = $correctAnswers;
        $belowScoreThreshold{$key}[1] = $totalAnswers;
        $belowScoreThreshold{$key}[2] = $studentScores{$key}[0];
    }
}

say Dumper %belowScoreThreshold;

# Get amount of students with minimum amount of questions answered
my @minimalQuestionsAnsweredList = grep {$_ eq min(@totalAnswersList)} @totalAnswersList;
my $minimalQuestionsAnsweredCount = @minimalQuestionsAnsweredList;

# Get amount of students with maximum amount of questions answered
my @maximumQuestionsAnsweredList = grep {$_ eq max(@totalAnswersList)} @totalAnswersList;
my $maximumQuestionsAnsweredCount = @maximumQuestionsAnsweredList;

# Get amount of students with minimum of correctly given answers
my @minimumCorrectlyGivenAnswersList = grep {$_ eq min(@correctAnswersList)} @correctAnswersList;
my $minimumCorrectlyGivenAnswersCount = @minimumCorrectlyGivenAnswersList;

# Get amount of students with maximum of correctly given answers
my @maximumCorrectlyGivenAnswersList = grep {$_ eq max(@correctAnswersList)} @correctAnswersList;
my $maximumCorrectlyGivenAnswersCount = @maximumCorrectlyGivenAnswersList;

#====================================================================
# Screen Output
#====================================================================
say "Average number of questions answered:....." . mean(@totalAnswersList);
say "                             Minimum:....." . min(@totalAnswersList) . "   ($minimalQuestionsAnsweredCount Student(s))";
say "                             Maximum:....." . max(@totalAnswersList) . "   ($maximumQuestionsAnsweredCount Student(s))";
print "\n";
say "Average number of correct answers:........" . mean(@correctAnswersList);
say "                             Minimum:....." . min(@correctAnswersList) . "   ($minimumCorrectlyGivenAnswersCount Student(s))";
say "                             Maximum:....." . max(@correctAnswersList) . "   ($maximumCorrectlyGivenAnswersCount Student(s))";
print "\n";
say "Results below expectation:";
for my $key (sort keys %belowScoreThreshold) {
    say "                             $key.....$belowScoreThreshold{$key}[0]/$belowScoreThreshold{$key}[1]  (score < 50%)";
}
