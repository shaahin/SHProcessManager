//
//  DataProvider.swift
//  SHProcessManager
//
//  Created by Shahin Katebi on 2/13/19.
//

import Cocoa

class DataProvider {
    //singleton instance
    static let shared = DataProvider()
    
    let notificationName = "process list updated"
    private let configurationAppId = "us.shaahin.SHProcessManager" as CFString
    var currentRefreshRate = 3
    var currentMineOnlyProcesses = false
    
    var processes: [ProcessItem] = []
    
    func getProcesses(){
        
        var args: [String] = []
        
        // get mine_only from prefrerences
        if let mineOnly = CFPreferencesCopyAppValue("mine_only" as CFString,configurationAppId){
            currentMineOnlyProcesses = (mineOnly as? Bool) ?? false
        }
        
        if currentMineOnlyProcesses {
            args.append(contentsOf: ["-u\(NSUserName())", "-o"])
        }else {
            args.append("-eo")
        }
        args.append("user=,pid=,%cpu=,pri=,comm=")
        let string = runShellCommand("/bin/ps", args: args )
        if let lines = string?.split(separator: Character("\n"))
        {
            let pattern = "([\\w0-9\\/\\.])+"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            processes = []
            for line in lines {
                let lineString = String(line)
                let range = NSRange(lineString.startIndex..<lineString.endIndex,
                                    in: lineString)
                let results = regex.matches(in: String(lineString), options: [], range: range).map {
                    String(lineString[Range($0.range, in: lineString)!])
                }
                if results.count == 5 {
                    processes.append(ProcessItem(title: URL(string: results[4])?.lastPathComponent ?? "-", user: results[0], command: results[4], pid: Int(results[1]) ?? -1, priority: Int(results[3]) ?? -1, cpu: Double(results[2]) ?? 0))
                }else{
                    // throw error, invalid data
                }
                
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.notificationName), object: self)
            }
            if let refreshRateConfig = CFPreferencesCopyAppValue("refresh_rate" as CFString,configurationAppId) {
                currentRefreshRate = (refreshRateConfig as? Int) ?? 3
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(currentRefreshRate)) {
                self.getProcesses()
            }
        }
    }
    
    func filteredProcesses(_ search: String) -> [ProcessItem] {
        if search == "" {
            return self.processes
        }
        return self.processes.filter { (process) -> Bool in
            return process.command.lowercased().contains(search.lowercased()) || process.user.lowercased().contains(search.lowercased())
        }
        
    }
}


struct ProcessItem {
    var title, user, command: String
    var pid,priority: Int
    var cpu: Double
}
