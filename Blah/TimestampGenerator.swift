//
//  TimestampGenerator.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/** 
 Interface for objects that provide a timestamp value as a String
 */
protocol TimestampGeneratorInterface {
    typealias Timestamp = String
    var value: Timestamp { get }
}

/** 
 Implementation of TimestampGeneratorInterface using `Date` for times.
 */
final class TimestampGenerator: NSObject, TimestampGeneratorInterface {

    var value: TimestampGeneratorInterface.Timestamp {
        get {
            return dateTimeFormatter.string(from: Date())
        }
    }

    var dateTimeFormatter: DateFormatter

    /**
     Initialize new instance.
     - parameter format: the format to use for the timestamps. See `DateFormatter`.
     */
    init(format: String = "HH:mm:ss.SSS") {
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.setLocalizedDateFormatFromTemplate(format)
        super.init()
    }
}
