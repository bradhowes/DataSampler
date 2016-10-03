//
//  BRHEventLog.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class BRHEventLog : BRHTextRecorder {
    
    private static let singleton = BRHEventLog()

    static func sharedInstance() -> BRHEventLog {
        return BRHEventLog.singleton
    }

    static func clear() {
        sharedInstance().clear()
    }

    static func log(_ args: CVarArg...) {
        let value = args.map { "\($0)" }.joined(separator: ",")
        sharedInstance().add(value)
    }

    private init() {
        super.init(fileName: "events.csv")
    }

    override internal func add(_ line: String) {
        var s = line
        if !s.hasSuffix("\n") {
            s.append("\n")
        }
        s = self.timestamp() + "," + s
        super.add(s)
    }
}
