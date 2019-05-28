//
//  HelperConnectionManager.swift
//  SHProcessManager
//
//  Created by Shahin on 2/12/19.
//

import Cocoa
import ServiceManagement

class HelperConnectionManager {
    
    private let owner: AppProtocol!
    
    init(owner: AppProtocol) {
        self.owner = owner
    }

    
    // public properties
    private var _helperConnection: NSXPCConnection?
    
    var helperConnection: NSXPCConnection? {
        if(_helperConnection == nil)
        {
            let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
            connection.exportedInterface = NSXPCInterface(with: AppProtocol.self)
            connection.exportedObject = owner
            connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            connection.invalidationHandler = {
                self._helperConnection = nil
            }
            _helperConnection = connection
            connection.resume()
        }
        return _helperConnection
    }
    
    
    
    func helperStatus(completion: @escaping (_ installed: Bool) -> Void) {
        
        // Comppare the CFBundleShortVersionString from the Info.plisin the helper inside our application bundle with the one on disk.
        
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/" + HelperConstants.machServiceName)
        guard
            let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL) as? [String: Any],
            let helperVersion = helperBundleInfo["CFBundleShortVersionString"] as? String,
            let helper = self.helper(completion) else {
                completion(false)
                return
        }
        
        helper.getVersion { installedHelperVersion in
            completion(installedHelperVersion == helperVersion)
        }
        completion(true)
    }
    func helper(_ completion: ((Bool) -> Void)?) -> HelperProtocol? {
        
        // Get the current helper connection and return the remote object (Helper.swift) as a proxy object to call functions on.
        guard let helper = self.helperConnection?.remoteObjectProxyWithErrorHandler({ error in
            //self.textViewOutput.appendText("Helper connection was closed with error: \(error)")
            print("ERROR: \(error)")
            if let onCompletion = completion { onCompletion(false) }
        }) as? HelperProtocol else { return nil }
        return helper
    }
    
    
    
    
}
