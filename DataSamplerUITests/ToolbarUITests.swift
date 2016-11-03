//
//  DataSamplerUITests.swift
//  DataSamplerUITests
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest

class ToolbarUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
        XCUIDevice.shared().orientation = .portrait
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func getTextView(app: XCUIApplication, named: String) -> XCUIElement {
        let other = app.otherElements[named]
        if other.exists { return other }
        let textView = app.textViews[named]
        if textView.exists { return textView }
        fatalError("missing item: \(named)")
    }

    func testToolbar() {
        let app = XCUIApplication()
        let rootFrame = app.windows.element(boundBy: 0).frame
        let toolbar = app.toolbars.element(boundBy: 0)

        let histogramButton = toolbar.buttons["Histogram"]
        let logButton = toolbar.buttons["Log"]
        let eventButton = toolbar.buttons["Events"]


        // Default view shows histogram plot
        //
        let histogramView = getTextView(app: app, named: "HistogramView")
        XCTAssertTrue(histogramView.exists)
        XCTAssertTrue(rootFrame.contains(histogramView.frame))

        // Switch to log view
        //
        logButton.tap()
        let logView = getTextView(app: app, named: "LogView")
        XCTAssertTrue(logView.exists)
        XCTAssertTrue(rootFrame.contains(logView.frame))

        // Switch to event view
        //
        eventButton.tap()
        let eventView = getTextView(app: app, named: "EventsView")
        XCTAssertTrue(eventView.exists)
        XCTAssertTrue(rootFrame.contains(eventView.frame))

        // Switch to histogram view
        //
        histogramButton.tap()
        XCTAssertTrue(histogramView.exists)
        XCTAssertTrue(rootFrame.contains(histogramView.frame))
    }
}
