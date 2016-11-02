//
//  MissingPlot.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

class MissingPlot: CPTScatterPlot, LatencyPlotInterface {

    var source: RunDataInterface!

    func configure(owner: LatencyPlotInterface.Owner) {
        plotId = .missing
        cachePrecision = .double

        dataSource = owner

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 1.0
        lineStyle.lineColor = CPTColor.red()

        dataLineStyle = lineStyle
        areaBaseValue = 0.0
        areaFill = CPTFill(color: CPTColor.red().withAlphaComponent(0.25))
    }

    func numberOfRecords() -> Int {
        return source.missing.count
    }

    func xValueOfRecord(record: Int) -> Double {
        return source.missing[record].arrivalTime.timeIntervalSince(source.startTime)
    }

    func yValueOfRecord(record: Int) -> Any {
        return source.missing[record].latency
    }

    func insertRecord() {
        let numRecords = source.samples.last!.missingCount * 2 + 1
        if numRecords > 2 {
            insertData(at: UInt(source.missing.count - numRecords), numberOfRecords: UInt(numRecords))
        }
    }
}
