//
//  BRHEventLog.swift
//  DataSampler
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/** 
 Protocol for all Logger classes
 */
protocol LoggerInterface {
    static func clear()
    static func save(to url: URL, done: @escaping (Int64)->() )
    static func restore(from url: URL)
    static func log(format: String, _ args: CVarArg...) -> String
    @discardableResult static func log(_ args: CVarArg...) -> String
}

/**
 A `Logger` instance collects log statements for saving to a file and displaying in a UITextView.
 - SeeAlso: `TextRecorder`
 */
final class Logger : TextRecorder, LoggerInterface {

    /// The sole instance available for logging.
    static let singleton = Logger()

    /**
     Clear out any previous log data.
     */
    static func clear() {
        singleton.clear()
    }

    /**
     Write the contents of Logger to disk.
     - parameter url: the location where to write to
     - parameter done: closure called when done which reports how many bytes were written
     */
    static func save(to url: URL, done: @escaping (Int64)->() ) {
        singleton.save(to: url, done: done)
    }

    /**
     Restore the contents of Logger from disk
     - parameter url: the location where to read from
     */
    static func restore(from url: URL) {
        singleton.restore(from: url)
    }

    /**
     Add a new log entry by applying a format string to a set of arguments
     - parameter format: the format to apply to the arguments
     - parameter args: the arguments to format
     - returns: the full text that was added to the log
     */
    @discardableResult static func log(format: String, _ args: CVarArg...) -> String {
        let s = String(format: format, arguments: args)
        return singleton.add(s)
    }

    @discardableResult func log(format: String, _ args: CVarArg...) -> String {
        let s = String(format: format, arguments: args)
        return add(s)
    }

    /**
     Add a new log entry. Converts given arguments to a String.
     - parameter args: the arguments to add
     - returns: the full text that was added to the log
     */
    @discardableResult static func log(_ args: CVarArg...) -> String {
        let value = args.map { "\($0)" }.joined(separator: " ")
        return singleton.add(value)
    }

    @discardableResult func log(_ args: CVarArg...) -> String {
        let value = args.map { "\($0)" }.joined(separator: " ")
        return add(value)
    }

    /**
     Constructor for a new `Logger`
     */
    override init(fileName: String = "log.txt",
                  timestampGenerator: TimestampGeneratorInterface = TimestampGenerator()) {
        super.init(fileName: fileName, timestampGenerator: timestampGenerator)
    }

    /**
     Add a new log entry.
     - parameter line: the log entry
     - returns: the full text that was added to the log
     */
    @discardableResult override internal func add(_ line: String) -> String {
        var s = line
        if !s.hasSuffix("\n") {
            s.append("\n")
        }
        s = self.timestamp() + " " + s
        NSLog(s)
        return super.add(s)
    }
}
