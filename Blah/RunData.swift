//
//  BRHRunData.swift
//  Blah
//
//  Created by Brad Howes on 9/18/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Tags used for NSCoding operations
 */
private enum Tag: String { case name, startTime, samples, missing, emitInterval, estArrivalInterval, binsCount }

/**
 Extension of NSCoder to support above Tags enumeration
 */
private extension NSCoder {
    func encode<T>(_ value: T, forTag: Tag) { encode(value, forKey: forTag.rawValue) }

    func decodeObject(forTag: Tag) -> Any? { return decodeObject(forKey: forTag.rawValue) }
    func decodeInteger(forTag: Tag) -> Int { return decodeInteger(forKey: forTag.rawValue) }
    func decodeDouble(forTag: Tag) -> Double { return decodeDouble(forKey: forTag.rawValue) }

    func containsValue(forTag: Tag) -> Bool { return containsValue(forKey: forTag.rawValue) }
}

/**
 Container for runtime data collected during a run.
 */
final class RunData : NSObject, NSCoding {

    var name: String
    var startTime: Date

    private(set) var samples: [Sample] = []
    private(set) var missing: [Sample] = []
    private(set) var orderedSamples = OrderedArray<Sample>()
    private(set) var histogram: Histogram
    private(set) var emitInterval: Int
    private(set) var estArrivalInterval: Double

    override init() {
        self.name = "Untitled"
        self.startTime = Date()

        samples = []
        missing = []
        orderedSamples = OrderedArray(predicate: (<))
        histogram = Histogram(size: UserSettings.maxHistogramBin)
        emitInterval = UserSettings.emitInterval
        estArrivalInterval = Double(emitInterval)

        super.init()
    }

    required convenience init?(coder decoder: NSCoder) {
        self.init()

        samples = decoder.decodeObject(forTag: .samples) as! [Sample]
        missing = decoder.decodeObject(forTag: .missing) as! [Sample]
        emitInterval = decoder.decodeInteger(forTag: .emitInterval)
        if decoder.containsValue(forTag: .estArrivalInterval) {
            estArrivalInterval = decoder.decodeDouble(forTag: .estArrivalInterval)
        }
        else {
            estArrivalInterval = Double(emitInterval)
        }

        histogram = Histogram(size: decoder.decodeInteger(forTag: .binsCount))

        samples.forEach {
            orderedSamples.add(value: $0)
            histogram.add(value: $0.latency)
        }
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(samples, forTag: .samples)
        encoder.encode(missing, forTag: .missing)
        encoder.encode(emitInterval, forTag: .emitInterval)
        encoder.encode(estArrivalInterval, forTag: .estArrivalInterval)
        encoder.encode(histogram.bins.count, forTag: .binsCount)
    }

    func begin(startTime: Date) {
        self.startTime = startTime
        name = startTime.description
    }

    func minSample() -> Sample? { return orderedSamples.first }
    func maxSample() -> Sample? { return orderedSamples.last }

    func orderedSampleAt(index: Int) -> Sample? {
        return index >= 0 && index < orderedSamples.count ? orderedSamples[index] : nil
    }

    /**
     Add a sample to the collection.
     - parameter sample: the stats to record
     */
    func recordLatency(sample: Sample) {
        EventLog.log("sample", sample.identifier, sample.emissionTime.description, sample.arrivalTime.description)
        var missingCount = 0
        if let prev = samples.last {
            missingCount = (sample.identifier - prev.identifier - 1)
            if missingCount > 0 {
                EventLog.log("missing", missingCount)
                sample.missingCount = missingCount
                let spacing = (sample - prev) / Double(missingCount)
                var arrivalTime = prev.arrivalTime
                missing.append(Sample(identifier: prev.identifier + 1, latency: 0.0, emissionTime: arrivalTime,
                                      arrivalTime: arrivalTime, medianLatency: 0.0, averageLatency: 0.0))
                for ident in 0..<missingCount {
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(Sample(identifier: prev.identifier + 1 + ident, latency: 100_000.0,
                                          emissionTime: arrivalTime, arrivalTime: arrivalTime, medianLatency: 0.0,
                                          averageLatency: 0.0))
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(Sample(identifier: prev.identifier + 1 + ident, latency: 0.0,
                                          emissionTime: arrivalTime, arrivalTime: arrivalTime, medianLatency: 0.0,
                                          averageLatency: 0.0))
                }
            }

            let denom = Double(samples.count)
            if samples.count == 1 {
                estArrivalInterval = sample - prev
            }
            else {
                estArrivalInterval = min(estArrivalInterval, ((sample - prev) + estArrivalInterval * (denom - 1.0)) / denom)
            }

            sample.averageLatency = (sample.latency + prev.averageLatency * denom) / (denom + 1.0)
            EventLog.log("averageLatency", sample.averageLatency)
        }

        orderedSamples.add(value: sample)
        samples.append(sample)
        histogram.add(value: sample.latency)

        let middle = samples.count / 2
        var medianLatency = orderedSamples[middle].latency
        if samples.count % 2 == 0 {
            medianLatency = (medianLatency + orderedSamples[middle - 1].latency) / 2.0
        }

        EventLog.log("medianLatency", medianLatency)
        sample.medianLatency = medianLatency

        RunDataNewSampleNotification.post(sender: self, sample: sample, index: samples.count - 1)
    }
}
