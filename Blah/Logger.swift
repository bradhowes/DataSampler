//
//  BRHEventLog.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

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
class Logger : TextRecorder, LoggerInterface {

    /// The sole instance available for logging.
    static let singleton = Logger()

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
     Add a new log entry by applying a format string to a set of arguments
     - parameter format: the format to apply to the arguments
     - parameter args: the arguments to format
     */
    @discardableResult static func log(format: String, _ args: CVarArg...) -> String {
        let s = String(format: format, arguments: args)
        return singleton.add(s)
    }

    /**
     Add a new log entry. Converts given arguments to a String.
     - parameter args: the arguments to add
     */
    @discardableResult static func log(_ args: CVarArg...) -> String {
        let value = args.map { "\($0)" }.joined(separator: " ")
        return singleton.add(value)
    }

    /**
     Constructor for a new `Logger`
     */
    private init() {
        super.init(fileName: "log.txt")
    }

    /**
     Add a new log entry.
     - parameter line: the log entry
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
