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

    /// Provides the text to show in the legend for a plot
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

/** 
 Interface for an XY scatter plot in the latency graph.
 */
protocol LatencyPlotInterface: class {

    /// Convenience type definition for a plot delegate / data source
    typealias Owner = (CPTScatterPlotDelegate & CPTScatterPlotDataSource)

    /// Holds the current source of plot data
    var source: RunDataInterface! { get set }

    /**
     Configure the plot. Installs an owner.
     - parameter owner: the owner of the plot
     */
    func configure(owner: Owner)

    /**
     Obtain the number of data samples to plot.
     - returns: sample count
     */
    func numberOfRecords() -> Int

    /**
     Obtain the X axis value of a sample.
     - parameter record: the index of the sample to work with
     - returns: the X value
     */
    func xValueOfRecord(record: Int) -> Double

    /**
     Obtain the Y axis value of a sample.
     - parameter record: the index of the sample to work with
     - returns: the Y value
     */
    func yValueOfRecord(record: Int) -> Any

    /**
     Create a new record for a new samle that is in the `source` property
     */
    func insertRecord()
}

/** 
 Extension with common XY plot methods.
 */
extension LatencyPlotInterface {
    func numberOfRecords() -> Int {
        return source.samples.count
    }

    func xValueOfRecord(record: Int) -> Double {
        return source.samples[record].arrivalTime.timeIntervalSince(source.startTime)
    }
}
