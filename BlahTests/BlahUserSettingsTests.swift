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

class BlahUserSettingsTests: XCTestCase {

    let userSettings = BRHUserSettings.settings()

    override func setUp() {
        userSettings.emitInterval.value = 120
        userSettings.syncToUserDefaults()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(BRHSettingBase.defaults.count, 12)
    }

    func testDelayedUpdate() {
        XCTAssertEqual(userSettings.emitInterval.value, 120)
        userSettings.emitInterval.value = 100
        XCTAssertEqual(userSettings.emitInterval.value, 100)
        XCTAssertEqual(userSettings.emitInterval.defaultsValue, "100")

        var ei = UserDefaults.standard.string(forKey: "emitInterval")
        XCTAssertNotNil(ei)
        XCTAssertEqual(ei!, "120")

        userSettings.syncToUserDefaults()
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        
        XCTAssertEqual(userSettings.emitInterval.value, 100)
        ei = UserDefaults.standard.string(forKey: "emitInterval")
        XCTAssertNotNil(ei)
        XCTAssertEqual(ei!, "100")
    }
    
    func testInvalidIntValueUpdate() {
        XCTAssertEqual(userSettings.emitInterval.value, 120)
        UserDefaults.standard.set("", forKey: "emitInteval")
        userSettings.syncFromUserDefaults()
        XCTAssertEqual(userSettings.emitInterval.value, 120)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
