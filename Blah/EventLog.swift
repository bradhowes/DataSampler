//
//  BRHEventLog.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol EventLogInterface {
    static func clear()
    static func save(to url: URL, done: @escaping (Int64)->() )
    static func restore(from url: URL)
    static func log(_ args: CVarArg...)
}

/**
 An `EventLog` instance collects "events", a comma-separated list of values. The collection can be saved to a file 
 and shown in a UITextView.
 - SeeAlso: `TextRecorder`
 */
class EventLog : TextRecorder, EventLogInterface {

    /// The sole instance available for logging.
    static let singleton = EventLog()

    /**
     Clear out any previous log data.
     */
    static func clear() {
        singleton.clear()
    }

    static func save(to url: URL, done: @escaping (Int64)->() ) {
        singleton.save(to: url, done: done)
    }

    static func restore(from url: URL) {
        singleton.restore(from: url)
    }

    /**
     Add a new event entry. Converts given arguments to a String.
     - parameter args: the arguments to add
     */
    static func log(_ args: CVarArg...) {
        let value = args.map { "\($0)" }.joined(separator: ",")
        singleton.add(value)
    }

    /**
     Constructor for a new `EventLog` instance
     */
    private init() {
        super.init(fileName: "events.csv")
    }

    /**
     Add a new event entry.
     - parameter line: the event entry
     */
    override internal func add(_ line: String) {
        var s = line
        if !s.hasSuffix("\n") {
            s.append("\n")
        }
        s = self.timestamp() + "," + s
        super.add(s)
    }
}
