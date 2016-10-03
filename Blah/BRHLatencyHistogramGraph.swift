//
//  BRHLatencyHistogramGraph.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit
import CorePlot

class BRHLatencyHistogramGraph : CPTGraphHostingView, CPTPlotDataSource, CPTBarPlotDelegate, CPTAxisDelegate {

    var source: BRHLatencyHistogramGraphSource! {
        didSet {
            if hostedGraph == nil {
                makeGraph()
            }
            else {
                updateBounds()
                redraw()
            }
        }
    }

    func sourceChanged(notification: Notification) {
        guard let userInfo = notification.userInfo, let binIndexObj = userInfo["binIndex"] else { return }
        if let binIndex = binIndexObj as? Int {
            hostedGraph?.allPlots().last!.reloadData(inIndexRange: NSMakeRange(binIndex, 1))
        }
        else {
            hostedGraph?.reloadData()
            let axisSet = hostedGraph?.axisSet as? CPTXYAxisSet
            if let x = axisSet?.xAxis {
                let binCount = Int(source.numberOfRecords()) - 1
                x.labelingPolicy = .locationsProvided
                x.majorTickLocations = Set<NSNumber>([0, binCount / 2, binCount].map { NSNumber(integerLiteral: $0) })
            }
        }

        updateBounds()
    }

    fileprivate func makeGraph() {

        NotificationCenter.default.addObserver(self, selector: #selector(sourceChanged),
                                               name: BRHHistogram.changedNotification,
                                               object: nil)

        let graph = CPTXYGraph(frame: self.frame)
        hostedGraph = graph
//        graph.applyTheme(CPTTheme(named: kCPTDarkGradientTheme))
        
        graph.paddingTop = 0.0
        graph.paddingLeft = 0.0
        graph.paddingBottom = 0.0
        graph.paddingRight = 0.0
//
        graph.plotAreaFrame?.masksToBorder = false;
        graph.plotAreaFrame?.borderLineStyle = nil
        graph.plotAreaFrame?.cornerRadius = 0.0
        graph.plotAreaFrame?.paddingTop = 10.0
        graph.plotAreaFrame?.paddingLeft = 22.0
        graph.plotAreaFrame?.paddingBottom = 35.0
        graph.plotAreaFrame?.paddingRight = 4.0

        let barPlotSpace = CPTXYPlotSpace()
        graph.add(barPlotSpace)

        let axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = 0.75
        axisLineStyle.lineColor = CPTColor(genericGray: 0.45)

        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineWidth = 0.75
        gridLineStyle.lineColor = CPTColor(genericGray: 0.25)
        
        let tickLineStyle = CPTMutableLineStyle()
        tickLineStyle.lineWidth = 0.75
        tickLineStyle.lineColor = CPTColor(genericGray: 0.25)
        
        let labelStyle = CPTMutableTextStyle()
        labelStyle.color = CPTColor(componentRed: 0.0, green: 1.0, blue: 1.0, alpha: 0.75)
        labelStyle.fontSize = 12.0
        
        let titleStyle = CPTMutableTextStyle()
        titleStyle.color = CPTColor(genericGray: 0.75)
        titleStyle.fontSize = 11.0
        
        guard let axisSet = graph.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }

        // X Axis
        //
        x.titleTextStyle = titleStyle
        x.title = "Histogram (1s bin)"
        x.titleOffset = 18.0

        x.axisLineStyle = nil // axisLineStyle
        x.labelTextStyle = labelStyle
        x.labelOffset = -3.0

        let binCount = Int(source.numberOfRecords())
        x.labelingPolicy = .locationsProvided
        x.majorTickLocations = Set<NSNumber>([0, binCount / 2, binCount - 1].map { NSNumber(integerLiteral: $0) })

        x.majorTickLineStyle = tickLineStyle
        x.majorTickLength = 5.0

        x.minorTickLineStyle = nil
        x.minorTickLength = 0
        x.minorTicksPerInterval = 0

        x.plotSpace = barPlotSpace

        // Y Axis
        //
        guard let y = axisSet.yAxis else { return }

        y.title = nil
        y.axisLineStyle = nil // axisLineStyle
        y.orthogonalPosition = -0.5;
        y.labelRotation = CGFloat(M_PI_2)

        y.labelTextStyle = labelStyle
        y.labelOffset = -3.0

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        y.labelFormatter = formatter
        y.plotSpace = barPlotSpace

        y.majorTickLineStyle = tickLineStyle
        y.preferredNumberOfMajorTicks = 5

        y.minorTickLineStyle = nil

        y.majorGridLineStyle = gridLineStyle
        y.minorTicksPerInterval = 0
        y.minorGridLineStyle = gridLineStyle
        
        graph.axisSet!.axes = [x, y]

        let plot = CPTBarPlot.tubularBarPlot(with: CPTColor.green(), horizontalBars: false)
        //plot.barWidth = 0.5
        
        plot.dataSource = self
        plot.delegate = self
        
        graph.add(plot, to: barPlotSpace)
        updateBounds()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBounds()
    }

    fileprivate func redraw() {
        if let plots = hostedGraph?.allPlots() {
            for each in plots {
                each.setDataNeedsReloading()
            }
        }
    }

    fileprivate func updateBounds() {
        guard let source = self.source else { return }
        guard let hostedGraph = self.hostedGraph else { return }
        guard let plotSpace = hostedGraph.allPlotSpaces().last as? CPTXYPlotSpace else { return }

        let binCount = Int(source.numberOfRecords())
        plotSpace.xRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))

        let maxY = ((max(source.maxValue(), 10) + 9) / 10) * 10
        plotSpace.yRange = CPTPlotRange(location: 0.0, length: NSNumber(integerLiteral: maxY))

        guard let axisSet = hostedGraph.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }
        x.labelFormatter = BRHBinFormatter(lastBin: binCount - 1)
        x.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        x.gridLinesRange = CPTPlotRange(location: -1.0, length: NSNumber(integerLiteral: maxY))

        guard let y = axisSet.yAxis else { return }
        y.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: maxY + 1))
        y.gridLinesRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        
        y.labelingPolicy = .locationsProvided
        y.majorTickLocations = Set<NSNumber>([0, maxY / 2, maxY].map { NSNumber(integerLiteral: $0) })
    }

    func update() {
        hostedGraph?.reloadData()
        updateBounds()
    }
    
    func renderPDF(_ context: CGContext) {
        let graph = self.hostedGraph!
        var mediaBox = CGRect(x:0, y:0, width:graph.bounds.size.width, height:graph.bounds.size.height)
        context.beginPage(mediaBox: &mediaBox);
        graph.layoutAndRender(in: context);
        context.endPage();
    }

    // - Data Source Methods
    //
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return source.numberOfRecords()
    }


    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        guard let field = CPTBarPlotField(rawValue: Int(fieldEnum)) else { return nil }
        switch field {
        case .barLocation: return idx as AnyObject?
        case .barTip: return source.valueForRecord(idx)
        default: return nil
        }
    }
}
