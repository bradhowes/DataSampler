//
//  BRHLatencyByTimeGraph.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import CorePlot
import PDFGenerator

final class GraphLatencyByTime: CPTGraphHostingView {

    static let kLatencyPlotId = NSString(string: "Latency")
    static let kAveragePlotId = NSString(string: "Avg")
    static let kMedianPlotId = NSString(string: "Median")
    static let kMissingPlotId = NSString(string: "Miss")
    
    let kPlotSymbolSize: Double = 8.0

    var source: RunDataInterface! {
        willSet {
            if source != nil {
                RunDataNewSampleNotification.unobserve(from: source, observer: self)
            }
        }
        didSet {
            RunDataNewSampleNotification.observe(from: source, observer: self, selector: #selector(sampleAdded))
            if hostedGraph == nil {
                makeGraph()
                updateTitle()
            }
            else {
                reload()
            }
        }
    }

    func sampleAdded(notification: Notification) {
        let info = RunDataNewSampleNotification(notification: notification)
        guard let plots = hostedGraph?.allPlots() else { return }

        plots.forEach {
            if $0.identifier === GraphLatencyByTime.kMissingPlotId {
                if info.sample.missingCount > 0 {
                    let numRecords = info.sample.missingCount * 2 + 1
                    $0.insertData(at: UInt(source.missing.count - numRecords), numberOfRecords: UInt(numRecords))
                }
            }
            else {
                $0.insertData(at: UInt(info.index), numberOfRecords: 1)
            }
        }

        if Thread.isMainThread {
            updateBounds()
        }
        else {
            DispatchQueue.main.async(execute: self.updateBounds)
        }
    }

    var targetYMax: Double?

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

    fileprivate let latencyFormatter = PlotLatencyFormatter()

    private func makeGraph() {

        let graph = CPTXYGraph(frame: self.frame)
        hostedGraph = graph
        
        graph.paddingLeft = 0.0
        graph.paddingRight = 0.0
        graph.paddingTop = 0.0
        graph.paddingBottom = 0.0
        
        graph.plotAreaFrame?.masksToBorder = false;
        graph.plotAreaFrame?.borderLineStyle = nil
        graph.plotAreaFrame?.cornerRadius = 0.0
        graph.plotAreaFrame?.paddingTop = 0.0
        graph.plotAreaFrame?.paddingLeft = 22.0
        graph.plotAreaFrame?.paddingBottom = 35.0
        graph.plotAreaFrame?.paddingRight = 4.0

        let axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = 0.75
        axisLineStyle.lineColor = CPTColor(genericGray: 0.45)
        
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineWidth = 0.75
        gridLineStyle.lineColor = CPTColor.green().withAlphaComponent(0.75)
        
        let tickLineStyle = CPTMutableLineStyle()
        tickLineStyle.lineWidth = 0.75
        tickLineStyle.lineColor = CPTColor(genericGray: 0.25)
        
        let plotSpace = CPTXYPlotSpace()
        graph.add(plotSpace)
        
        plotSpace.allowsUserInteraction = true
        plotSpace.allowsMomentumX = true
        plotSpace.allowsMomentumY = false
        plotSpace.delegate = self
        plotSpace.xRange = CPTPlotRange(locationDecimal: 0.0, lengthDecimal: 100.0)
        plotSpace.yRange = CPTPlotRange(locationDecimal: 0.0, lengthDecimal: 1.0)

        guard let axisSet = graph.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }
        x.plotSpace = plotSpace

        // X axis
        //
        x.titleTextStyle = titleStyle
        x.title = ""
        x.titleOffset = 18.0
        x.labelTextStyle = labelStyle

        x.axisLineStyle = gridLineStyle
        x.labelOffset = -4.0

        x.axisConstraints = CPTConstraints(lowerOffset: 0.0) // Keep the X axis from moving up/down when scrolling
        x.labelingPolicy = .automatic
        x.labelFormatter = PlotTimeFormatter()
        
        x.tickDirection = .negative
        x.majorTickLineStyle = gridLineStyle
        x.majorTickLength = 5.0
        x.majorIntervalLength = 10

        x.minorTickLineStyle = nil;
        x.minorTickLength = 0
        x.minorTicksPerInterval = 0;
        
        x.majorGridLineStyle = gridLineStyle
        x.minorGridLineStyle = nil
        
        // Y axis
        //
        guard let y = axisSet.yAxis else { return }
        y.plotSpace = plotSpace

        y.titleTextStyle = nil
        y.title = nil
        y.labelRotation = CGFloat(M_PI_2)
        
        y.labelTextStyle = labelStyle
        y.labelOffset = -3.0

        y.axisLineStyle = gridLineStyle
        y.axisConstraints = CPTConstraints(lowerOffset: 0.0)

        y.labelingPolicy = .locationsProvided
        y.labelFormatter = latencyFormatter

        y.majorGridLineStyle = gridLineStyle
        y.minorGridLineStyle = nil

        y.majorTickLineStyle = gridLineStyle
        x.tickDirection = .negative
        y.majorTickLength = 5.0

        y.minorTickLineStyle = nil

        graph.axisSet!.axes = [x, y]

        makeMissingPlot(graph: graph, plotSpace: plotSpace)
        makeAveragePlot(graph: graph, plotSpace: plotSpace)
        makeMedianPlot(graph: graph, plotSpace: plotSpace)
        makeLatencyPlot(graph: graph, plotSpace: plotSpace)
        makeLegend(graph: graph)

        updateBounds()
    }

    private func makeLegend(graph: CPTXYGraph) {
        let legend = CPTLegend(graph: graph)

        graph.legend = legend
        graph.legendAnchor = .top
        graph.legendDisplacement = CGPoint(x: 0.0, y: -5.0)
        legend.isHidden = true
        legend.fill = CPTFill(color: CPTColor.darkGray().withAlphaComponent(0.5))

        legend.textStyle = titleStyle;

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.75
        lineStyle.lineColor = CPTColor(genericGray: 0.45)

        legend.borderLineStyle = lineStyle
        legend.cornerRadius = 5.0
        legend.swatchSize = CGSize(width: 25.0, height: 25.0)
        legend.numberOfRows = 1
        legend.delegate = self

        // Create a 2-tap gesture recognizer to show/hide the legend
        //
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.numberOfTouchesRequired = 1
        recognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(recognizer)
    }

    func handleTap(recognizer: UITapGestureRecognizer) {
        guard let legend = self.hostedGraph?.legend else { return }
        legend.isHidden = !legend.isHidden
    }
    
    private func makeLatencyPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {

        let plot = CPTScatterPlot()
        plot.identifier = GraphLatencyByTime.kLatencyPlotId
        plot.dataSource = self
        plot.cachePrecision = .double

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 1.0
        lineStyle.lineColor = CPTColor.gray()
        plot.dataLineStyle = lineStyle

        let symbolGradient = CPTGradient(beginning: CPTColor(componentRed: 0.75, green: 0.75, blue: 1.0, alpha: 1.0),
                                         ending: CPTColor.cyan())
        symbolGradient.gradientType = .radial
        symbolGradient.startAnchor = CGPoint(x: 0.25, y: 0.75)
        
        let plotSymbol = CPTPlotSymbol.ellipse()
        plotSymbol.fill = CPTFill(gradient: symbolGradient)
        plotSymbol.lineStyle = nil;
        plotSymbol.size = CGSize(width: kPlotSymbolSize, height: kPlotSymbolSize)
        plot.plotSymbol = plotSymbol;
        plot.plotSymbolMarginForHitDetection = CGFloat(kPlotSymbolSize) * CGFloat(1.5)

        plot.delegate = self

        graph.add(plot, to: plotSpace)
    }

    private func makeAveragePlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        
        let plot = CPTScatterPlot()
        plot.identifier = GraphLatencyByTime.kAveragePlotId
        plot.dataSource = self
        plot.cachePrecision = .double

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 3.0
        lineStyle.lineColor = CPTColor.yellow()
        plot.dataLineStyle = lineStyle
        
        graph.add(plot, to: plotSpace)
    }
    
    private func makeMedianPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {

        let plot = CPTScatterPlot()
        plot.identifier = GraphLatencyByTime.kMedianPlotId
        plot.dataSource = self
        plot.cachePrecision = .double
        
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 3.0
        lineStyle.lineColor = CPTColor.magenta()
        plot.dataLineStyle = lineStyle
        
        graph.add(plot, to: plotSpace)
    }
    
    private func makeMissingPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        
        let plot = CPTScatterPlot()
        plot.identifier = GraphLatencyByTime.kMissingPlotId
        plot.dataSource = self
        plot.cachePrecision = .double

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineJoin = .round
        lineStyle.lineCap = .round
        lineStyle.lineWidth = 1.0
        lineStyle.lineColor = CPTColor.red()
        plot.dataLineStyle = lineStyle
        plot.areaBaseValue = 0.0
        plot.areaFill = CPTFill(color: CPTColor.red().withAlphaComponent(0.25))
        graph.add(plot, to: plotSpace)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBounds()
    }

    private func updateTitle() {
        guard let axisSet = hostedGraph?.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }

        if !source.name.isEmpty {
            x.title = String(format: "%@ - %lds Intervals", source.name, source.emitInterval)
        }
        else {
            x.title = String(format: "%lds Intervals", source.emitInterval)
        }

        Logger.log("new title: \(x.title)")
    }
    
    func reload() {
        if Thread.isMainThread {
            self.hostedGraph?.reloadData()
            self.updateTitle()
            self.updateBounds()
            self.setNeedsDisplay()
        }
        else {
            DispatchQueue.main.async(execute: self.reload)
        }
    }

    private func calculatePlotWidth() -> Double {
        guard let w = hostedGraph?.frame.size.width else { return 10.0 }
        return floor(Double(w) / (kPlotSymbolSize * 1.5))
    }

    private func findFirstSampleAtOrBefore(when: TimeInterval) -> Int {
        let pos = source.samples.map({$0.arrivalTime}).insertionIndexOf(value: source.startTime.addingTimeInterval(when),
                                                                        predicate: {$0 < $1})
        return pos
    }

    private func findMinMaxInRange(range: CPTPlotRange) -> (min: Double, max: Double)? {
        if source.samples.count == 0 { return nil }
        let x0 = findFirstSampleAtOrBefore(when: range.locationDouble)
        let x1 = findFirstSampleAtOrBefore(when: range.endDouble)
        return source.samples[x0..<x1].map({$0.latency}).minMax()
    }

    private func updateBounds() {
        guard let plotSpace = hostedGraph?.allPlotSpaces().last as? CPTXYPlotSpace else { return }
        let plotData = source.samples
        let visiblePoints = calculatePlotWidth() * source.estArrivalInterval

        var xMin = 0.0
        var xMax = visiblePoints

        if plotData.count > 0 {
            let tmp = plotData.last!
            let xPos = xValueFor(sample: tmp)
            if xPos > xMax {
                xMin = xPos - xMax
                xMax = xPos
            }
            else if xPos < xMax {
                xMax = xPos
            }
        }

        let xMinPadded = 0.0 - source.estArrivalInterval / 2.0
        let xMaxPadded = xMax + source.estArrivalInterval / 2.0
        plotSpace.globalXRange = CPTPlotRange(location: NSNumber(value: xMinPadded),
                                              length: NSNumber(value: xMaxPadded - xMinPadded))

        if xMin == 0.0 {

            // Nothing going on here -- just show a default range of X
            //
            let xRange = CPTMutablePlotRange(location: NSNumber(value: xMin), length: NSNumber(value: xMax - xMin))
            xRange.expand(byFactor: 1.05)
            plotSpace.xRange = xRange
        }
        else if plotData.count > 1 && xValueFor(sample:plotData[plotData.count - 2]) < plotSpace.xRange.endDouble {

            // Scroll the view to show the new points
            //
            let oldRange = plotSpace.xRange
            let newRange = CPTMutablePlotRange(location: NSNumber(value: xMin), length: NSNumber(value: xMax - xMin))
            newRange.expand(byFactor: 1.05)
            CPTAnimation.animate(plotSpace, property: "xRange", from: oldRange, to: newRange, duration: 0.25)
        }

        updateYRange()
    }

    fileprivate func updateYRange() {
        guard let plotSpace = hostedGraph?.allPlotSpaces().last as? CPTXYPlotSpace else { return }
        guard let axisSet = hostedGraph?.axisSet as? CPTXYAxisSet else { return }
        guard let x = axisSet.xAxis else { return }
        guard let y = axisSet.yAxis else { return }

        let xRange = plotSpace.xRange
        let yMinMax = findMinMaxInRange(range: xRange) ?? (0.0, 10.0)
        let yMax = floor(yMinMax.max + 0.9)
        
        if targetYMax != yMax {
            targetYMax = yMax
            let yRange = CPTMutablePlotRange(location: NSNumber(value: 0.0), length: NSNumber(value: yMax))
            y.majorTickLocations = Set<NSNumber>([0, yMax / 2, yMax].map { NSNumber(value: $0) })
            y.visibleAxisRange = yRange
            y.visibleRange = yRange
            x.gridLinesRange = yRange

            yRange.expand(byFactor: 1.05)
            let oldRange = plotSpace.yRange
            CPTAnimation.animate(plotSpace, property: "yRange", from: oldRange, to: yRange, duration: 0.25)
        }

        y.gridLinesRange = xRange
    }
}

// - MARK: Data Source Methods

extension GraphLatencyByTime: CPTScatterPlotDataSource {

    func numberOfRecords(for plot: CPTPlot) -> UInt {
        guard let tag = plot.identifier as? NSString else { return 0 }
        switch tag {
        case GraphLatencyByTime.kMissingPlotId: return UInt(source.missing.count)
        default: return UInt(source.samples.count)
        }
    }

    func xValueFor(sample: Sample) -> Double {
        return sample.arrivalTime.timeIntervalSince(source.startTime)
    }

    func yValueFor(sample: Sample) -> Double {
        return sample.latency
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        guard let field = CPTScatterPlotField(rawValue: Int(fieldEnum)) else { return nil }
        guard let tag = plot.identifier as? NSString else { return nil }
        let sample = tag == GraphLatencyByTime.kMissingPlotId ? source.missing[Int(idx)] : source.samples[Int(idx)]
        switch field {
        case .X: return xValueFor(sample: sample)
        case .Y:
            switch plot.identifier as! NSString {
            case GraphLatencyByTime.kLatencyPlotId: return sample.latency
            case GraphLatencyByTime.kAveragePlotId: return sample.averageLatency
            case GraphLatencyByTime.kMedianPlotId: return sample.medianLatency
            case GraphLatencyByTime.kMissingPlotId: return sample.latency
            default: return 0.0
            }
        }
    }

}

// - MARK: Plot Space Delegate Methods

extension GraphLatencyByTime: CPTPlotSpaceDelegate {
    
    func plotSpace(_ space: CPTPlotSpace, didChangePlotRangeFor coordinate: CPTCoordinate) {
        guard let plotSpace = space as? CPTXYPlotSpace else { return }
        switch coordinate {
        case .Y:
            let yRange = plotSpace.yRange
            if yRange.locationDouble != 0.0 {
                plotSpace.yRange = CPTPlotRange(location: NSNumber(value: 0.0), length: yRange.length)
            }
        case .X:
            let xRange = plotSpace.xRange
            if xRange.locationDouble < 0.0 {
                plotSpace.xRange = CPTPlotRange(location: NSNumber(value: 0.0), length: xRange.length)
            }

            updateYRange()
        default: break
        }
    }
}

// - MARK: Legend Delegate Methods

extension GraphLatencyByTime: CPTLegendDelegate {
    func legend(_ legend: CPTLegend, legendEntryFor plot: CPTPlot, wasSelectedAt idx: UInt) {
        plot.isHidden = !plot.isHidden
    }
}

extension GraphLatencyByTime: CPTScatterPlotDelegate {
    func scatterPlot(_ plot: CPTScatterPlot, plotSymbolTouchUpAtRecord idx: UInt) {
        if let annotation = self.annotation {
            hostedGraph?.plotAreaFrame?.plotArea?.removeAnnotation(annotation)
            self.annotation = nil
            if self.annotationIndex == Int(idx) {
                return
            }
        }

        self.annotationIndex = Int(idx)

        let sample = source.samples[self.annotationIndex]
        let x = sample.arrivalTime.timeIntervalSince(source.startTime)
        let y = sample.latency

        let tag = latencyFormatter.string(from: NSNumber(value: y)) ?? "???"
        let textLayer = CPTTextLayer(text: "\(sample.identifier): " + tag, style: annotationStyle)
        textLayer.fill = CPTFill(color: CPTColor.black().withAlphaComponent(0.6))
        let pos = [NSNumber(value: x), NSNumber(value: y)]
        let plotSpace = hostedGraph!.allPlotSpaces().last as! CPTXYPlotSpace
        self.annotation = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: pos)
        self.annotation?.contentLayer = textLayer

        let xOffset = (Double(textLayer.frame.width) + kPlotSymbolSize) / 2.0
        if x < plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble / 2.0 {
            self.annotation?.displacement = CGPoint(x: xOffset, y: 0.0)
        }
        else {
            self.annotation?.displacement = CGPoint(x: -xOffset, y: 0.0)
        }
        hostedGraph?.plotAreaFrame?.plotArea?.addAnnotation(self.annotation)
    }
}

extension GraphLatencyByTime: PDFRenderable {

    var pdfContent: PDFPage {
        get {
            let graph = self.hostedGraph! as! CPTXYGraph
            let plotSpace = graph.plotSpace(at: 0) as! CPTXYPlotSpace
            let savedXRange = plotSpace.xRange
            let savedYRange = plotSpace.yRange
            plotSpace.xRange = plotSpace.globalXRange!
            plotSpace.yRange = plotSpace.globalYRange!
            defer {
                plotSpace.xRange = savedXRange
                plotSpace.yRange = savedYRange
            }

            let data = graph.dataForPDFRepresentationOfLayer()
            return PDFPage.binary(data)
        }
    }
}
