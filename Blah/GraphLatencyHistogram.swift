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
import PDFGenerator

final class GraphLatencyHistogram : CPTGraphHostingView, HistogramObserver {

    var source: Histogram! {
        willSet {
            if source != nil {
                source.observer = nil
            }
        }
        didSet {
            source.observer = self
            if hostedGraph == nil {
                makeGraph()
            }
            else {
                reload()
            }
        }
    }

    private var binCount: Int { return source.bins.count }
    private var maxValue: Int { return source.bins[source.maxBinIndex] }

    fileprivate lazy var labelStyle: CPTMutableTextStyle = {
        let labelStyle = CPTMutableTextStyle()
        labelStyle.color = CPTColor(componentRed: 0.0, green: 1.0, blue: 1.0, alpha: 0.75)
        labelStyle.fontSize = 12.0
        return labelStyle
    }()

    fileprivate var annotation: CPTPlotSpaceAnnotation? = nil
    fileprivate var annotationIndex: Int = 0

    fileprivate lazy var annotationStyle: CPTMutableTextStyle = {
        let annotationStyle = CPTMutableTextStyle()
        annotationStyle.color = self.labelStyle.color
        annotationStyle.fontSize = 12.0
        return annotationStyle
    }()

    fileprivate lazy var titleStyle: CPTMutableTextStyle = {
        let titleStyle = CPTMutableTextStyle()
        titleStyle.color = CPTColor(genericGray: 0.75)
        titleStyle.fontSize = 11.0
        return titleStyle
    }()
    
    func histogramBinChanged(_ histogram: Histogram, index: Int) {
        hostedGraph?.allPlots().last!.reloadData(inIndexRange: NSMakeRange(index, 1))
        if Thread.isMainThread {
            self.updateBounds()
        }
        else {
            DispatchQueue.main.async(execute: self.updateBounds)
        }
    }

    private func makeGraph() {
        let graph = CPTXYGraph(frame: self.frame)
        hostedGraph = graph

        graph.paddingTop = 0.0
        graph.paddingLeft = 0.0
        graph.paddingBottom = 0.0
        graph.paddingRight = 0.0

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

        UserSettingsChangedNotification.observe(observer: self, selector: #selector(checkMaxBinSetting),
                                                setting: UserSettingName.maxHistogramBin)
    }

    func checkMaxBinSetting(notification: Notification) {
        let notif = UserSettingsChangedNotificationWith<Int>(notification: notification)
        if notif.name == UserSettingName.maxHistogramBin {
            if self.hostedGraph != nil {
                reload()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBounds()
    }

    func reload() {
        if Thread.isMainThread {
            self.hostedGraph?.reloadData()
            let axisSet = self.hostedGraph?.axisSet as? CPTXYAxisSet
            if let x = axisSet?.xAxis {
                x.labelingPolicy = .locationsProvided
                x.majorTickLocations = Set<NSNumber>([0, binCount / 2, binCount - 1].map { NSNumber(integerLiteral: $0) })
            }
            self.updateBounds()
            self.setNeedsDisplay()
        }
        else {
            DispatchQueue.main.async(execute: self.reload)
        }
    }

    fileprivate func updateBounds() {
        guard let hostedGraph = self.hostedGraph else { return }
        guard let plotSpace = hostedGraph.allPlotSpaces().last as? CPTXYPlotSpace else { return }

        plotSpace.xRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))

        let maxY = ((max(maxValue, 10) + 9) / 10) * 10
        plotSpace.yRange = CPTPlotRange(location: 0.0, length: NSNumber(integerLiteral: maxY))

        guard let axisSet = hostedGraph.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }
        x.labelFormatter = HistogramBinFormatter(lastBin: binCount - 1)
        x.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        x.gridLinesRange = CPTPlotRange(location: -1.0, length: NSNumber(integerLiteral: maxY))

        guard let y = axisSet.yAxis else { return }
        y.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: maxY + 1))
        y.gridLinesRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        
        y.labelingPolicy = .locationsProvided
        y.majorTickLocations = Set<NSNumber>([0, maxY / 2, maxY].map { NSNumber(integerLiteral: $0) })
    }

    func renderPDF(_ context: CGContext) {
        let graph = self.hostedGraph!
        var mediaBox = CGRect(x:0, y:0, width:graph.bounds.size.width, height:graph.bounds.size.height)
        context.beginPage(mediaBox: &mediaBox);
        graph.layoutAndRender(in: context);
        context.endPage();
    }
}

extension GraphLatencyHistogram: CPTBarPlotDataSource {

    // - Data Source Methods
    //
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(source.bins.count)
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        guard let field = CPTBarPlotField(rawValue: Int(fieldEnum)) else { return nil }
        switch field {
        case .barLocation: return idx as AnyObject?
        case .barTip: return source.bins[Int(idx)]
        default: return nil
        }
    }
}

extension GraphLatencyHistogram: CPTBarPlotDelegate {

    func barPlot(_ plot: CPTBarPlot, barWasSelectedAtRecord idx: UInt) {
        if let annotation = self.annotation {
            hostedGraph?.plotAreaFrame?.plotArea?.removeAnnotation(annotation)
            self.annotation = nil
            if self.annotationIndex == Int(idx) {
                return
            }
        }

        self.annotationIndex = Int(idx)

        let x = Int(idx)
        let y = source.bins[x]

        let tag = "\(y)"
        let textLayer = CPTTextLayer(text: tag, style: annotationStyle)
        textLayer.fill = CPTFill(color: CPTColor.black().withAlphaComponent(0.3))
        let pos = [NSNumber(value: x), NSNumber(value: y)]
        let plotSpace = hostedGraph!.allPlotSpaces().last as! CPTXYPlotSpace
        self.annotation = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: pos)
        self.annotation?.contentLayer = textLayer

        self.annotation?.displacement = CGPoint(x: 0.0, y: textLayer.frame.height / 2.0)
        hostedGraph?.plotAreaFrame?.plotArea?.addAnnotation(self.annotation)
    }
}

extension GraphLatencyHistogram: PDFRenderable {

    var pdfContent: PDFPage {
        get {
            let graph = self.hostedGraph! as! CPTXYGraph
            let data = graph.dataForPDFRepresentationOfLayer()
            return PDFPage.binary(data)
        }
    }
}

