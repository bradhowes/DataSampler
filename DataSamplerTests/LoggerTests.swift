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
        let log = Logger.singleton
        let directory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

        XCTAssertEqual("01:00:01.100 this is 1 test\n", Logger.log(format: "this %@ %d %@", "is", 1, "test"))
        XCTAssertEqual("01:00:02.200 this is 2 test\n", Logger.log("this", "is", 2, "test"))

        log.save(to: directory) { (count: Int64) in
            XCTAssertEqual(count, 163)
            let s = String(log.logText)
            print(s)
            XCTAssertTrue(s.contains("01:00:01.100 this is 1 test\n"))
            XCTAssertTrue(s.contains("01:00:02.200 this is 2 test\n"))
            log.clear()
            Logger.restore(from: directory)
            XCTAssertEqual(String(log.logText), s)
        }
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
