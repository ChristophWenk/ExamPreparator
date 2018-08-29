#!/usr/bin/perl
use v5.28;
use strict;
use warnings FATAL => 'all';

my $filename = "resources/MasterFiles/short_exam_master_file.txt"; # < means open for reading
open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

my %questions;
my $question;

while (my $row = readline($filehandle)) {

    $row = trim($row);

    if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
        #say "question: " . $row;
        $question = $row;
    }
    elsif(substr($row,0,1) eq '[' && defined($question)) {
        #say "option:   " . $row;
        push @{ $questions{$question} }, $row; # append option to anonymous array
    }
    else {
        #say "__skip line" . $row
    }
}

for my $current_question ( keys %questions ) {
    say "$current_question";
    for my $i ( 0 .. $#{ $questions{$current_question} } ) {
        say "$questions{$current_question}[$i]";
    }
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };