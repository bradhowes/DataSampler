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
        let log = EventLog.singleton
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

        EventLog.log("this", "is", "a", "test")
        EventLog.log(1, 2, 3, 4.0, "hello", 5.0)
        log.save(to: directory) { (count: Int64) in
            XCTAssertEqual(count, 15)
            let s = String(log.logText)
            print(s)
            XCTAssertTrue(s.contains(",this,is,a,test"))
            XCTAssertTrue(s.contains(",1,2,3,4.0,hello,5.0"))
            log.clear()
            log.restore(from: directory)
            XCTAssertEqual(String(log.logText), s)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
