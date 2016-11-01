//
//  BRHCollectionLowerBound.swift
//  DataSampler
//
//  Created by Brad Howes on 9/18/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Add insertionIndexOf method to Collection protocol.
 */
extension Collection {

    typealias OrderPredicate = (Iterator.Element, Iterator.Element) -> Bool
    
    /**
     Locate the proper location to insert a given value into an ordered collection.
     - parameter value: the value to insert
     - parameter predicate: a closure that determines whether one element comes before or after another
     - returns: index value which falls in range [0,N] where N is the number of elements in the container. If N is
     returned, the given value is ordered after all others in the container
     */
    func insertionIndexOf(value: Iterator.Element, predicate: OrderPredicate) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            if predicate(self[mid], value) {
                low = index(mid, offsetBy: 1)
            }
            else {
                high = mid
            }
        }
        return low
    }
}

/**
 Add binarySearchFor method to Collection protocol
 */
extension Collection where Iterator.Element: Equatable {
    
    /**
     Quickly search for a given value in an ordered collection.
     - parameter value: the value to locate
     - parameter predicate: a closure that determines whether one element comes before/after another
     - returns: true if the given value was found, false otherwise
     */
    func binarySearchFor(value: Iterator.Element, predicate: OrderPredicate) -> Bool {
        let pos = insertionIndexOf(value: value, predicate: predicate)
        return pos < endIndex && self[pos] == value
    }
}

/** 
 Add a minMax method to collections with comparable elements. Returns both min and max values found in the collection.
 */
extension Collection where Iterator.Element: Comparable {

    /**
     Locate min and max values within a collection.
     - returns: 2-tuple containint the found values, or nil for an empty container
     */
    func minMax() -> (min: Iterator.Element, max: Iterator.Element)? {
        guard let value = self.first else { return nil }
        var min = value
        var max = value
        var pos = self.index(after: startIndex)
        while pos < self.endIndex {
            let value = self[pos]
            if value < min { min = value }
            if value > max { max = value }
            pos = self.index(after: pos)
        }
        return (min, max)
    }
}
