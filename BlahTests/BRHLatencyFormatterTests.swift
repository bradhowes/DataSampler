//
//  BRHBinFormatterTests.swift
//  Blah
//
//  Created by Brad Howes on 9/21/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import Blah

class BRHLatencyFormatterTests: XCTestCase {
    
    func testFormatting() {
        let lf = BRHLatencyFormatter()
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.0)), "0")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.1)), "0.1")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.01)), "0")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.5)), "0.5")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.9)), "0.9")
        XCTAssertEqual(lf.string(for: NSNumber(value: 0.9999)), "1")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
