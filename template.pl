eval 'exec perl -w $0 ${1+"$@"}'    # -*-Perl-*-
if 0;
#-------------------------------------------------------------------------------
# Script Name: template.pl
# Written by: John W. Woolsey
#-------------------------------------------------------------------------------

initProgram();  # initialize program features
our $helpMsg = <<HMSG;  # help message

Description:
  Perl script template with command line interface.

Syntax:  $program [ -d[ebug] ]
   -h[elp] | -v[ersion] | [ -o[ut] <outfile> ] <infile>

Where:
  <infile>  represents the input file(s).
  <outfile> represents the output file.

Options:
  -d[ebug]          specify debug mode.
  -h[elp]           print program help.
  -o[ut] <outfile>  specify output filename.
  -v[ersion]        print program version.

Example Invocation:
  % $program -out ofile ifile
HMSG

getArguments();  # get command line arguments

while (<>) {  # process contents of each file
   print "$program:  $_";
}

endProgram(0);  # finalize and end program

#-------------------------------------------------------------------------------
# initProgram subroutine
# initializes program
# arguments: none
# return: none
sub initProgram {

   # includes
   use strict;              # syntax checker
   use warnings;            # display warning messages
   use Getopt::Long;        # argument parsing
   use POSIX qw(strftime);  # time routines

   # program information
   my @program = split(m!/!, $0);  # get program name
   our $program = pop(@program);
   our ($progRev) = '$Revision: 1.1 $' =~ /Revision: (\S+) \$/;  # get program revision number
   our ($progDate) = '$Date: 2011/11/09 04:26:32 $' =~ /Date: (.+) \$/;  # get program revision date

   # global settings
   my $pwd = $ENV{PWD};  # get current working directory
   my $date = strftime "%y%m%d%H%M%S", localtime;  # get current date and time
   our $tmpDir = "$pwd/${program}_$ENV{USER}_$date";  # name of temporary directory
   $|=1;  # turn output buffering off

   if (! mkdir($tmpDir)) {  # create temporary directory
      print STDERR "$program:  ERROR - Could not create directory $tmpDir: $!\n";
      endProgram(1);
   }
}  # initProgram

#-------------------------------------------------------------------------------
# endProgram subroutine
# finalizes and ends program
# arguments: exit code
# return: none
sub endProgram {
   my ($exitCode) = @_;  # get arguments

   if ($options{out}) {  # close output file
      close(OFILE);
   }
   unlink <$tmpDir/*>;  # remove temporary data
   rmdir($tmpDir);
   exit($exitCode);
}  # endProgram

#-------------------------------------------------------------------------------
# getArguments subroutine
# get command line arguments
# arguments: none
# return: none
sub getArguments {

   our %options;  # command line options

   if (! GetOptions(\%options,
      'debug',    # specify debug mode
      'help',     # print program help 
      'out=s',    # specify output filename
      'version',  # print program version
   )) {
      print STDERR "$program:  ERROR - Unknown option on command line\n";
      printHelp();
      endProgram(1);
   }
   if ($options{out}) {  # output file specified
      our $outFile = $options{out};
      if (! open(OFILE, ">$outFile")) {  # open output file
         print STDERR "$program:  ERROR - Could not create file $outFile: $!\n";
         endProgram(1);
      }
      select(OFILE);  # redirect STDOUT to output file
   }
   if ($options{debug}) {  # debug mode requested
      print "$program:  DEBUG - Running in debug mode\n";
      print "$program:  DEBUG - Arguments: ";
      foreach my $option (sort keys %options) {  # print options
         print " $option = $options{$option},";
      }
      print " ARGV = @ARGV\n";
   }
   if ($options{help}) {  # print help message on request or error
      printHelp();
      endProgram(0);
   }
   if ($options{version}) {  # version message requested
      printVersion();
      endProgram(0);
   }
   if ($#ARGV < 0) {  # no command line arguments
      print STDERR "$program:  ERROR - Missing arguments from command line\n";
      printHelp();
      endProgram(1);
   }
}  # getArguments

#-------------------------------------------------------------------------------
# printVersion subroutine
# prints program version
# arguments: none
# return: none
sub printVersion {

   print "$program  $progRev  $progDate\n";
}  # printVersion

#-------------------------------------------------------------------------------
# printHelp subroutine
# prints help message
# arguments: none
# return: none
sub printHelp {

   printVersion();
   print $helpMsg;
}  # printHelp

#-------------------------------------------------------------------------------
# Revision History
#
# $Log: template.pl,v $
# Revision 1.1  2011/11/09 04:26:32  woolsey
# Initial revision
#
