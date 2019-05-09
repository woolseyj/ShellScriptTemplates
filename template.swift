#!/usr/bin/swift

////////////////////////////////////////////////////////////////////////////////
// Script Name: template.swift
// Written by: John W. Woolsey
// Copyright © 2015.  All rights reserved.
// Description:
//   Swift shell script template with command line interface.
//   Please see the printHelp function for syntax information.
////////////////////////////////////////////////////////////////////////////////


import Foundation
#if os(macOS)
   import Darwin
#elseif os(Linux)
   import Glibc
#endif


// MARK: - Enumerations

enum ConsoleOutputType {
   case standard
   case debug
   case warning
   case error
}


// MARK: - Properties

// Program information
var outputDateFormatter: DateFormatter {
   let formatter = DateFormatter()
   formatter.dateFormat = "MM/dd/yyyy"
   return formatter
}
let programPath = CommandLine.arguments[0]
let programName = (programPath as NSString).lastPathComponent
var programVersion = "$Revision: 1.5 $"  // Changed automatically by RCS
var programDate: String {
   if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: programPath),
      let fileModificationDate = fileAttributes[FileAttributeKey.modificationDate] as? Date {
      return outputDateFormatter.string(from: fileModificationDate)
   } else {
      return ""
   }
}
var numberOfErrors = 0

// Command line options
var debugOption = false
var helpOption = false
var versionOption = false
var outputFileName:String?


// MARK: - Functions

/// Initializes program.
func initProgram() {
   let programVersionComponents = programVersion.components(separatedBy: " ")
   if programVersionComponents.count > 1 {
      programVersion = programVersionComponents[1]
   }
}


/// Prints program version.
func printVersion() {
   print("\(programName)  \(programVersion)  \(programDate)")
}


/// Prints program help message.
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


/// Finalizes and ends program.
func endProgram() {
   if debugOption {
      writeMessage("Program ended with exit code of '\(numberOfErrors)'.", to: .debug)
   }
   exit(Int32(numberOfErrors))
}


/// Gets command line options.
///
/// - Returns: The number of processed command line arguments.
func getOptions() -> Int {
   var argumentsProcessedCount = 1
   let pattern = "dho:v"
   let buffer = Array(pattern.utf8).map { Int8($0) }
   while true {
      let option = Int(getopt(CommandLine.argc, CommandLine.unsafeArgv, buffer))
      if option == -1 { break }  // no more options available
      argumentsProcessedCount += 1
      switch "\(UnicodeScalar(UInt8(option)))" {
      case "d":  // debug mode
         debugOption = true
      case "h":  // print help message
         helpOption = true
      case "o":  // output file specified
         outputFileName = String(cString: optarg)
         argumentsProcessedCount += 1
         if let fileName = outputFileName {
            if fileName.hasPrefix("-") {
               writeMessage("Missing output file name.", to: .error)
               numberOfErrors += 1
               printHelp()
               endProgram()
            }
         } else {
            writeMessage("Could not retrieve output file name.", to: .error)
            numberOfErrors += 1
            printHelp()
            endProgram()
         }
      case "v":  // print version message
         versionOption = true
      default:
         writeMessage("Could not retrieve an argument.", to: .error)
         numberOfErrors += 1
         printHelp()
         endProgram()
      }
   }
   return argumentsProcessedCount
}


/// Processes command line options.
func processOptions() {
   if debugOption {
      writeMessage("Running in debug mode.", to: .debug)
      writeMessage("Arguments are \(CommandLine.arguments).", to: .debug)
      if let fileName = outputFileName {
         writeMessage("Output file name is '\(fileName)'.", to: .debug)
      }
   }
   if helpOption {
      printHelp()
      endProgram()
   } else if versionOption {
      printVersion()
      endProgram()
   }
}


/// Processes input files.
///
/// - Parameter inputFileNames: The input file names.
/// - Returns: The result of processing the input files.
func processFiles(_ inputFileNames:[String]) -> String {
   var results = ""
   let fileManager = FileManager.default
   for fileName in inputFileNames {
      if debugOption {
         writeMessage("Processing file '\(fileName)'.", to: .debug)
      }
      if !fileName.lowercased().hasSuffix(".txt") || !fileManager.fileExists(atPath: fileName) {
         writeMessage("Could not read from file '\(fileName)'.", to: .error)
         numberOfErrors += 1
         continue
      }
      do {
         let fileContents = try String(contentsOfFile: fileName, encoding: String.Encoding.utf8)
         for row in fileContents.components(separatedBy: "\n") {  // rows separated by new lines
            if row.count > 0 {
               // TODO: Do file processing here
               results += programName + ": " + row + "\n"
            }
         }
      } catch let error {
         writeMessage("Could not read from file '\(fileName)'.  \(error.localizedDescription)", to: .error)
         numberOfErrors += 1
      }
   }
   return results
}


/// Prints results.
///
/// - Parameter results: The contents to print.
func printResults(_ results:String) {
   if results.count > 0 {
      if let fileName = outputFileName {
         do {
            try results.write(toFile: fileName, atomically: false, encoding: String.Encoding.utf8)
         } catch let error {
            writeMessage("Could not write to file '\(fileName)'.  \(error.localizedDescription)", to: .error)
            numberOfErrors += 1
         }
      } else {
         print(results)
      }
   }
}


/// Writes a message to the console.
///
/// Messages with .debug, .warning, and .error types are prepended with the associated type.
///
/// The .standard and .debug types are sent to STDOUT, whereas .warning and .error types are sent to STDERR.
///
/// - Parameters:
///   - message: The message to write.
///   - to: The message type.  One of .standard (default), .debug, .warning, or .error must be used.
func writeMessage(_ message: String, to: ConsoleOutputType = .standard) {
   switch to {
   case .standard:
      print("\(programName): \(message)")
   case .debug:
      print("\(programName): DEBUG - \(message)")
   case .warning:
      fputs("\(programName): Warning - \(message)\n", stderr)
   case .error:
      fputs("\(programName): ERROR - \(message)\n", stderr)
   }
}


// MARK: - Main Section

initProgram()
let argumentsProcessedCount = getOptions()
processOptions()
if CommandLine.arguments.count <= argumentsProcessedCount {  // check for file arguments
   writeMessage("Missing command line arguments.", to: .error)
   numberOfErrors += 1
   printHelp()
   endProgram()
}
var inputFileNames = [String]()
for argument in CommandLine.arguments[argumentsProcessedCount..<CommandLine.arguments.count] {
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
// Revision 1.5  2019/05/09 01:31:46  woolsey
// Changed OSX to macOS in compiler directive.
//
// Revision 1.4  2019/05/08 21:42:14  woolsey
// Updated to Swift 5.0 compatibility.
//
// Revision 1.3  2016/12/04 16:03:03  woolsey
// Migrated to Swift 3.0.
//
// Revision 1.2  2016/06/10 15:19:05  woolsey
// Updated to Swift 2.2 syntax.
//
// Revision 1.1  2015/02/23 19:35:39  woolsey
// Initial revision
//
