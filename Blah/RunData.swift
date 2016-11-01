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

/**
 Container for runtime data collected during a run.
 */
public final class RunData : NSObject, NSCoding, RunDataInterface {

    public var name: String
    public var startTime: Date

    public private(set) var samples: [Sample] = []
    public private(set) var missing: [Sample] = []
    public private(set) var orderedSamples = OrderedArray<Sample>()
    public private(set) var histogram: Histogram
    public private(set) var emitInterval: Int
    public private(set) var estArrivalInterval: Double

    public var minSample: Sample? { return orderedSamples.first }
    public var maxSample: Sample? { return orderedSamples.last }

    /**
     Factory method to create a new RunData instance
     - parameter userSettings: the UserSettings collection to use for configuration settings
     - returns: new RunData instance
     */
    public static func MakeRunData(userSettings: UserSettingsInterface) -> RunDataInterface {
        return RunData(userSettings: userSettings)
    }

    public func updateHistogramBinCount(notification: Notification) {
        let notif = UserSettingsChangedNotificationWith<Int>(notification: notification)
        if notif.name == UserSettingName.maxHistogramBin {
            histogram.resize(size: notif.newValue + 1)
        }
    }

    /**
     Default construction. Create an empty container.
     */
    public override init() {
        self.name = "Untitled"
        self.startTime = Date()

        samples = []
        missing = []
        orderedSamples = OrderedArray(predicate: (<))
        histogram = Histogram(size: 1)
        self.emitInterval = 0
        estArrivalInterval = Double(emitInterval)

        super.init()

        UserSettingsChangedNotification.observe(observer: self, selector: #selector(updateHistogramBinCount),
                                                setting: UserSettingName.maxHistogramBin)
   }

    /**
     Construction using configuration settings.
     - parameter userSettings: the user settings to use
     */
    public convenience init(userSettings: UserSettingsInterface) {
        self.init()
        histogram = Histogram(size: userSettings.maxHistogramBin + 1)
        self.emitInterval = userSettings.emitInterval
        estArrivalInterval = Double(emitInterval)
    }

    /**
     Reconstitute a previous instance from data in an NSCoder object
     - parameter decoder: the NSCoder object to use for data
     */
    public required convenience init?(coder decoder: NSCoder) {
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

    /**
     Encode the current state in an NSCoder object.
     - parameter encoder: the NSCoder object to write to
     */
    public func encode(with encoder: NSCoder) {
        encoder.encode(samples, forKey: Tag.samples.rawValue)
        encoder.encode(missing, forKey: Tag.missing.rawValue)
        encoder.encode(emitInterval, forKey: Tag.emitInterval.rawValue)
        encoder.encode(estArrivalInterval, forKey: Tag.estArrivalInterval.rawValue)
        encoder.encode(histogram.bins.count, forKey: Tag.binsCount.rawValue)
    }

    /**
     Obtain the ordered sample at a given index
     - parameter index: where to fetch from
     - returns: the sample found at the position. May be nil
     */
    public func orderedSampleAt(index: Int) -> Sample? {
        return index >= 0 && index < orderedSamples.count ? orderedSamples[index] : nil
    }

    /**
     Add a sample to the collection.
     - parameter sample: the stats to record
     */
    public func recordLatency(sample: Sample) {
        EventLog.log("sample", sample.identifier, sample.emissionTime.description, sample.arrivalTime.description)
        var missingCount = 0
        if let prev = samples.last {
            missingCount = (sample.identifier - prev.identifier - 1)
            if missingCount > 0 {
                EventLog.log("missing", missingCount)
                sample.missingCount = missingCount
                let spacing = (sample - prev) / Double(missingCount)
                var arrivalTime = prev.arrivalTime
                missing.append(Sample(identifier: prev.identifier + 1, latency: -1.0, emissionTime: arrivalTime,
                                      arrivalTime: arrivalTime, medianLatency: 0.0, averageLatency: 0.0))
                for ident in 0..<missingCount {
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(Sample(identifier: prev.identifier + 1 + ident, latency: 100_000.0,
                                          emissionTime: arrivalTime, arrivalTime: arrivalTime, medianLatency: 0.0,
                                          averageLatency: 0.0))
                    arrivalTime = arrivalTime.addingTimeInterval(spacing / 2.0)
                    missing.append(Sample(identifier: prev.identifier + 1 + ident, latency: -1.0,
                                          emissionTime: arrivalTime, arrivalTime: arrivalTime, medianLatency: 0.0,
                                          averageLatency: 0.0))
                }
            }

            let denom = Double(samples.count)
            estArrivalInterval = min(estArrivalInterval, sample - prev)
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
