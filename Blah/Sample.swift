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
    func decodeObject(forTag: Tag) -> Any? { return decodeObject(forKey: forTag.rawValue) }
    func decodeInteger(forTag: Tag) -> Int { return decodeInteger(forKey: forTag.rawValue) }
    func decodeDouble(forTag: Tag) -> Double { return decodeDouble(forKey: forTag.rawValue) }
}

protocol SampleInterface: Comparable, CustomStringConvertible {
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
func ==<T: SampleInterface>(x: T, y: T) -> Bool { return x.identifier == y.identifier }

/**
 Enable Comparable protocol for SampleInterface objects, ordering by increasing latency value
 */
func < <T: SampleInterface>(x: T, y: T) -> Bool { return x.latency < y.latency }

/**
 Determine difference between two SampleInterface arrival times. If LHS < RHS the result will be negative.
 */
func - <T: SampleInterface>(lhs: T, rhs: T) -> TimeInterval {
    return lhs.arrivalTime.timeIntervalSince(rhs.arrivalTime)
}

final class Sample: NSObject, NSCoding, SampleInterface {

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
        encoder.encode(self.identifier, forKey: Tag.identifier.rawValue)
        encoder.encode(self.latency, forKey: Tag.latency.rawValue)
        encoder.encode(self.emissionTime, forKey: Tag.emissionTime.rawValue)
        encoder.encode(self.arrivalTime, forKey: Tag.arrivalTime.rawValue)
        encoder.encode(self.medianLatency, forKey: Tag.medianLatency.rawValue)
        encoder.encode(self.averageLatency, forKey: Tag.averageLatency.rawValue)
        encoder.encode(self.missingCount, forKey: Tag.missingCount.rawValue)
    }

    override var description: String { return ("\(self.identifier), \(self.latency)") }
}
