//
//  ShellHelper.swift
//  SHProcessManager
//
//  Created by Shahin Katebi on 2/13/19.
//

import Cocoa
import Foundation

func runShellCommand(_ path: String, args: [String]) -> String?
{
    var process: Process!
    if #available(OSX 10.13, *) {
        process = Process()
        process.arguments = args
        process.executableURL = URL(fileURLWithPath: path)
    } else {
        // Fallback on earlier versions
        process = Process()
        process.launchPath = path
        process.arguments = args
        
    }

    let outputPipe = Pipe()
    //process.standardInput = nil
    process.standardOutput = outputPipe
    if !process.isRunning
    {
        do {
            if #available(OSX 10.13, *) {
                try process.run()
            } else {
                // Fallback on earlier versions
                process.launch()
            }
        }catch {
            // throw error
        }
        
    }
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    
    
    return String(data: outputData, encoding: String.Encoding.utf8)
    
}
