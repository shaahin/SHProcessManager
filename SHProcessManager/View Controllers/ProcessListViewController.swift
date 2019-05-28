//
//  ViewController.swift
//  SHProcessManager
//
//  Created by Shahin on 2/12/19.
//

import Cocoa
import Security
import ServiceManagement
class ProcessListViewController: NSViewController, AppProtocol {

    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var killButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var configLabel: NSTextField!
    
    var helperConnectionManager: HelperConnectionManager?
    @objc dynamic private var currentHelperAuthData: NSData?

    
    var showingProcesses: [ProcessItem] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // initialize helper connection
        helperConnectionManager = HelperConnectionManager(owner: self)
        
        // initialize processes
        updateStatus("Loading processes...", withLoading: true)
        DispatchQueue.global().async {
            DataProvider.shared.getProcesses()
        }
        
    }
    override func viewWillAppear() {
         NotificationCenter.default.addObserver(self, selector: #selector(processListUpdated), name: Notification.Name(DataProvider.shared.notificationName), object: DataProvider.shared)
    }

    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: -
    // MARK: View Methods
    func updateStatus(_ message: String, withLoading loading: Bool) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = message
            if loading {
                self.progressIndicator.startAnimation(self)
            }else{
                self.progressIndicator.stopAnimation(self)
            }
        }
    }
    

    func showAlert(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    func showAlert(forError error: Error) {
        DispatchQueue.main.async {
            NSAlert(error: error).runModal()
        }
    }
    // MARK: -
    // MARK: Actions
    
    @IBAction func killProcess(_ sender: NSButton) {
        
        let process = DataProvider.shared.filteredProcesses(self.searchField.stringValue)[tableView.selectedRow]
        
        let alert = NSAlert()
        alert.messageText = "Kill process: \(process.title) with PID: \(process.pid)"
        alert.informativeText = "Are you sure?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn
        {
            if NSUserName() == process.user
            {
                // can be killed normally
                updateStatus("Killing PID: \(process.pid)", withLoading: true)
                DispatchQueue.global().async {
                    let result = runShellCommand("/bin/kill", args: ["\(process.pid)"])
                    if result?.trimmingCharacters(in: CharacterSet.newlines) == "" {
                        DispatchQueue.main.async {
                            self.updateStatus("PID: \(process.pid) killed successfully.", withLoading: false)
                        }
                    }else{
                        DispatchQueue.main.async {
                            self.updateStatus("PID: \(process.pid) failed to kill because: \(result ?? "")", withLoading: false)
                        }
                    }
                }
                
            }else {
                // needs privileged access
                do {
                    guard let authData = try self.currentHelperAuthData ?? HelperAuthorization.emptyAuthorizationExternalFormData() else {
                        showAlert("Failed to get the empty authorization external form")
                        return
                    }
                    guard
                        let helper = helperConnectionManager?.helper(nil),
                        let _ = helperConnectionManager?.helperConnection else {
                            showAlert("Failed to connect to helper")
                            return
                    }
                    
                    let kill = { () in
                        self.updateStatus("Killing PID: \(process.pid) as administrator", withLoading: true)
                        helper.killProcess(withPID: "\(process.pid)", authData: authData) { (success,result) in
                            
                            if result is NSNumber &&  result as! NSNumber == kAuthorizationFailedExitCode {
                                self.showAlert( "Authentication Failed")
                                return
                            }
                            if self.currentHelperAuthData == nil {
                                self.currentHelperAuthData = authData
                            }
                            DispatchQueue.main.async {
                                if success {
                                    self.updateStatus("PID: \(process.pid) kill command sent as administrator.", withLoading: false)
                                }else{
                                    self.updateStatus("PID: \(process.pid) failed to kill because: \(result)", withLoading: false)
                                }
                            }
                        }
                    }
                    
                     kill()
                
                } catch {
                    showAlert(forError: error)
                    
                }
                
                
                
            }
        }
    }
    

    // MARK: -
    // MARK: AppProtocol (Not used for this app)
    
    func log(stdOut: String) {
        guard !stdOut.isEmpty else { return }
        OperationQueue.main.addOperation {
            print(stdOut)
        }
    }
    
    func log(stdErr: String) {
        guard !stdErr.isEmpty else { return }
        OperationQueue.main.addOperation {
            print(stdErr)
        }
    }
    
    
    
    // MARK: -
    // MARK: Process List Updated Notification
    @objc func processListUpdated() {
        DispatchQueue.main.async {
            
            self.showingProcesses = DataProvider.shared.filteredProcesses(self.searchField.stringValue)
            self.updateStatus("Showing \(self.showingProcesses.count) processes.", withLoading: false)
            self.configLabel.stringValue = "Showing \( DataProvider.shared.currentMineOnlyProcesses ? "owned" : "all" ) processes. Refreshing every \(DataProvider.shared.currentRefreshRate) seconds."
            
            let selectedRowIndices = self.tableView.selectedRowIndexes
            self.tableView.reloadData()
            self.tableView.selectRowIndexes(selectedRowIndices, byExtendingSelection: true)
        }
        
    }
    
}

extension ProcessListViewController: NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return showingProcesses.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let process = showingProcesses[row]
        let result = tableView.makeView(withIdentifier: (tableColumn?.identifier)!, owner: self) as! NSTableCellView
        
        switch tableColumn?.identifier.rawValue {
        case "title":
            result.textField?.stringValue =  process.title
        case "pid":
            result.textField?.stringValue =  "\(process.pid)"
        case "user":
            result.textField?.stringValue =  process.user
        case "cpu":
            result.textField?.stringValue =  "\(process.cpu)"
        case "priority":
            result.textField?.stringValue =  "\(process.priority)"
        case "command":
            result.textField?.stringValue =  process.command
        default:
            return process.pid
        }
        return result
    }
}

extension ProcessListViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow != -1 {
            let process = showingProcesses[tableView.selectedRow]
            killButton.isEnabled = true
            if NSUserName() == process.user
            {
                killButton.title = "Kill"
            }else {
                killButton.title = "🔑 Kill"
            }
            
        }else {
            killButton.title = "Kill"
            killButton.isEnabled = false
        }
    }
}

extension ProcessListViewController: NSTextFieldDelegate {
    public func controlTextDidChange(_ obj: Notification) {
        processListUpdated()
    }
}
