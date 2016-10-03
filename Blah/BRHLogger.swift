//
//  BRHEventLog.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class BRHLogger : BRHTextRecorder {
    
    private static let singleton = BRHLogger()

    static func sharedInstance() -> BRHLogger {
        return BRHLogger.singleton
    }

    static func clear() {
        sharedInstance().clear()
    }

    static func log(format: String, _ args: CVarArg...) {
        let s = String(format: format, arguments: args)
        sharedInstance().add(s)
    }

    static func log(_ args: CVarArg...) {
        let value = args.map { "\($0)" }.joined(separator: " ")
        sharedInstance().add(value)
    }

    private init() {
        super.init(fileName: "log.txt")
    }

    override internal func add(_ line: String) {
        var s = line
        if !s.hasSuffix("\n") {
            s.append("\n")
        }
        s = self.timestamp() + " " + s
        super.add(s)
    }
}
