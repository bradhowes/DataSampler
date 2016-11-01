//
//  BRHBinFormatterTests.swift
//  DataSampler
//
//  Created by Brad Howes on 9/21/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class HistogramBinFormatterTests: XCTestCase {
    
    func testFormatting() {
        let bf = HistogramBinFormatter(lastBin: 10)
        XCTAssertEqual(bf.string(for: NSNumber(integerLiteral: 0)), "<1")
        XCTAssertEqual(bf.string(for: NSNumber(integerLiteral: 1)), "1")
        XCTAssertEqual(bf.string(for: NSNumber(integerLiteral: 9)), "9")
        XCTAssertEqual(bf.string(for: NSNumber(integerLiteral: 10)), "10+")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
