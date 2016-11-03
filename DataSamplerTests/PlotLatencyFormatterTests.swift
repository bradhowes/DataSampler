//
//  BRHBinFormatterTests.swift
//  DataSampler
//
//  Created by Brad Howes on 9/21/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class PlotLatencyFormatterTests: XCTestCase {
    
    func testFormatting() {
        let lf = PlotLatencyFormatter()
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.0))!, "0")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.1))!, ".1")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.01))!, "0")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.06))!, ".1")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.5))!, ".5")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.9))!, ".9")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.9999))!, "1")
    }
}
