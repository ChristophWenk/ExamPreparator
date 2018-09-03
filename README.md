# ExamPreparator
Perl project to automatically create and mark exams.
The application consists of two scripts and one module:

- create_master_file.pl
- score_exams.pl
- statistics.pm

**create_master_file** takes a master answer file template as input, removes all previously set [X] from the answers, scrambles the order of the answers for each question and writes the result to an output file.

**score_exams.pl** takes a master file as input as well as one or several student answer files. It analyzes the answer files according to the master file and collects and if possible corrects all slight mismatches. It then scores the answer files and calls the statistics module for output. Additionally the script will look for possible academic misconducts and calculates the likelyhood of a possible miscoduct.

**statistics.pm** takes a hash with students score results as input and writes several statistics for each file and the consolidated data. It then formats the data for output and presents the data to the user. This module can only be called with the score_exams.pl script.


## Usage

All files must be called from the project root directory. Otherwise the directory paths will not match.

### create_master_file.pl
To create a blank master file place the filled out exam master file in the *resources/MasterFiles/* directory.

Call syntax: *perl bin/create_master_file \<master_file>*

The generated master file be written to *out/{timestamp}-{input_file_name}*

### score_exams.pl
To analyze the response files place them in the *resources/Responses/* directory.

**Process a single file**
Call syntax: *perl bin/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/Responses/\<response_file>

**Process multiple files**
Call syntax: *perl bin/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/Responses/\<response_file> [response_file] [...]*

**Process all files**
Call syntax: *perl bin/score_exams.pl resources/MasterFiles/FHNW_entrance_exam_master_file_2017.txt resources/Responses/\**

The output will be presented in the console.
