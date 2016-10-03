//
//  BRHEventLogTests.swift
//  BlahTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import Blah

class BRHEventLogTests: XCTestCase {

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
        let log = BRHEventLog.sharedInstance()
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        log.logPath = directory

        BRHEventLog.log("this", "is", "a", "test")
        BRHEventLog.log(1, 2, 3, 4.0, "hello", 5.0)
        log.save()

        let s = log.logContentFor(folder: directory)
        print("s: \(s)")

        XCTAssertTrue(s.contains("this,is,a,test\n"))
        XCTAssertTrue(s.contains("1,2,3,4.0,hello,5.0\n"))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
