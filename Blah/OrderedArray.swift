//
//  BRHOrderedArray.swift
//  Blah
//
//  Created by Brad Howes on 9/18/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

struct OrderedArray<Element:Comparable> : Collection, CustomDebugStringConvertible {

    typealias Predicate = (Element, Element) -> Bool

    private(set) var items: [Element]
    private let predicate: Predicate

    var startIndex: Int { get { return 0 } }
    var endIndex: Int { get { return items.count } }
    var count: Int { get { return items.count } }

    var last: Element { get { return items[endIndex - 1] } }

    var debugDescription: String { get { return "OrderedArray: \(items)" } }
    var description: String { get { return "OrderedArray: \(items)" } }

    init(predicate: @escaping Predicate = (<)) {
        self.items = []
        self.predicate = predicate
    }

    init(items: [Element], predicate: @escaping Predicate = (<)) {
        self.items = items
        self.predicate = predicate
        self.items.sort(by: predicate)
    }

    init(count: Int, repeatedValue: Element, predicate: @escaping Predicate = (<)) {
        self.items = Array(repeating: repeatedValue, count: count)
        self.predicate = predicate
    }

    mutating func reserveCapacity(_ minimumCapacity: Int) {
        items.reserveCapacity(minimumCapacity)
    }

    mutating func add(value: Element) {
        let pos = items.insertionIndexOf(value: value, predicate: predicate)
        if pos == items.count {
            items.append(value)
        }
        else {
            items.insert(value, at: pos)
        }
    }

    func index(after pos: Int) -> Int { return pos + 1 }

    mutating func removeAll() { items.removeAll() }

    mutating func popLast() -> Element? { return items.popLast() }

    mutating func removeLast() -> Element { return items.removeLast() }

    subscript(index: Int) -> Element { return items[index] }
}
