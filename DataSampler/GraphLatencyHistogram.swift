//
//  BRHLatencyHistogramGraph.swift
//  DataSampler
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit
import CorePlot

final class GraphLatencyHistogram : CPTGraphHostingView, HistogramObserver, Skinnable {

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

    let displaySkin = DisplayGraphSkin()
    let pdfSkin = PDFGraphSkin()

    var activeSkin: GraphSkinInterface! {
        didSet {
            applySkin()
        }
    }

    private var maxY: Int {
        return ((max(maxValue, 10) + 9) / 10) * 10
    }

    private lazy var plotSpace: CPTXYPlotSpace = {
        return self.hostedGraph!.allPlotSpaces().last! as! CPTXYPlotSpace
    }()

    fileprivate lazy var xAxis: CPTXYAxis = {
        return (self.hostedGraph!.axisSet! as! CPTXYAxisSet).xAxis!
    }()

    fileprivate lazy var yAxis: CPTXYAxis = {
        return (self.hostedGraph!.axisSet! as! CPTXYAxisSet).yAxis!
    }()
    
    private var binCount: Int { return source.bins.count }
    private var maxValue: Int { return source.bins[source.maxBinIndex] }

    fileprivate var annotation: CPTPlotSpaceAnnotation? = nil
    fileprivate var annotationIndex: Int = 0

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

        xAxis.plotSpace = barPlotSpace
        yAxis.plotSpace = barPlotSpace

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        yAxis.labelFormatter = formatter


        graph.axisSet!.axes = [xAxis, yAxis]

        let plot = CPTBarPlot.tubularBarPlot(with: CPTColor.green(), horizontalBars: false)
        plot.dataSource = self
        plot.delegate = self
        
        graph.add(plot, to: barPlotSpace)

        configureForDisplay()
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

    private func applySkin() {
        xAxis.titleTextStyle = activeSkin.titleStyle
        xAxis.labelTextStyle = activeSkin.labelStyle
        xAxis.axisLineStyle = activeSkin.gridLineStyle
        xAxis.majorTickLineStyle = activeSkin.gridLineStyle

        yAxis.titleTextStyle = activeSkin.titleStyle
        yAxis.labelTextStyle = activeSkin.labelStyle
        yAxis.axisLineStyle = activeSkin.gridLineStyle
        yAxis.majorTickLineStyle = activeSkin.gridLineStyle
        // yAxis.majorGridLineStyle = activeSkin.gridLineStyle
    }

    private func configureGraph() {
        xAxis.title = "Histogram (1s bin)"
        xAxis.titleOffset = 18.0
        xAxis.axisLineStyle = nil
        xAxis.labelOffset = -3.0
        xAxis.majorTickLength = 5.0
        xAxis.minorTickLineStyle = nil
        xAxis.minorTickLength = 0
        xAxis.minorTicksPerInterval = 0

        yAxis.title = nil
        yAxis.axisLineStyle = nil
        yAxis.orthogonalPosition = -0.5;
        yAxis.labelRotation = CGFloat(M_PI_2)
        yAxis.labelOffset = -3.0

        yAxis.preferredNumberOfMajorTicks = 5
        yAxis.minorTickLineStyle = nil
        yAxis.minorTicksPerInterval = 0
    }

    private func configureForDisplay() {
        configureGraph()
        activeSkin = displaySkin
        xAxis.labelingPolicy = .locationsProvided
        xAxis.majorTickLocations = Set<NSNumber>([0, binCount / 2, binCount - 1].map { NSNumber(integerLiteral: $0) })
        yAxis.labelingPolicy = .locationsProvided
        yAxis.majorTickLocations = Set<NSNumber>([0, maxY / 2, maxY].map { NSNumber(integerLiteral: $0) })
    }

    private func configureForPDF() {
        configureGraph()
        activeSkin = pdfSkin
        xAxis.majorTickLocations = nil
        xAxis.labelingPolicy = .automatic
        yAxis.majorTickLocations = nil
        yAxis.labelingPolicy = .automatic
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBounds()
    }

    func renderPDF(context: CGContext, mediaBox: CGRect, margin: CGFloat) {
        let savedSize = self.bounds.size
        defer {
            context.restoreGState()
            context.endPDFPage()
            bounds.size = savedSize
            configureForDisplay()
            reload()
        }

        self.bounds.size.width = mediaBox.size.width - 2.0 * margin
        self.bounds.size.height = mediaBox.size.height - 2.0 * margin

        context.beginPDFPage(nil)
        context.saveGState()
        context.translateBy(x: margin, y: margin)

        configureForPDF()
        hostedGraph?.reloadData()
        updateBounds()
        hostedGraph?.layoutAndRender(in: context)
    }
    
    func reload() {
        if Thread.isMainThread {
            self.hostedGraph?.reloadData()
            self.updateBounds()
            self.setNeedsDisplay()
        }
        else {
            DispatchQueue.main.async(execute: self.reload)
        }
    }

    fileprivate func updateBounds() {
        plotSpace.xRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        plotSpace.yRange = CPTPlotRange(location: 0.0, length: NSNumber(integerLiteral: maxY))
        xAxis.labelFormatter = HistogramBinFormatter(lastBin: binCount - 1)
        xAxis.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        xAxis.gridLinesRange = CPTPlotRange(location: -1.0, length: NSNumber(integerLiteral: maxY))
        yAxis.visibleRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: maxY + 1))
        yAxis.gridLinesRange = CPTPlotRange(location: -0.5, length: NSNumber(integerLiteral: binCount))
        yAxis.majorTickLocations = Set<NSNumber>([0, maxY / 2, maxY].map { NSNumber(integerLiteral: $0) })
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
        let textLayer = CPTTextLayer(text: tag, style: displaySkin.annotationStyle)
        textLayer.fill = CPTFill(color: CPTColor.black().withAlphaComponent(0.3))
        let pos = [NSNumber(value: x), NSNumber(value: y)]
        let plotSpace = hostedGraph!.allPlotSpaces().last as! CPTXYPlotSpace
        self.annotation = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: pos)
        self.annotation?.contentLayer = textLayer

        self.annotation?.displacement = CGPoint(x: 0.0, y: textLayer.frame.height / 2.0)
        hostedGraph?.plotAreaFrame?.plotArea?.addAnnotation(self.annotation)
    }
}

