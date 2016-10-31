//
//  BRHOrderedArray.swift
//  Blah
//
//  Created by Brad Howes on 9/18/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 An Array that maintains ordering of items.
 */
public struct OrderedArray<Element:Comparable> : Collection, CustomDebugStringConvertible {

    public typealias Predicate = (Element, Element) -> Bool

    private(set) var items: [Element]
    private let predicate: Predicate

    public var startIndex: Int { get { return 0 } }
    public var endIndex: Int { get { return items.count } }
    public var count: Int { get { return items.count } }

    public var last: Element { get { return items[endIndex - 1] } }

    public var debugDescription: String { get { return "OrderedArray: \(items)" } }
    public var description: String { get { return "OrderedArray: \(items)" } }

    public init(predicate: @escaping Predicate = (<)) {
        self.items = []
        self.predicate = predicate
    }

    public init(items: [Element], predicate: @escaping Predicate = (<)) {
        self.items = items
        self.predicate = predicate
        self.items.sort(by: predicate)
    }

    public init(count: Int, repeatedValue: Element, predicate: @escaping Predicate = (<)) {
        self.items = Array(repeating: repeatedValue, count: count)
        self.predicate = predicate
    }

    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        items.reserveCapacity(minimumCapacity)
    }

    public mutating func add(value: Element) {
        let pos = items.insertionIndexOf(value: value, predicate: predicate)
        if pos == items.count {
            items.append(value)
        }
        else {
            items.insert(value, at: pos)
        }
    }

    public func index(after pos: Int) -> Int { return pos + 1 }

    public subscript(index: Int) -> Element { return items[index] }

    public mutating func removeAll() { items.removeAll() }

    public mutating func popLast() -> Element? { return items.popLast() }

    public mutating func removeLast() -> Element { return items.removeLast() }

}
