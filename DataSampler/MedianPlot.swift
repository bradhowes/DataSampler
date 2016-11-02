//
//  MedianPlot.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

class MedianPlot: CPTScatterPlot, LatencyPlotInterface {

    var source: RunDataInterface!

    func configure(owner: LatencyPlotInterface.Owner) {
        plotId = .median
        cachePrecision = .double

        dataSource = owner

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 3.0
        lineStyle.lineColor = CPTColor.magenta()

        dataLineStyle = lineStyle
    }

    func yValueOfRecord(record: Int) -> Any {
        return source.samples[record].medianLatency
    }

    func insertRecord() {
        insertData(at: UInt(source.samples.count - 1), numberOfRecords: 1)
    }
}
