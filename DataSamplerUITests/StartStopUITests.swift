//
//  DataSamplerUITests.swift
//  DataSamplerUITests
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest

class StartStopUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
        XCUIDevice.shared().orientation = .portrait
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testStartStop() {
        let app = XCUIApplication()
        let toolbarsQuery = app.toolbars
        let start = toolbarsQuery.buttons["Play"]
        XCTAssertTrue(start.exists)
        let stop = toolbarsQuery.buttons["Stop"]
        XCTAssertFalse(stop.exists)

        let graphsTabButton = app.tabBars.children(matching: .button).element(boundBy: 0)
        let recordingsTabButton = app.tabBars.children(matching: .button).element(boundBy: 1)
        let settingsTabButton = app.tabBars.children(matching: .button).element(boundBy: 2)

        // Before we start a new recording, get the current count of rows in the recordings table.
        //
        recordingsTabButton.tap()
        let recordingsTable = app.tables.element(boundBy: 0)
        let recordingsCount = recordingsTable.cells.count
        graphsTabButton.tap()
        print(recordingsCount)

        // Start new recording
        //
        start.tap()
        self.expectation(for: NSPredicate(format: "self.exists = 1"), evaluatedWith: stop, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        // Verify that start button disappears and stop button is present
        //
        XCTAssertTrue(stop.exists)
        XCTAssertFalse(start.exists)

        // Move to recordings view and see if we have a new row.
        //
        recordingsTabButton.tap()
        self.expectation(for: NSPredicate(format: "self.count = \(recordingsCount + UInt(1))"),
                         evaluatedWith: recordingsTable.cells, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(recordingsCount + UInt(1), recordingsTable.cells.count)

        // Verify that the first cell is showing recording
        //
        let recordingCell = recordingsTable.cells.element(boundBy: 0)
        let recordingStatus = recordingCell.staticTexts.element(boundBy: 1) // 0 is the directory name
        XCTAssertTrue(recordingStatus.label.contains("Recording"))

        // Verify that swiping reveals NO action buttons since recording is active
        //
        recordingCell.swipeLeft()
        XCTAssertEqual(recordingCell.buttons.count, 0)
        recordingCell.tap()

        recordingCell.swipeRight()
        XCTAssertEqual(recordingCell.buttons.count, 0)
        recordingCell.tap()

        // Stop recording
        //
        graphsTabButton.tap()
        stop.tap()
        self.expectation(for: NSPredicate(format: "self.exists = 1"), evaluatedWith: start, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        // Verify that stop button disappears and start button returns
        //
        XCTAssertTrue(start.exists)
        XCTAssertFalse(stop.exists)

        // Go back and check recording state
        //
        recordingsTabButton.tap()

        // Verify that the first cell is NOT showing recording
        //
        XCTAssertFalse(recordingStatus.label.contains("Recording"))

        // Swipe right and verify buttons
        //
        recordingCell.swipeRight()
        XCTAssertEqual(recordingCell.buttons.count, 2)
        let shareButton = recordingCell.buttons.element(boundBy: 0)
        let deleteButton = recordingCell.buttons.element(boundBy: 1)
        XCTAssertEqual(shareButton.label, "share")
        XCTAssertEqual(deleteButton.label, "Delete")

        XCTAssertTrue(recordingCell.frame.contains(shareButton.frame))
        XCTAssertFalse(recordingCell.frame.contains(deleteButton.frame))
        recordingCell.tap()

        // Swipe left and verity buttons
        //
        recordingCell.swipeLeft()
        XCTAssertFalse(recordingCell.frame.contains(shareButton.frame))
        XCTAssertTrue(recordingCell.frame.contains(deleteButton.frame))

        // Delete row/cell
        //
        deleteButton.tap()
        self.expectation(for: NSPredicate(format: "self.count = \(recordingsCount)"),
                         evaluatedWith: recordingsTable.cells, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
