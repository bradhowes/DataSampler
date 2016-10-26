//
//  RunDataInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/25/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Interface for recorded run data.
 */
public protocol RunDataInterface {

    typealias FactoryType = (UserSettingsInterface) -> RunDataInterface

    /**
     Factory method which will create a new RunDataInterface instance
     - parameter userSettings: the UserSettings collection to use for configuration settings
     - returns: new RunData instance
     */
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
