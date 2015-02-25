#!/usr/bin/env -i xcrun swift

////////////////////////////////////////////////////////////////////////////////
// Script Name: template.swift
// Written by: John W. Woolsey
// Copyright © 2015.  All rights reserved.
// Description:
//   Swift shell script template with command line interface.
//   Please see the printHelp function for syntax information.
////////////////////////////////////////////////////////////////////////////////


import Foundation
import Darwin


// MARK: - Globals

// Program information
var programRevision = "$Revision: 1.1 $"
var programDate = "$Date: 2015/02/23 19:35:39 $"
var programName = "template.swift"
var numberOfErrors = 0

// Command line options
var debugOption = 0
var helpOption = 0
var versionOption = 0
var outputFileName:String?


// MARK: - Functions

/**
Initializes program.
*/
func initProgram() {
   let programRevisionComponents = split(programRevision, { $0 == " " }, maxSplit:Int.max, allowEmptySlices:false)
   if programRevisionComponents.count > 1 {
      programRevision = programRevisionComponents[1]
   }
   let programDateComponents = split(programDate, { $0 == " " }, maxSplit:Int.max, allowEmptySlices:false)
   if programDateComponents.count > 1 {
      programDate = programDateComponents[1]
   }
   if Process.arguments.count > 0 {
      programName = Process.arguments[0].lastPathComponent
   }
}


/**
Prints program version.
*/
func printVersion() {
   println("\(programName)  \(programRevision)  \(programDate)")
}


/**
Prints program help message.
*/
func printHelp() {
   printVersion()
   println()
   println("Description:")
   println("  Swift shell script template with command line interface.\n")
   println("Syntax: \(programName) [ -d ] -h | -v | [ -o <outfile> ] <infile>\n")
   println("Where:")
   println("  <infile>  represents the input text (.txt) file(s).")
   println("  <outfile> represents the output text file.\n")
   println("Options:")
   println("  -d            specify debug mode.")
   println("  -h            print program help.")
   println("  -o <outfile>  specify output file name.")
   println("  -v            print program version.\n")
   println("Example Invocation:")
   println("  % \(programName) -o ofile.txt ifile.txt")
}


/**
Finalizes and ends program.
*/
func endProgram() {
   if debugOption != 0 {
      println("\(programName): DEBUG - Program ended with exit code of '\(numberOfErrors)'")
   }
   exit(Int32(numberOfErrors))
}


/**
Get command line options.

:returns: The number of processed command line arguments.
*/
func getOptions() -> Int {
   var argumentsProcessedCount = 1
   let pattern = "dho:v"
   var buffer = Array(pattern.utf8).map { Int8($0) }
   if C_ARGC < 2 {  // check for command line arguments
      println("\(programName): ERROR - Missing command line arguments")
      numberOfErrors += 1
      printHelp()
      endProgram()
   }
   while true {
      let option = Int(getopt(C_ARGC, C_ARGV, buffer))
      if option == -1 { break }  // no more options available
      argumentsProcessedCount += 1
      switch "\(UnicodeScalar(option))" {
      case "d":  // debug mode
         debugOption = 1
      case "h":  // print help message
         helpOption = 1
      case "o":  // output file specified
         outputFileName = String.fromCString(optarg)
         argumentsProcessedCount += 1
         if let fileName = outputFileName {
            if fileName.hasPrefix("-") {
               println("\(programName): ERROR - Missing output file name")
               numberOfErrors += 1
               printHelp()
               endProgram()
            }
         } else {
            println("\(programName): ERROR - Could not retrieve output file name")
            numberOfErrors += 1
            printHelp()
            endProgram()
         }
      case "v":  // print version message
         versionOption = 1
      default:
         println("\(programName): ERROR - Could not retrieve an argument")
         numberOfErrors += 1
         printHelp()
         endProgram()
      }
   }
   return argumentsProcessedCount
}


/**
Processes command line options.
*/
func processOptions() {
   if debugOption != 0 {
      println("\(programName): DEBUG - Running in debug mode")
      println("\(programName): DEBUG - Arguments are \(Process.arguments)")
      if let fileName = outputFileName {
         println("\(programName): DEBUG - Output file name is '\(fileName)'")
      }
   }
   if helpOption != 0 {
      printHelp()
      endProgram()
   } else if versionOption != 0 {
      printVersion()
      endProgram()
   }
}


/**
Processes input files.

:param: inputFileNames The input file names.

:returns: The result of processing the input files.
*/
func processFiles(inputFileNames:[String]) -> String {
   var results = ""
   let fileManager = NSFileManager.defaultManager()
   for fileName in inputFileNames {
      if debugOption != 0 {
         println("\(programName): DEBUG - Processing file '\(fileName)'")
      }
      if !fileName.lowercaseString.hasSuffix(".txt") || !fileManager.fileExistsAtPath(fileName) {
         println("\(programName): ERROR - Could not read from file '\(fileName)'")
         numberOfErrors += 1
         continue
      }
      if let fileContents = String(contentsOfFile:fileName, encoding:NSUTF8StringEncoding, error:nil) {
         for row in fileContents.componentsSeparatedByString("\n") {  // rows separated by new lines
            if countElements(row) > 0 {
               results += programName + ": " + row + "\n"
            }
         }
      } else {
         println("\(programName): ERROR - Could not read from file '\(fileName)'")
         numberOfErrors += 1
      }
   }
   return results
}


/**
Prints results.

:param: results The contents to print.
*/
func printResults(results:String) {
   if countElements(results) > 0 {
      if let fileName = outputFileName {
         var fileError:NSError?
         results.writeToFile(fileName, atomically:false, encoding:NSUTF8StringEncoding, error:&fileError);
         if fileError != nil {
            println("\(programName): ERROR - Could not write to file '\(fileName)'")
            numberOfErrors += 1
         }
      } else {
         print(results)
      }
   }
}


// MARK: - Main Section

initProgram()
let argumentsProcessedCount = getOptions()
processOptions()
var inputFileNames = [String]()
for argument in Process.arguments[argumentsProcessedCount..<Process.arguments.count] {
   inputFileNames.append(argument)
}
let results = processFiles(inputFileNames)
printResults(results)
endProgram()


// MARK: - Revision History

////////////////////////////////////////////////////////////////////////////////
// Revision History
//
// $Log: template.swift,v $
// Revision 1.1  2015/02/23 19:35:39  woolsey
// Initial revision
//
