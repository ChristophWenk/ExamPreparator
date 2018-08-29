#!/usr/bin/perl
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';

my $master_filename = "resources/MasterFiles/short_exam_master_file.txt";
my %master_questions = get_questions_with_options($master_filename);
my %master_answers = get_answers(%master_questions);

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

print Dumper(%master_questions);
say "###############################################";
print Dumper(%master_answers);

#for my $current_question ( keys %master_questions ) {
#    say "$current_question";
#    for my $i ( 0 .. $#{ $master_questions{$current_question} } ) {
#        say "$master_questions{$current_question}[$i]";
#    }
#}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
