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

my @correctAnswersList;
my @totalAnswersList;

# Create statistic arrays
for my $key (sort keys %studentScores) {
    my $correctAnswers = $studentScores{$key}[0];
    my $totalAnswers = $studentScores{$key}[1];
    push @correctAnswersList, $correctAnswers; # Collect the amount of correct answers given by the student
    push @totalAnswersList, $totalAnswers; # Collect the total amount of answers given by the student
}


say Dumper @correctAnswersList;


my @studentScoresArray = values %studentScores;

# Get amount of students with minimum grade
#my @minimalGradeStudents = grep {$_ eq min(@studentScoresArray)} %studentScores;
my @minimalGradeStudents = grep {$_ eq min(@studentScoresArray)} %studentScores;
my $minimalGradeStudentsCount = @minimalGradeStudents;

say Dumper @minimalGradeStudents;


# Get amount of students with maximum grade
my @maximumGradeStudents = grep {$_ eq max(@studentScoresArray)} %studentScores;
my $maximumGradeStudentsCount = @maximumGradeStudents;

say "Average number of questions answered:....." . mean(@totalAnswersList);
say "                             Minimum:....." . min(@totalAnswersList);
say "                             Maximum:....." . max(@totalAnswersList);
print "\n";
say "Average number of correct answers:........" . mean(@correctAnswersList);
say "                             Minimum:....." . min(@correctAnswersList) . "   ( Student(s))";
say "                             Maximum:....." . max(@correctAnswersList) . "   ( Student(s))";