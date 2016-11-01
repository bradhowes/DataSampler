//
//  BRHCollection+AdditionsTests.swift
//  DataSampler
//
//  Created by Brad Howes on 9/18/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest
@testable import DataSampler

class CollectionAdditionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPartitions() {
        var collection = [1, 3, 5, 7, 9]
        var pos: Int = collection.insertionIndexOf(value: 4, predicate: <)
        XCTAssertEqual(pos, 2)
        collection.insert(4, at: pos)
        XCTAssertEqual(collection, [1,3,4,5,7,9])
        pos = collection.insertionIndexOf(value: 10, predicate: <)
        XCTAssertEqual(pos, 6)
        collection.insert(10, at: pos)
        XCTAssertEqual(collection, [1,3,4,5,7,9,10])
    }

    func testEmptyCollection() {
        var collection = [Int]()
        var pos = collection.insertionIndexOf(value: 123, predicate: <)
        XCTAssertEqual(pos, 0)
        collection.insert(123, at: pos)
        XCTAssertEqual(collection, [123])
        pos = collection.insertionIndexOf(value: 123, predicate: <)
        XCTAssertEqual(pos, 0)
    }

    func testOrderedArray() {
        var collection = OrderedArray<Int>(predicate: <)
        XCTAssertEqual(collection.count, 0)
        collection.add(value:10)
        XCTAssertEqual(collection.count, 1)
        collection.add(value:5)
        collection.add(value:1)
        collection.add(value:11)
        XCTAssertEqual(collection.items, [1,5,10,11])
        XCTAssertEqual(collection.removeLast(), 11)
        XCTAssertEqual(collection.popLast(), Optional(10))
        collection.removeAll()
        XCTAssertEqual(collection.popLast(), nil)
    }
    
    func testBinarySearch() {
        let collection = [1, 3, 5, 7, 9]
        for each in collection {
            XCTAssertTrue(collection.binarySearchFor(value: each, predicate: <))
        }

        for each in [0, 2, 4, 6, 8, 10] {
            XCTAssertFalse(collection.binarySearchFor(value: each, predicate: <))
        }
    }
    
    func testMinMax() {
        let a: Array<Int> = [1, 3, 5, 7, 9]
        let mm = a.minMax()
        XCTAssertEqual(mm?.min, 1)
        XCTAssertEqual(mm?.max, 9)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
