//
//  BRHEventLog.swift
//  DataSampler
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for all EventLog classes
 */
protocol EventLogInterface {

    /**
     Clear the log.
     */
    static func clear()

    /**
     Save the contents of the log to a file.
     - parameter url: the URL of the file to save to
     - parameter done: closure invoked at end of save operation that conveys the number of bytes that were written
     */
    static func save(to url: URL, done: @escaping (Int64)->() )
    static func restore(from url: URL)
    @discardableResult static func log(_ args: CVarArg...) -> String
}

/**
 An `EventLog` instance collects "events", a comma-separated list of values. The collection can be saved to a file 
 and shown in a UITextView.
 - SeeAlso: `TextRecorder`
 */
final class EventLog : TextRecorder, EventLogInterface {

    /// The sole instance available for logging.
    static let singleton = EventLog()

    /**
     Clear out any previous log data, and allow for new entries
     */
    static func clear() {
        singleton.clear()
    }

    /**
     Save the current collection of events to a file
     - parameter url: the location where the file will be
     - parameter done: closure invoked at end of save operation that conveys the number of bytes that were written
     */
    static func save(to url: URL, done: @escaping (Int64)->() ) {
        singleton.save(to: url, done: done)
    }

    /**
     Restore a previously-saved collection of events
     - parameter url: the location where file is
     */
    static func restore(from url: URL) {
        singleton.restore(from: url)
    }

    /**
     Add a new event entry. Converts given arguments to a String.
     - parameter args: the arguments to add
     */
    @discardableResult static func log(_ args: CVarArg...) -> String {
        let value = args.map { "\($0)" }.joined(separator: ",")
        return singleton.add(value)
    }

    @discardableResult func log(_ args: CVarArg...) -> String {
        let value = args.map { "\($0)" }.joined(separator: ",")
        return add(value)
    }

    /**
     Constructor for a new `EventLog` instance.
     - parameter timestampGenerator: a generator for timestamp values
     */
    override init(fileName: String = "events.csv",
                  timestampGenerator: TimestampGeneratorInterface = TimestampGenerator()) {
        super.init(fileName: fileName, timestampGenerator: timestampGenerator)
    }

    /**
     Add a new event entry.
     - parameter line: the event entry
     - returns: the full text that was added to the log
     */
    @discardableResult override internal func add(_ line: String) -> String {
        var s = line
        if !s.hasSuffix("\n") {
            s.append("\n")
        }
        s = self.timestamp() + "," + s
        return super.add(s)
    }
}
