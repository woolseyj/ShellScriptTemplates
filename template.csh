#!/bin/csh -f
#-------------------------------------------------------------------------------
# Script Name: template.csh
# Written by: John W. Woolsey
# Description is located at bottom of script.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
initProg:  # initializes program
onintr catch

# program information
set program = `basename $0`
set progRev = `echo '$Revision: 1.2 $' | awk '{print $2}'`
set progDate = `echo '$Date: 2011/11/09 04:54:10 $' | awk '{print $2}' | awk -F/ '{printf "%s/%s/%s",$2,$3,$1}'`
set exitCode = 0

# global settings
set date = `date +%y%m%d%H%M%S`
set tmpDir = "${PWD}/${program}_${USER}_$date"
mkdir $tmpDir

#-------------------------------------------------------------------------------
getArguments:  # get command line arguments (position dependent)
if ($#argv == 0) then  # expect at least one argument
   echo "${program}:  ERROR - Missing arguments from command line"
   set exitCode = 1
   goto printHelp
endif
set options_debug = 0
set outfile = ""
# long option names are not supported on Mac OS X
set argv = (`getopt dhvo: $*`)  # get command line arguments
# set argv = (`getopt -a -o dhvo: --long debug,help,version,out: -- $*| sed "s/'//g"`)  # get command line arguments

if ($status == 0) then
   while ($#argv > 1)
      switch ($argv[1])
         # case --debug:  # debug mode
         case -d:
            set options_debug = 1
            echo "${program}:  DEBUG - Running in debug mode"
            breaksw
         # case --help:  # print help message
         case -h:
            goto printHelp
            breaksw
         # case --version:  # print version message
         case -v:
            goto printVersion
            breaksw
         # case --out:  # output file specified
         case -o:
            set outfile = $argv[2]
            if ($options_debug) then
                echo "${program}:  DEBUG - output file = $outfile"
            endif
            echo -n "" >! $outfile
            shift argv
            breaksw
         case --:  # end of options
            break
            breaksw
         default:  # unknown option
            echo "${program}:  ERROR - Unknown option on command line"
            set exitCode = 1
            goto printHelp
            breaksw
      endsw
      shift argv
   end
   shift argv
else
   echo "${program}:  ERROR - Unknown option on command line"
   set exitCode = 1
   goto printHelp
endif
if ($options_debug) then
   echo "${program}:  DEBUG - argv = $argv"
endif
if ($#argv == 0) then
   echo "${program}:  ERROR - Missing arguments from command line"
   set exitCode = 1
   goto printHelp
endif


#-------------------------------------------------------------------------------
main:  # main section
foreach var ($*)  # process each file (not contents)
   if ($outfile != "") then
      echo "${program}:  Processing $var" >> $outfile
   else
      echo "${program}:  Processing $var"
   endif
end
goto endProg

#-------------------------------------------------------------------------------
catch:  # interrupt handler
echo "$program was interrupted or terminated abnormally."
set exitCode = 1

#-------------------------------------------------------------------------------
endProg:  # finalizes and ends program
rm -rf $tmpDir
exit $exitCode

#-------------------------------------------------------------------------------
printVersion:  # prints program version
echo "$program  $progRev  $progDate"
goto endProg

#-------------------------------------------------------------------------------
# printHelp:  # prints help message
# echo "$program  $progRev  $progDate"
# echo
# cat << HMSG
# Description:
#   C shell script template with command line interface.
# 
# Syntax:  $program [ -d[ebug] ]
#    -h[elp] | -v[ersion] | [ -o[ut] <outfile> ] <infile>
# 
# Where:
#   <infile>  represents the input file(s).
#   <outfile> represents the output file.
# 
# Options:
#   -d[ebug]           specify debug mode.
#   -h[elp]            print program help.
#   -o[out] <outfile>  specify output filename.
#   -v[ersion]         print program version.
# 
# Example Invocation:
#   % $program -o ofile ifile
# HMSG
# goto endProg

#-------------------------------------------------------------------------------
printHelp:  # prints help message
echo "$program  $progRev  $progDate"
echo
cat << HMSG
Description:
  C shell script template with command line interface.

Syntax:  $program [ -d ] -h | -v | [ -o <outfile> ] <infile>

Where:
  <infile>  represents the input file(s).
  <outfile> represents the output file.

Options:
  -d            specify debug mode.
  -h            print program help.
  -o <outfile>  specify output filename.
  -v            print program version.

Example Invocation:
  % $program -o ofile ifile
HMSG
goto endProg

#-------------------------------------------------------------------------------
# Revision History
#
# $Log: template.csh,v $
# Revision 1.2  2011/11/09 04:54:10  woolsey
# Updated getopts since Darwin Unix does not support long option format.
#
# Revision 1.1  2011/11/09 04:27:42  woolsey
# Initial revision
#
