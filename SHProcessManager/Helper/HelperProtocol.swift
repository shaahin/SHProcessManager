//
//  HelperProtocol.swift
//  SwiftPrivilegedHelper
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

@objc(HelperProtocol)
protocol HelperProtocol {
    func getVersion(completion: @escaping (String) -> Void)
    func killProcess(withPID: String, authData: NSData?, completion: @escaping (Bool, Any) -> Void)
}
