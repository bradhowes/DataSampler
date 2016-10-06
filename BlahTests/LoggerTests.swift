//
//  BRHLoggerTests
//  BlahTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import Blah

class LoggerTests: XCTestCase {

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
        let log = Logger.singleton
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        log.logPath = directory

        Logger.log(format: "this %@ %d %@", "is", 1, "test")
        Logger.log("this", "is", 2, "test")
        log.save()
        
        let s = log.logContentFor(folder: directory)
        print("s: \(s)")
        XCTAssertTrue(s.contains("this is 1 test\n"))
        XCTAssertTrue(s.contains("this is 2 test\n"))

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
