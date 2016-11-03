//
//  BRHEventLogTests.swift
//  DataSamplerTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class EventLogTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        print("NSHomeDirectory: \(NSHomeDirectory())")
        let eventLog = EventLog(fileName: "testExample.csv")
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

        eventLog.log("this", "is", "a", "test")
        eventLog.log(1, 2, 3, 4.0, "hello", 5.0)
        let s = String(eventLog.logText)
        print(s)
        XCTAssertTrue(s.contains(",this,is,a,test"))
        XCTAssertTrue(s.contains(",1,2,3,4.0,hello,5.0"))

        let exp = expectation(description: "EventLog save")

        eventLog.save(to: directory) { (count: Int64) in
            XCTAssertEqual(count, 61)
            eventLog.clear()
            eventLog.restore(from: directory)
            let r = String(eventLog.logText)
            XCTAssertEqual(r, s)
            exp.fulfill()
        }

        print("*** after testExample.csv save")
        waitForExpectations(timeout: 5.0, handler:nil)
    }
}
