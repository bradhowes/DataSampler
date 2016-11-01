//
//  Sample.swift
//  DataSampler
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

public final class Sample: NSObject, NSCoding, SampleInterface {

    public let identifier: Int
    public let latency: Double
    public let emissionTime: Date
    public let arrivalTime: Date
    public var medianLatency: Double
    public var averageLatency: Double
    public var missingCount: Int

    public init(identifier: Int, latency: Double, emissionTime: Date, arrivalTime: Date, medianLatency: Double,
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

    public required init?(coder decoder: NSCoder) {
        self.identifier = decoder.decodeInteger(forTag: .identifier)
        self.latency = decoder.decodeDouble(forTag: .latency)
        self.emissionTime = decoder.decodeObject(forTag: .emissionTime) as! Date
        self.arrivalTime = decoder.decodeObject(forTag: .arrivalTime) as! Date
        self.medianLatency = decoder.decodeDouble(forTag: .medianLatency)
        self.averageLatency = decoder.decodeDouble(forTag: .averageLatency)
        self.missingCount = decoder.decodeInteger(forTag: .missingCount)
        super.init()
    }

    public func encode(with encoder: NSCoder) {
        encoder.encode(self.identifier, forKey: Tag.identifier.rawValue)
        encoder.encode(self.latency, forKey: Tag.latency.rawValue)
        encoder.encode(self.emissionTime, forKey: Tag.emissionTime.rawValue)
        encoder.encode(self.arrivalTime, forKey: Tag.arrivalTime.rawValue)
        encoder.encode(self.medianLatency, forKey: Tag.medianLatency.rawValue)
        encoder.encode(self.averageLatency, forKey: Tag.averageLatency.rawValue)
        encoder.encode(self.missingCount, forKey: Tag.missingCount.rawValue)
    }

    public override var description: String { return ("\(self.identifier), \(self.latency)") }
}

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
