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

final class TimestampGenerator: NSObject, TimestampGeneratorInterface {

    var value: TimestampGeneratorInterface.Timestamp {
        get {
            return dateTimeFormatter.string(from: Date())
        }
    }

    var dateTimeFormatter: DateFormatter

    init(format: String = "HH:mm:ss.SSS") {
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.setLocalizedDateFormatFromTemplate(format)
        super.init()
    }
}
