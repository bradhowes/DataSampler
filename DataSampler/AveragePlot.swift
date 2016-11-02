//
//  AveragePlot.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

class AveragePlot: CPTScatterPlot, LatencyPlotInterface {

    var source: RunDataInterface!

    func configure(owner: LatencyPlotInterface.Owner) {
        plotId = .average
        cachePrecision = .double

        dataSource = owner

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 3.0
        lineStyle.lineColor = CPTColor.yellow()

        dataLineStyle = lineStyle
    }

    func yValueOfRecord(record: Int) -> Any {
        return source.samples[record].averageLatency
    }

    func insertRecord() {
        insertData(at: UInt(source.samples.count - 1), numberOfRecords: 1)
    }
}
