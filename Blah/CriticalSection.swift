//
//  CriticalSection.swift
//  Blah
//
//  Created by Brad Howes on 10/9/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Process a closure in thread-safe fashion.
 - parameter obj: the object to protect while executing the closure
 - parameter closure: the code to execute
 */
func synchronized(obj: AnyObject, closure: () -> ()) {
    defer { objc_sync_exit(obj) }
    objc_sync_enter(obj)
    closure()
}
