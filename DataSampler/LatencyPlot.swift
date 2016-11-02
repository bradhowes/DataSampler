//
//  LatencyPlot.swift
//  DataSampler
//
//  Created by Brad Howes on 11/2/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CorePlot

class LatencyPlot: CPTScatterPlot, LatencyPlotInterface {

    static let kPlotSymbolSize: Double = 8.0

    var source: RunDataInterface!

    func configure(owner: LatencyPlotInterface.Owner) {
        plotId = .latency
        cachePrecision = .double

        delegate = owner
        dataSource = owner

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 1.0
        lineStyle.lineColor = CPTColor.gray()
        dataLineStyle = lineStyle

        let symbolGradient = CPTGradient(beginning: CPTColor(componentRed: 0.75, green: 0.75, blue: 1.0, alpha: 1.0),
                                         ending: CPTColor.cyan())
        symbolGradient.gradientType = .radial
        symbolGradient.startAnchor = CGPoint(x: 0.25, y: 0.75)

        let plotSymbol = CPTPlotSymbol.ellipse()
        plotSymbol.fill = CPTFill(gradient: symbolGradient)
        plotSymbol.lineStyle = nil;
        plotSymbol.size = CGSize(width: LatencyPlot.kPlotSymbolSize, height: LatencyPlot.kPlotSymbolSize)
        self.plotSymbol = plotSymbol

        plotSymbolMarginForHitDetection = CGFloat(LatencyPlot.kPlotSymbolSize) * CGFloat(1.5)
    }

    func yValueOfRecord(record: Int) -> Any {
        return source.samples[record].latency
    }

    func insertRecord() {
        insertData(at: UInt(source.samples.count - 1), numberOfRecords: 1)
    }
}
