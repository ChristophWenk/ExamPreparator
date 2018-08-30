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
#my %master_answers = get_answers(%master_questions);

#my $student_filename =  "resources/SampleResponses/20170828-092520-FHNW_entrance_exam-ID006431";
#my %student_questions = get_questions_with_options($student_filename);
#my %student_answers = get_answers(%student_questions);

#check_missing_content(%student_questions);

# sub check_missing_content(%student){
#     for my $current_question (keys %master_questions) {
#         if(!defined($student{$current_question})){
#             #say "missing question: " . $current_question;
#                 next;
#         }
#
#         for my $option_index ( 0 .. $#{ $master_questions{$current_question} } ) {
#             #say $master_questions{$current_question}[$option_index];
#             #say Dumper(@{ $student{$current_question}});
#             #say "searching: $master_questions{$current_question}[$option_index]";
#             #print Dumper(@{ $student{$current_question} });
#             #if (!defined($student{$current_question}[$current_option]) ) {
#             #print Dumper($student{$current_question});
#             if ( grep( /^$master_questions{$current_question}[$option_index]$/, @{ $student{$current_question} }) ) {
#                 say "missing option: " . $master_questions{$current_question}[$option_index];
#             }
#
#
#
#         }
#     }
# }

# sub get_answers(%questions){
#     my %answers;
#
#     for my $current_question (keys %questions) {
#
#         $answers{$current_question} = undef;
#
#         for my $current_option ( 0 .. $#{ $questions{$current_question} } ) {
#             #if option selected
#             if (substr($questions{$current_question}[$current_option], 0, 3) eq '[X]'
#               && !defined($answers{$current_question}) ) {
#                 $answers{$current_question} = $questions{$current_question}[$current_option];
#             }
#             # more than one option selected, answer no valid
#             elsif(substr($questions{$current_question}[$current_option], 0, 3) eq '[X]'
#                 && defined($answers{$current_question})){
#                 $answers{$current_question} = undef;
#                 last;
#             }
#         }
#     }
#     return %answers;
# }

sub get_questions_with_options($filename) {

    open(my $filehandle, "<", $filename) or die "Could not open file '$filename' $!" ;

    my %questions;
    my $current_question;
    my %current_options;

    while (my $row = readline($filehandle)) {

        $row = trim($row);

        if(substr($row,0,1) =~ /^\d/) {  # if row starts with a number
            $current_question = $row;
        }
        elsif(substr($row,0,1) eq '_' && defined($current_question)){ # save question with options
            $questions{$current_question} = { %current_options };
            %current_options = ();
            $current_question = undef;
        }
        elsif(substr($row,0,1) eq '[' && defined($current_question)) { #add option
            $current_options{$row} = undef;
        }

        else { #say "__skip line" . $row
        }
    }
    #print Dumper(%current_options);
    return %questions;
}

print Dumper(%master_questions);
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