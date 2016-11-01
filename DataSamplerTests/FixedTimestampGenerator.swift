//
//  FixedTimestampGenerator.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
@testable import Blah

final class FixedTimestampGenerator: NSObject, TimestampGeneratorInterface {

    var value: String {
        counter += 1.1
        return dateTimeFormatter.string(from: Date(timeIntervalSince1970: counter))
    }

    private var counter: TimeInterval
    private var dateTimeFormatter: DateFormatter

    init(format: String = "HH:mm:ss.SSS") {
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.setLocalizedDateFormatFromTemplate(format)
        self.counter = 0.0
        super.init()
    }
}
