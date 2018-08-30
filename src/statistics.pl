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
my %studentScores = (student1 => [13,18], student2 => [19,20], student3 => [8,12], student4 => [8,20]);

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