//
//  BlahTests.swift
//  BlahTests
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
import Foundation

@testable import Blah

class UserSettingsTests: XCTestCase {

    let userSettings = UserSettings()

    override func setUp() {
        userSettings.emitInterval = 120
        userSettings.write()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(userSettings.count, 13)
    }

    func testDelayedUpdate() {
        XCTAssertEqual(userSettings.emitInterval, 120)
        userSettings.emitInterval = 100
        XCTAssertEqual(userSettings.emitInterval, 100)

        var ei = UserDefaults.standard.string(forKey: "emitInterval")
        XCTAssertNotNil(ei)
        XCTAssertEqual(ei!, "120")

        userSettings.write()
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        
        XCTAssertEqual(userSettings.emitInterval, 100)
        ei = UserDefaults.standard.string(forKey: "emitInterval")
        XCTAssertNotNil(ei)
        XCTAssertEqual(ei!, "100")
    }
    
    func testInvalidIntValueUpdate() {
        XCTAssertEqual(userSettings.emitInterval, 120)
        UserDefaults.standard.set("", forKey: "emitInteval")
        userSettings.read()
        XCTAssertEqual(userSettings.emitInterval, 120)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
