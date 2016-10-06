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
private enum Tags: String { case name, startTime, samples, missing, emitInterval, binsCount }

/**
 Extension of NSCoder to support above Tags enumeration
 */
private extension NSCoder {
    func decodeObject(forTag: Tags) -> Any? { return decodeObject(forKey: forTag.rawValue) }
    func decodeInteger(forTag: Tags) -> Int { return decodeInteger(forKey: forTag.rawValue) }
}

/**
 Container for runtime data collected during a run.
 */
class RunData : NSObject, NSCoding {
    
    static let newSample = Notification.Name(rawValue: "RunData.newSample")
    static let replacedData = Notification.Name(rawValue: "RunData.replacedData")

    var name: String
    var startTime: Date

    private(set) var samples: [LatencySample] = []
    private(set) var missing: [LatencySample] = []
    private(set) var orderedSamples = OrderedArray<LatencySample>()
    private(set) var histogram: Histogram
    private(set) var emitInterval: Int
    private(set) var estArrivalInterval: Double

    override init() {
        self.name = "Untitled"
        self.startTime = Date()

        samples = []
        missing = []
        orderedSamples = OrderedArray(predicate: (<))
        histogram = Histogram(size: UserSettings.singleton.maxHistogramBin.value)
        emitInterval = 30 // secs
        estArrivalInterval = Double(emitInterval)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(maxHistogramBinChanged),
            name: UserSettings.singleton.maxHistogramBin.notificationName, object: nil)
    }

    required convenience init?(coder decoder: NSCoder) {
        self.init()

        samples = decoder.decodeObject(forTag: .samples) as! [LatencySample]
        missing = decoder.decodeObject(forTag: .missing) as! [LatencySample]
        emitInterval = decoder.decodeInteger(forTag: .emitInterval)
        histogram = Histogram(size: decoder.decodeInteger(forTag: .binsCount))

        samples.forEach {
            orderedSamples.add(value: $0)
            histogram.add(value: $0.latency)
        }
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(samples, forKey: Tags.samples.rawValue)
        encoder.encode(missing, forKey: Tags.missing.rawValue)
        encoder.encode(emitInterval, forKey: Tags.emitInterval.rawValue)
        encoder.encode(histogram.bins.count, forKey: Tags.binsCount.rawValue)
    }

    func begin(startTime: Date) {
        self.startTime = startTime
        name = startTime.description
        samples = []
        missing = []
        histogram.clear()
        orderedSamples.removeAll()
    }

    func replace(with rhs: RunData) {
        startTime = rhs.startTime
        name = rhs.name
        samples = rhs.samples
        missing = rhs.missing
        orderedSamples = rhs.orderedSamples
        emitInterval = rhs.emitInterval
        estArrivalInterval = rhs.estArrivalInterval
        histogram.replace(with: rhs.histogram)

        NotificationCenter.default.post(name: RunData.replacedData, object: self, userInfo: nil)
    }

    func maxHistogramBinChanged(notification: Notification) {
        guard let userInfo = notification.userInfo, let newSizeObj = userInfo["new"] else { return }
        guard let newSize: Int = newSizeObj as? Int else { return }
        histogram.resize(size: newSize)
        histogram.replace(values: samples)
    }

    func minSample() -> LatencySample? { return orderedSamples.first }
    func maxSample() -> LatencySample? { return orderedSamples.last }

    func orderedSampleAt(index: Int) -> LatencySample? {
        return index >= 0 && index < orderedSamples.count ? orderedSamples[index] : nil
    }

    /**
     Add a sample to the collection.
     - parameter sample: the stats to record
     */
    func recordLatency(sample: LatencySample) {
        var missingCount = 0
        if let prev = samples.last {
            missingCount = (sample.identifier - prev.identifier - 1)
            if missingCount > 0 {
                let spacing = (sample - prev) / Double(missingCount)
                var arrivalTime = prev.arrivalTime
                missing.append(LatencySample(identifier: prev.identifier + 1,
                                                latency: 0.0,
                                                emissionTime: arrivalTime,
                                                arrivalTime: arrivalTime,
                                                medianLatency: 0.0,
                                                averageLatency: 0.0))
                for ident in 0..<missingCount {
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(LatencySample(identifier: prev.identifier + 1 + ident,
                                                    latency: 100_000.0,
                                                    emissionTime: arrivalTime,
                                                    arrivalTime: arrivalTime,
                                                    medianLatency: 0.0,
                                                    averageLatency: 0.0))
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(LatencySample(identifier: prev.identifier + 1 + ident,
                                                    latency: 0.0,
                                                    emissionTime: arrivalTime,
                                                    arrivalTime: arrivalTime,
                                                    medianLatency: 0.0,
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
        }

        orderedSamples.add(value: sample)
        samples.append(sample)
        histogram.add(value: sample.latency)

        let middle = samples.count / 2
        var medianLatency = orderedSamples[middle].latency
        if samples.count % 2 == 0 {
            medianLatency = (medianLatency + orderedSamples[middle - 1].latency) / 2.0
        }

        sample.medianLatency = medianLatency

        NotificationCenter.default.post(name: RunData.newSample, object: self,
                                        userInfo: ["sample": sample, "index": samples.count - 1,
                                                   "missing": missingCount])
    }
}
