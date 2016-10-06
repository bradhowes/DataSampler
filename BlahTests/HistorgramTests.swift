//
//  BlahTests.swift
//  BlahTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import Blah

class HistogramTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        let hist = Histogram.init(size: 10)
        XCTAssertEqual(hist.binAt(index: 0), 0)
        XCTAssertEqual(hist.maxValue(), 0)
    }
    
    func testBinning() {
        let hist = Histogram.init(size: 3)
        XCTAssertEqual(hist.binIndexFor(value: 1.5), 1)
        XCTAssertEqual(hist.binIndexFor(value: 0.0), 0)
        XCTAssertEqual(hist.binIndexFor(value: -1.0), 0)
        XCTAssertEqual(hist.binIndexFor(value: 2.0), 2)
        XCTAssertEqual(hist.binIndexFor(value: 999999.0), 2)
    }

    func testAdd() {
        let hist = Histogram.init(size: 10)
        var _ = hist.add(value: 0.1)
        _ = hist.add(value: 0.2)
        _ = hist.add(value: 0.3)
        _ = hist.add(value: 0.4)
        XCTAssertEqual(hist.binAt(index: 0), 4)
        XCTAssertEqual(hist.maxValue(), 4)
        _ = hist.add(value: 1.1)
        _ = hist.add(value: 1.2)
        XCTAssertEqual(hist.binAt(index: 0), 4)
        XCTAssertEqual(hist.binAt(index: 1), 2)
        XCTAssertEqual(hist.maxValue(), 4)
        _ = hist.add(value: 1.3)
        _ = hist.add(value: 1.4)
        _ = hist.add(value: 1.5)
        XCTAssertEqual(hist.maxValue(), 5)
        XCTAssertEqual(hist.binAt(index: 2), 0)
    }
    
    func testGraphSource() {
        let hist = Histogram.init(size: 3)
        var _ = hist.add(value: 0.1)
        _ = hist.add(value: 0.2)
        _ = hist.add(value: 0.3)
        _ = hist.add(value: 0.4)
        _ = hist.add(value: 1.1)
        _ = hist.add(value: 1.2)
        _ = hist.add(value: 1.3)
        _ = hist.add(value: 1.4)
        _ = hist.add(value: 1.5)
        XCTAssertEqual(hist.numberOfRecords(), 3)
        XCTAssertEqual(hist.valueForRecord(0), 4)
    }
    
    func testClear() {
        let hist = Histogram.init(size: 3)
        var _ = hist.add(value: 0.1)
        _ = hist.add(value: 0.2)
        _ = hist.add(value: 0.3)
        _ = hist.add(value: 0.4)
        _ = hist.add(value: 1.1)
        _ = hist.add(value: 1.2)
        _ = hist.add(value: 1.3)
        _ = hist.add(value: 1.4)
        _ = hist.add(value: 1.5)
        XCTAssertEqual(hist.binAt(index: 0), 4)
        XCTAssertEqual(hist.binAt(index: 1), 5)
        XCTAssertEqual(hist.maxValue(), 5)
        
        hist.clear()
        XCTAssertEqual(hist.binAt(index: 0), 0)
        XCTAssertEqual(hist.binAt(index: 1), 0)
        XCTAssertEqual(hist.maxValue(), 0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
