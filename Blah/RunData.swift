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
    func decodeObject(forTag: Tag) -> Any? { return decodeObject(forKey: forTag.rawValue) }
    func decodeInteger(forTag: Tag) -> Int { return decodeInteger(forKey: forTag.rawValue) }
    func decodeDouble(forTag: Tag) -> Double { return decodeDouble(forKey: forTag.rawValue) }
}

protocol RunDataInterface {

    static func MakeRunData(userSettings: UserSettingsInterface) -> RunDataInterface

    var name: String { get set }
    var startTime: Date { get set }

    var samples: [Sample] { get }
    var missing: [Sample] { get }
    var orderedSamples: OrderedArray<Sample> { get }
    var histogram: Histogram { get }

    var emitInterval: Int { get }
    var estArrivalInterval: Double { get }

    var minSample: Sample? { get }
    var maxSample: Sample? { get }

    func orderedSampleAt(index: Int) -> Sample?
    func recordLatency(sample: Sample)
}

/**
 Container for runtime data collected during a run.
 */
final class RunData : NSObject, NSCoding, RunDataInterface {

    var name: String
    var startTime: Date

    private(set) var samples: [Sample] = []
    private(set) var missing: [Sample] = []
    private(set) var orderedSamples = OrderedArray<Sample>()
    private(set) var histogram: Histogram
    private(set) var emitInterval: Int
    private(set) var estArrivalInterval: Double

    var minSample: Sample? { return orderedSamples.first }
    var maxSample: Sample? { return orderedSamples.last }

    static func MakeRunData(userSettings: UserSettingsInterface) -> RunDataInterface {
        return RunData(userSettings: userSettings)
    }

    override init() {
        self.name = "Untitled"
        self.startTime = Date()

        samples = []
        missing = []
        orderedSamples = OrderedArray(predicate: (<))
        histogram = Histogram(size: 1)
        self.emitInterval = 0
        estArrivalInterval = Double(emitInterval)

        super.init()
    }

    convenience init(userSettings: UserSettingsInterface) {
        self.init()
        histogram = Histogram(size: userSettings.maxHistogramBin + 1)
        self.emitInterval = userSettings.emitInterval
        estArrivalInterval = Double(emitInterval)
    }

    required convenience init?(coder decoder: NSCoder) {
        self.init()
        samples = decoder.decodeObject(forTag: .samples) as! [Sample]
        missing = decoder.decodeObject(forTag: .missing) as! [Sample]
        emitInterval = decoder.decodeInteger(forTag: .emitInterval)
        estArrivalInterval = decoder.decodeDouble(forTag: .estArrivalInterval)
        histogram = Histogram(size: decoder.decodeInteger(forTag: .binsCount))
        samples.forEach {
            orderedSamples.add(value: $0)
            histogram.add(value: $0.latency)
        }
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(samples, forKey: Tag.samples.rawValue)
        encoder.encode(missing, forKey: Tag.missing.rawValue)
        encoder.encode(emitInterval, forKey: Tag.emitInterval.rawValue)
        encoder.encode(estArrivalInterval, forKey: Tag.estArrivalInterval.rawValue)
        encoder.encode(histogram.bins.count, forKey: Tag.binsCount.rawValue)
    }

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
