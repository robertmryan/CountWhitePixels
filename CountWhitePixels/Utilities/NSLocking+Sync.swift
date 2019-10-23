//
//  NSLocking+Sync.swift
//  CountWhitePixels
//
//  Created by Robert Ryan on 10/22/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import Foundation

extension NSLocking {
    func sync<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}
