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
private enum Tags: String { case name, startTime, samples, missing, emitInterval }

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
class BRHRunData : NSObject, NSCoding {
    
    static let newSample = Notification.Name(rawValue: "BRHRunData.newSample")

    var name: String
    var startTime: Date

    private(set) var samples: [BRHLatencySample] = []
    private(set) var missing: [BRHLatencySample] = []
    private(set) var orderedSamples = BRHOrderedArray<BRHLatencySample>()
    private(set) var histogram: BRHHistogram
    private(set) var emitInterval: Int
    private(set) var estArrivalInterval: Double

    override init() {
        self.name = "Untitled"
        self.startTime = Date()

        samples = []
        missing = []
        orderedSamples = BRHOrderedArray(predicate: (<))
        histogram = BRHHistogram(size: BRHUserSettings.settings().maxHistogramBin.value)
        emitInterval = 30 // secs
        estArrivalInterval = Double(emitInterval)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(maxHistogramBinChanged),
            name: BRHUserSettings.settings().maxHistogramBin.notificationName, object: nil)

        let rnd = BRHRandomUniform()
        var identifier = 1

        var elapsed = Date()
        startTime = elapsed
        
        // Fill with synthesized data
        //
        for _ in 0..<100 {
            elapsed = elapsed.addingTimeInterval(2.0)
            let emissionTime = elapsed
            let latency = rnd.uniform(lower: 0.5, upper: 10.0)
            elapsed = elapsed.addingTimeInterval(latency)
            let arrivalTime = elapsed
            if rnd.uniform(lower: 0.0, upper: 1.0) > 0.1 {
                let sample = BRHLatencySample(identifier: identifier, latency: latency, emissionTime: emissionTime,
                                              arrivalTime: arrivalTime, medianLatency: 0.0, averageLatency: 0.0)
                self.recordLatency(sample: sample)
            }
            identifier += 1
        }

        // Create timer to continue to add synthesized data
        //
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            elapsed = elapsed.addingTimeInterval(2.0)
            let emissionTime = elapsed
            let latency = rnd.uniform(lower: 0.5, upper: 10.0) *
                (rnd.uniform(lower: 0.0, upper: 1.0) > 0.95 ? rnd.uniform(lower: 2.0, upper: 10.0) : 1.0)
            elapsed = elapsed.addingTimeInterval(latency)
            let arrivalTime = elapsed
            if rnd.uniform(lower: 0.0, upper: 1.0) > 0.1 {
                let sample = BRHLatencySample(identifier: identifier, latency: latency,
                                              emissionTime: emissionTime,
                                              arrivalTime: arrivalTime,
                                              medianLatency: 0.0, averageLatency: 0.0)
                self.recordLatency(sample: sample)
            }
            identifier += 1
        }
    }

    required convenience init?(coder decoder: NSCoder) {
        self.init()
        name = decoder.decodeObject(forTag: .name) as! String
        startTime = decoder.decodeObject(forTag: .startTime) as! Date
        samples = decoder.decodeObject(forTag: .samples) as! [BRHLatencySample]
        missing = decoder.decodeObject(forTag: .missing) as! [BRHLatencySample]
        histogram = BRHHistogram(size: BRHUserSettings.settings().maxHistogramBin.value)
        emitInterval = decoder.decodeInteger(forTag: .emitInterval)
        samples.forEach {
            orderedSamples.add(value: $0)
            histogram.add(value: $0.latency)
        }
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(name, forKey: Tags.name.rawValue)
        encoder.encode(samples, forKey: Tags.samples.rawValue)
        encoder.encode(missing, forKey: Tags.missing.rawValue)
        encoder.encode(emitInterval, forKey: Tags.emitInterval.rawValue)
    }

    func maxHistogramBinChanged(notification: Notification) {
        guard let userInfo = notification.userInfo, let newSizeObj = userInfo["new"] else { return }
        guard let newSize: Int = newSizeObj as? Int else { return }
        histogram.resize(size: newSize)
        histogram.replaceWith(values: samples)
    }

    func minSample() -> BRHLatencySample? { return orderedSamples.first }
    func maxSample() -> BRHLatencySample? { return orderedSamples.last }

    func orderedSampleAt(index: Int) -> BRHLatencySample? {
        return index >= 0 && index < orderedSamples.count ? orderedSamples[index] : nil
    }

    /**
     Add a sample to the collection.
     - parameter sample: the stats to record
     */
    func recordLatency(sample: BRHLatencySample) {
        var missingCount = 0
        if let prev = samples.last {
            missingCount = (sample.identifier - prev.identifier - 1)
            if missingCount > 0 {
                let spacing = (sample - prev) / Double(missingCount)
                var arrivalTime = prev.arrivalTime
                missing.append(BRHLatencySample(identifier: prev.identifier + 1,
                                                latency: 0.0,
                                                emissionTime: arrivalTime,
                                                arrivalTime: arrivalTime,
                                                medianLatency: 0.0,
                                                averageLatency: 0.0))
                for ident in 0..<missingCount {
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(BRHLatencySample(identifier: prev.identifier + 1 + ident,
                                                    latency: 100_000.0,
                                                    emissionTime: arrivalTime,
                                                    arrivalTime: arrivalTime,
                                                    medianLatency: 0.0,
                                                    averageLatency: 0.0))
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(BRHLatencySample(identifier: prev.identifier + 1 + ident,
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

        NotificationCenter.default.post(name: BRHRunData.newSample, object: self,
                                        userInfo: ["sample": sample, "index": samples.count - 1,
                                                   "missing": missingCount])
    }
}
