//
//  main.swift
//  SwiftPrivilegedHelper
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

let helper = Helper()
try? "App ran".write(to: URL(string: "/Users/shahin/shahin-test.txt")!, atomically: true, encoding: String.Encoding.utf8)
helper.run()
