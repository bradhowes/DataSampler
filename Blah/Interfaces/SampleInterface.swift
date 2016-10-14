//
//  Sample.swift
//  Blah
//
//  Created by Brad Howes on 10/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

public protocol SampleInterface: Comparable, CustomStringConvertible {
    var identifier: Int { get }
    var latency: Double { get }
    var emissionTime: Date { get }
    var arrivalTime: Date { get }
    var medianLatency: Double { get }
    var averageLatency: Double { get }
    var missingCount: Int { get }
    var description: String { get }
}

/**
 Enable Equatable protocol for SampleInterface objects, comparing identifiers which should be unique in a run
 */
public func ==<T: SampleInterface>(x: T, y: T) -> Bool { return x.identifier == y.identifier }

/**
 Enable Comparable protocol for SampleInterface objects, ordering by increasing latency value
 */
public func < <T: SampleInterface>(x: T, y: T) -> Bool { return x.latency < y.latency }

/**
 Determine difference between two SampleInterface arrival times. If LHS < RHS the result will be negative.
 */
func - <T: SampleInterface>(lhs: T, rhs: T) -> TimeInterval {
    return lhs.arrivalTime.timeIntervalSince(rhs.arrivalTime)
}

