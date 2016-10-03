//
//  BRHLatencySample.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class BRHLatencySample: NSObject, NSCoding, Comparable {
    
    let kIdentifierKey: String = "identifier"
    let kLatencyKey: String = "latency"
    let kEmissionTime: String = "emissionTime"
    let kArrivalTime: String = "arrivalTime"
    let kMedianLatencyKey: String = "medianLatency"
    let kAverageLatencyKey: String = "averageLatency"

    let identifier: Int
    let latency: Double
    let emissionTime: Date
    let arrivalTime: Date
    var medianLatency: Double
    var averageLatency: Double

    init(identifier: Int, latency: Double, emissionTime: Date, arrivalTime: Date, medianLatency: Double,
         averageLatency: Double) {
        self.identifier = identifier
        self.latency = latency
        self.emissionTime = emissionTime
        self.arrivalTime = arrivalTime
        self.medianLatency = medianLatency
        self.averageLatency = averageLatency
        super.init()
    }

    required init?(coder decoder: NSCoder) {
        self.identifier = decoder.decodeInteger(forKey: kIdentifierKey)
        self.latency = decoder.decodeDouble(forKey: kLatencyKey)
        self.emissionTime = decoder.decodeObject(forKey: kEmissionTime) as! Date
        self.arrivalTime = decoder.decodeObject(forKey: kArrivalTime) as! Date
        self.medianLatency = decoder.decodeDouble(forKey: kMedianLatencyKey)
        self.averageLatency = decoder.decodeDouble(forKey: kAverageLatencyKey)
        super.init()
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(self.identifier, forKey: kIdentifierKey)
        encoder.encode(self.latency, forKey: kLatencyKey)
        encoder.encode(self.emissionTime, forKey: kEmissionTime)
        encoder.encode(self.arrivalTime, forKey: kArrivalTime)
        encoder.encode(self.medianLatency, forKey: kMedianLatencyKey)
        encoder.encode(self.averageLatency, forKey: kAverageLatencyKey)
    }

    override var description: String {
        get {
            return ("\(self.identifier), \(self.latency)")
        }
    }
}

/**
 @brief Support Equatable protocol for BRHLatencySample objects, comparing identifiers
 */
func ==(x: BRHLatencySample, y: BRHLatencySample) -> Bool { return x.identifier == y.identifier }

/**
 @brief Support Comparable protocol for BRHLatencySample objects, ordering by increasing latency value
 */
func <(x: BRHLatencySample, y: BRHLatencySample) -> Bool { return x.latency < y.latency }

/**
 @brief Determine difference between two BRHLatencySample arrival times. If LHS < RHS the result will be negative.
 */
func -(lhs: BRHLatencySample, rhs: BRHLatencySample) -> TimeInterval {
    return lhs.arrivalTime.timeIntervalSince(rhs.arrivalTime)
}
