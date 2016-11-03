//
//  BRHBinFormatterTests.swift
//  DataSampler
//
//  Created by Brad Howes on 9/21/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class PlotTimeFormatterTests: XCTestCase {
    
    func testFormatting() {
        let bf = PlotTimeFormatter()
        XCTAssertEqual(bf.string(for: NSNumber(value: 0.0)), "0s")
        XCTAssertEqual(bf.string(for: NSNumber(value: 0.9)), "1s")
        XCTAssertEqual(bf.string(for: NSNumber(value: 59.99)), "1m")
        XCTAssertEqual(bf.string(for: NSNumber(value: 60.4)), "1m")
        XCTAssertEqual(bf.string(for: NSNumber(value: 60.0 - 0.6)), "59s")
        XCTAssertEqual(bf.string(for: NSNumber(value: 3600.0 - 1.0)), "59m59s")
        XCTAssertEqual(bf.string(for: NSNumber(value: 3600.0 * 3 + 59.0)), "3h59s")
    }
}
