//
//  LatencyPlotInterface.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

/**
 Enumeration of the plots in the latency graph
 */
enum LatencyPlotId: String {
    case latency, average, median, missing

    var legend: String {
        get {
            switch self {
            case .latency: return "Latency"
            case .average: return "Avg"
            case .median: return "Median"
            case .missing: return "Miss"
            }
        }
    }
}

protocol LatencyPlotInterface: class {

    typealias Owner = (CPTScatterPlotDelegate & CPTScatterPlotDataSource)

    var source: RunDataInterface! { get set }

    func configure(owner: Owner)
    func numberOfRecords() -> Int
    func xValueOfRecord(record: Int) -> Double
    func yValueOfRecord(record: Int) -> Any
    func insertRecord()
}

extension LatencyPlotInterface {
    func numberOfRecords() -> Int {
        return source.samples.count
    }

    func xValueOfRecord(record: Int) -> Double {
        return source.samples[record].arrivalTime.timeIntervalSince(source.startTime)
    }
}
