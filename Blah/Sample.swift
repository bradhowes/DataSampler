//
//  Sample.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Tags used for NSCoding operations
 */
private enum Tag: String {
    case identifier, latency, emissionTime, arrivalTime, medianLatency, averageLatency, missingCount
}

/**
 Extension of NSCoder to support above Tags enumeration
 */
private extension NSCoder {
    func encode<T>(_ value: T, forTag: Tag) { encode(value, forKey: forTag.rawValue) }
    func decodeObject(forTag: Tag) -> Any? { return decodeObject(forKey: forTag.rawValue) }
    func decodeInteger(forTag: Tag) -> Int { return decodeInteger(forKey: forTag.rawValue) }
    func decodeDouble(forTag: Tag) -> Double { return decodeDouble(forKey: forTag.rawValue) }
}

final class Sample: NSObject, NSCoding, Comparable {

    let identifier: Int
    let latency: Double
    let emissionTime: Date
    let arrivalTime: Date
    var medianLatency: Double
    var averageLatency: Double
    var missingCount: Int

    init(identifier: Int, latency: Double, emissionTime: Date, arrivalTime: Date, medianLatency: Double,
         averageLatency: Double) {
        self.identifier = identifier
        self.latency = latency
        self.emissionTime = emissionTime
        self.arrivalTime = arrivalTime
        self.medianLatency = medianLatency
        self.averageLatency = averageLatency
        self.missingCount = 0
        super.init()
    }

    required init?(coder decoder: NSCoder) {
        self.identifier = decoder.decodeInteger(forTag: .identifier)
        self.latency = decoder.decodeDouble(forTag: .latency)
        self.emissionTime = decoder.decodeObject(forTag: .emissionTime) as! Date
        self.arrivalTime = decoder.decodeObject(forTag: .arrivalTime) as! Date
        self.medianLatency = decoder.decodeDouble(forTag: .medianLatency)
        self.averageLatency = decoder.decodeDouble(forTag: .averageLatency)
        self.missingCount = decoder.decodeInteger(forTag: .missingCount)
        super.init()
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(self.identifier, forTag: .identifier)
        encoder.encode(self.latency, forTag: .latency)
        encoder.encode(self.emissionTime, forTag: .emissionTime)
        encoder.encode(self.arrivalTime, forTag: .arrivalTime)
        encoder.encode(self.medianLatency, forTag: .medianLatency)
        encoder.encode(self.averageLatency, forTag: .averageLatency)
        encoder.encode(self.missingCount, forTag: .missingCount)
    }

    override var description: String {
        get {
            return ("\(self.identifier), \(self.latency)")
        }
    }
}

/**
 Enable Equatable protocol for Sample objects, comparing identifiers which should be unique in a run
 */
func ==(x: Sample, y: Sample) -> Bool { return x.identifier == y.identifier }

/**
 Enable Comparable protocol for Sample objects, ordering by increasing latency value
 */
func <(x: Sample, y: Sample) -> Bool { return x.latency < y.latency }

/**
 Determine difference between two Sample arrival times. If LHS < RHS the result will be negative.
 */
func -(lhs: Sample, rhs: Sample) -> TimeInterval {
    return lhs.arrivalTime.timeIntervalSince(rhs.arrivalTime)
}
