#!/usr/bin/swift

////////////////////////////////////////////////////////////////////////////////
// Script Name: template.swift
// Written by: John W. Woolsey
// Copyright © 2015-16.  All rights reserved.
// Description:
//   Swift shell script template with command line interface.
//   Please see the printHelp function for syntax information.
////////////////////////////////////////////////////////////////////////////////

// TODO: Send errors to StdError

import Foundation
#if os(OSX)
   import Darwin
#elseif os(Linux)
   import Glibc
#endif


// MARK: - Properties

var outputDateFormatter: NSDateFormatter {
   let formatter = NSDateFormatter()
   formatter.dateFormat = "MM/dd/yyyy"
   return formatter
}
let programName = (Process.arguments[0] as NSString).lastPathComponent
var programVersion = "$Revision: 1.2 $"  // Changed automatically by RCS
var programDate: String {
   if let fileAttributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(Process.arguments[0]),
      modificationDate = fileAttributes["NSFileModificationDate"] as? NSDate {
      return outputDateFormatter.stringFromDate(modificationDate)
   } else {
      return ""
   }
}
var numberOfErrors = 0
var debugOption = 0
var helpOption = 0
var versionOption = 0
var outputFileName:String?


// MARK: - Functions

/**
 Initializes program.
 */
func initProgram() {
   let programVersionComponents = programVersion.characters.split(" ").map(String.init)
   if programVersionComponents.count > 1 {
      programVersion = programVersionComponents[1]
   }
}


/**
 Prints program version.
 */
func printVersion() {
   print("\(programName)  \(programVersion)  \(programDate)")
}


/**
 Prints program help message.
 */
func printHelp() {
   printVersion()
   // MARK: Program Syntax
   print("")
   print("Description:")
   print("  Swift based command line program template.\n")
   print("Syntax: \(programName) [ -d ] -h | -v | [ -o <outfile> ] <infile>\n")
   print("Where:")
   print("  <infile>  represents the input text (.txt) file(s).")
   print("  <outfile> represents the output text file.\n")
   print("Options:")
   print("  -d            specify debug mode.")
   print("  -h            print program help.")
   print("  -o <outfile>  specify output file name.")
   print("  -v            print program version.\n")
   print("Example Invocation:")
   print("  % \(programName) input.txt")
   print("  % \(programName) -o ofile.txt ifile.txt")
}


/**
 Finalizes and ends program.
 */
func endProgram() {
   if debugOption != 0 {
      print("\(programName): DEBUG - Program ended with exit code of '\(numberOfErrors)'.")
   }
   exit(Int32(numberOfErrors))
}


/**
 Get command line options.
 
 - returns: The number of processed command line arguments.
 */
func getOptions() -> Int {
   var argumentsProcessedCount = 1
   let pattern = "dho:v"
   let buffer = Array(pattern.utf8).map { Int8($0) }
   if Process.argc < 2 {  // check for command line arguments
      print("\(programName): ERROR - Missing command line arguments.")
      numberOfErrors += 1
      printHelp()
      endProgram()
   }
   while true {
      let option = Int(getopt(Process.argc, Process.unsafeArgv, buffer))
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
               print("\(programName): ERROR - Missing output file name.")
               numberOfErrors += 1
               printHelp()
               endProgram()
            }
         } else {
            print("\(programName): ERROR - Could not retrieve output file name.")
            numberOfErrors += 1
            printHelp()
            endProgram()
         }
      case "v":  // print version message
         versionOption = 1
      default:
         print("\(programName): ERROR - Could not retrieve an argument.")
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
      print("\(programName): DEBUG - Running in debug mode.")
      print("\(programName): DEBUG - Arguments are \(Process.arguments).")
      if let fileName = outputFileName {
         print("\(programName): DEBUG - Output file name is '\(fileName)'.")
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
 
 - parameter inputFileNames: The input file names.
 
 - returns: The result of processing the input files.
 */
func processFiles(inputFileNames:[String]) -> String {
   var results = ""
   let fileManager = NSFileManager.defaultManager()
   for fileName in inputFileNames {
      if debugOption != 0 {
         print("\(programName): DEBUG - Processing file '\(fileName)'.")
      }
      if !fileName.lowercaseString.hasSuffix(".txt") || !fileManager.fileExistsAtPath(fileName) {
         print("\(programName): ERROR - Could not read from file '\(fileName)'.")
         numberOfErrors += 1
         continue
      }
      do {
         let fileContents = try String(contentsOfFile: fileName, encoding: NSUTF8StringEncoding)
         for row in fileContents.componentsSeparatedByString("\n") {  // rows separated by new lines
            if row.characters.count > 0 {
               // TODO: Do file processing here
               results += programName + ": " + row + "\n"
            }
         }
      } catch let error as NSError {
         print("\(programName): ERROR - Could not read from file '\(fileName)'.  \(error.localizedDescription)")
         numberOfErrors += 1
      }
   }
   return results
}


/**
 Prints results.
 
 - parameter results: The contents to print.
 */
func printResults(results:String) {
   if results.characters.count > 0 {
      if let fileName = outputFileName {
         do {
            try results.writeToFile(fileName, atomically: false, encoding: NSUTF8StringEncoding)
         } catch let error as NSError {
            print("\(programName): ERROR - Could not write to file '\(fileName)'.  \(error.localizedDescription)")
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
// Revision 1.2  2016/06/10 15:19:05  woolsey
// Updated to Swift 2.2 syntax.
//
// Revision 1.1  2015/02/23 19:35:39  woolsey
// Initial revision
//
