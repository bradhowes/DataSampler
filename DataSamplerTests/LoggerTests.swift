//
//  BRHLoggerTests
//  DataSamplerTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class LoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Logger.singleton.timestampGenerator = FixedTimestampGenerator()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        print("NSHomeDirectory: \(NSHomeDirectory())")
        let logger = Logger(fileName: "LoggerTests_testExample.txt", timestampGenerator: FixedTimestampGenerator())
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

        XCTAssertEqual("01:00:01.100 this is 1 test\n",
                       logger.log(format: "this %@ %d %@", "is", 1, "test"))
        XCTAssertEqual("01:00:02.200 this is 2 test\n",
                       logger.log("this", "is", 2, "test"))

        let s = String(logger.logText)
        print(s)
        XCTAssertTrue(s.contains("01:00:01.100 this is 1 test\n"))
        XCTAssertTrue(s.contains("01:00:02.200 this is 2 test\n"))

        let exp = expectation(description: "Logger save")
        logger.save(to: directory) { (count: Int64) in
            XCTAssertEqual(count, 56)
            logger.restore(from: directory)
            XCTAssertEqual(String(logger.logText), s)
            exp.fulfill()
        }

        print("*** after LoggerTests_testExample.txt save")
        waitForExpectations(timeout: 5.0, handler:nil)
    }

    func testMultithreading() {
        let group = DispatchGroup()
        let log = Logger.singleton
        log.clear()
        for i in 0...3 {
            for j in 0...3 {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async(group: group, qos: .userInitiated, flags: .assignCurrentContext) { () -> Void in
                    Logger.log(format: "block %d - %d", i, j)
                    group.leave()
                }
            }
        }

        group.wait()
        Logger.log("done")
        let s = String(log.logText)
        for i in 0...3 {
            for j in 0...3 {
                XCTAssertTrue(s.contains(" block \(i) - \(j)\n"))
            }
        }
    }
}
