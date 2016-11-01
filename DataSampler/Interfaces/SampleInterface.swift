//
//  Sample.swift
//  DataSampler
//
//  Created by Brad Howes on 10/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/** 
 Interface for an object that represents a data sample
 */
public protocol SampleInterface: Comparable, CustomStringConvertible {

    /// A unique identifier for this sample (e.g. counter)
    var identifier: Int { get }

    /// Sample value
    var latency: Double { get }

    /// The time when the event took place
    var emissionTime: Date { get }

    /// The time when the device/app received the event
    var arrivalTime: Date { get }

    /// The median latency value (arrivalTime - emissionTime)
    var medianLatency: Double { get }

    /// The average latency value
    var averageLatency: Double { get }

    /// The number of samples before this one that were missing
    var missingCount: Int { get }

    /// String description for the sample
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
public func - <T: SampleInterface>(lhs: T, rhs: T) -> TimeInterval {
    return lhs.arrivalTime.timeIntervalSince(rhs.arrivalTime)
}

