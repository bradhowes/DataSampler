//
//  BRHLatencyByTimeGraph.swift
//  DataSampler
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import CorePlot

extension CPTPlot {

    var plotId: LatencyPlotId {
        get {
            return LatencyPlotId(rawValue: name!)!
        }
        set {
            name = newValue.rawValue
            title = newValue.legend
        }
    }
}

/**
 Scatter plot that shows sample latencies over time.
 */
final class GraphLatencyByTime: CPTGraphHostingView, Skinnable {

    let displaySkin = DisplayGraphSkin()
    let pdfSkin = PDFGraphSkin()

    var activeSkin: GraphSkinInterface! {
        didSet {
            applySkin()
        }
    }

    var source: RunDataInterface? {
        willSet {
            if source != nil {
                RunDataNewSampleNotification.unobserve(from: source!, observer: self)
                if annotation != nil {
                    hostedGraph?.plotAreaFrame?.plotArea?.removeAnnotation(annotation)
                    annotation = nil
                }
            }
            else {
                makeGraph()
            }
        }
        didSet {
            RunDataNewSampleNotification.observe(from: source!, observer: self, selector: #selector(sampleAdded))
            plots.forEach { $0.source = source }
            updateTitle()
            reload()
        }
    }

    func sampleAdded(notification: Notification) {
        plots.forEach { $0.insertRecord() }
        if Thread.isMainThread {
            updateBounds()
        }
        else {
            DispatchQueue.main.async {self.updateBounds()}
        }
    }

    fileprivate lazy var labelStyle: CPTTextStyle = {
        let labelStyle = CPTMutableTextStyle()
        labelStyle.color = CPTColor(componentRed: 0.0, green: 1.0, blue: 1.0, alpha: 0.75)
        labelStyle.fontSize = 12.0
        return labelStyle
    }()

    fileprivate var annotation: CPTPlotSpaceAnnotation? = nil
    fileprivate var annotationIndex: Int = 0

    fileprivate lazy var plotSpace: CPTXYPlotSpace = {
        return self.hostedGraph!.allPlotSpaces().last! as! CPTXYPlotSpace
    }()

    fileprivate lazy var plots: [LatencyPlotInterface] = {
        return self.hostedGraph!.allPlots().map { $0 as! LatencyPlotInterface }
    }()

    fileprivate lazy var xAxis: CPTXYAxis = {
        return (self.hostedGraph!.axisSet! as! CPTXYAxisSet).xAxis!
    }()

    fileprivate lazy var yAxis: CPTXYAxis = {
        return (self.hostedGraph!.axisSet! as! CPTXYAxisSet).yAxis!
    }()

    fileprivate lazy var latencyFormatter = PlotLatencyFormatter()

    fileprivate func makeGraph() {

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

        let plotSpace = CPTXYPlotSpace()
        graph.add(plotSpace)

        plotSpace.allowsUserInteraction = true
        plotSpace.allowsMomentumX = true
        plotSpace.allowsMomentumY = false
        plotSpace.delegate = self
        plotSpace.xRange = CPTPlotRange(locationDecimal: 0.0, lengthDecimal: 100.0)
        plotSpace.yRange = CPTPlotRange(locationDecimal: 0.0, lengthDecimal: 1.0)

        xAxis.plotSpace = plotSpace
        yAxis.plotSpace = plotSpace

        configureForDisplay()

        graph.axisSet!.axes = [xAxis, yAxis]

        makeMissingPlot(graph: graph, plotSpace: plotSpace)
        makeAveragePlot(graph: graph, plotSpace: plotSpace)
        makeMedianPlot(graph: graph, plotSpace: plotSpace)
        makeLatencyPlot(graph: graph, plotSpace: plotSpace)
        makeLegend(graph: graph)

        updateBounds()
    }

    private func applySkin() {
        xAxis.titleTextStyle = activeSkin.titleStyle
        xAxis.labelTextStyle = activeSkin.labelStyle
        xAxis.majorTickLineStyle = activeSkin.gridLineStyle
        xAxis.majorGridLineStyle = activeSkin.gridLineStyle

        yAxis.titleTextStyle = activeSkin.titleStyle
        yAxis.labelTextStyle = activeSkin.labelStyle
        yAxis.majorTickLineStyle = activeSkin.gridLineStyle
        yAxis.majorGridLineStyle = activeSkin.gridLineStyle
    }

    private func configureGraph() {
        xAxis.title = ""
        xAxis.titleOffset = 18.0
        xAxis.labelOffset = -4.0
        xAxis.axisLineStyle = nil // activeSkin.gridLineStyle
        xAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0) // Keep the X axis from moving up/down when scrolling
        xAxis.labelingPolicy = .automatic
        xAxis.labelFormatter = PlotTimeFormatter()
        xAxis.tickDirection = .negative
        xAxis.majorTickLength = 2.5
        xAxis.majorIntervalLength = 10
        xAxis.minorTickLineStyle = nil;
        xAxis.minorTickLength = 0
        xAxis.minorTicksPerInterval = 0;
        xAxis.minorGridLineStyle = nil

        // Y axis
        //
        yAxis.titleTextStyle = nil
        yAxis.title = nil
        yAxis.labelRotation = CGFloat(M_PI_2)
        yAxis.labelTextStyle = labelStyle
        yAxis.labelOffset = -1.5
        yAxis.axisLineStyle = nil
        yAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0)
        yAxis.labelingPolicy = .locationsProvided
        yAxis.labelFormatter = latencyFormatter
        yAxis.minorGridLineStyle = nil
        yAxis.tickDirection = .negative
        yAxis.majorTickLength = 2.5
        yAxis.minorTickLineStyle = nil
    }

    private func configureForDisplay() {
        configureGraph()
        activeSkin = displaySkin
        yAxis.labelingPolicy = .locationsProvided
    }

    private func configureForPDF() {
        configureGraph()
        activeSkin = pdfSkin
        yAxis.labelingPolicy = .automatic
    }

    private func makeLatencyPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        let plot = LatencyPlot()
        plot.configure(owner: self)
        graph.add(plot, to: plotSpace)
    }

    private func makeAveragePlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        let plot = AveragePlot()
        plot.configure(owner: self)
        graph.add(plot, to: plotSpace)
    }

    private func makeMedianPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        let plot = MedianPlot()
        plot.configure(owner: self)
        graph.add(plot, to: plotSpace)
    }

    private func makeMissingPlot(graph: CPTXYGraph, plotSpace: CPTXYPlotSpace) {
        let plot = MissingPlot()
        plot.configure(owner: self)
        graph.add(plot, to: plotSpace)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBounds()
    }

    private func updateTitle() {
        guard let source = self.source else { return }
        if !source.name.isEmpty {
            xAxis.title = String(format: "%@ - %lds Intervals", source.name, source.emitInterval)
        }
        else {
            xAxis.title = String(format: "%lds Intervals", source.emitInterval)
        }

        Logger.log("new title: \(xAxis.title)")
    }

    func renderPDF(context: CGContext, mediaBox: CGRect, margin: CGFloat) {
        let savedSize = self.bounds.size
        defer {
            context.restoreGState()
            context.endPDFPage()
            configureForDisplay()
            bounds.size = savedSize
            hostedGraph?.reloadData()
            updateTitle()
            updateBounds(onePage: false)
            setNeedsDisplay()
        }

        self.bounds.size.width = mediaBox.size.height - 2.0 * margin
        self.bounds.size.height = mediaBox.size.width - 2.0 * margin

        context.beginPDFPage(nil)
        context.saveGState()
        context.translateBy(x: mediaBox.width - margin, y: margin)
        context.rotate(by: CGFloat.pi / 2.0)

        configureForPDF()
        hostedGraph?.reloadData()
        updateTitle()
        updateBounds(onePage: true)
        hostedGraph?.layoutAndRender(in: context)
    }

    private let xRangeNeedsUpdate = CPTPlotRange(location: NSNumber(value: 0.0), length: NSNumber(value: 1.0))

    func reload() {
        if Thread.isMainThread {
            self.hostedGraph?.reloadData()
            self.updateTitle()
            self.plotSpace.xRange = xRangeNeedsUpdate
            self.updateBounds()
            self.setNeedsDisplay()
        }
        else {
            DispatchQueue.main.async() {
                self.reload()
            }
        }
    }

    fileprivate func plotWidthInSamples() -> Double {
        guard let w = hostedGraph?.frame.size.width else { return 100.0 }
        return floor(Double(w) / (LatencyPlot.kPlotSymbolSize * 1.5))
    }

    fileprivate func findFirstSampleAtOrBefore(when: TimeInterval) -> Int {
        guard let source = self.source else { return 0 }
        let value = source.startTime.addingTimeInterval(when)
        let pos = source.samples.map({$0.arrivalTime}).insertionIndexOf(value: value, predicate: {$0 < $1})
        return pos
    }

    fileprivate func findMinMaxInRange(range: CPTPlotRange) -> (min: Double, max: Double)? {
        guard let source = self.source else { return nil }
        if source.samples.count == 0 { return nil }
        let x0 = findFirstSampleAtOrBefore(when: range.locationDouble)
        let x1 = findFirstSampleAtOrBefore(when: range.endDouble)
        return source.samples[x0..<x1].map({$0.latency}).minMax()
    }

    fileprivate func updateBounds(onePage: Bool = false) {
        guard let samples = source?.samples else { return }

        let spacing = Double(source!.emitInterval)
        let plotWidthInTime = plotWidthInSamples() * spacing
        let oldRange = plotSpace.xRange

        // Calculate initial X axis min/max values
        //
        var xMin = 0.0
        var xMax = plotWidthInTime
        var xPos = xMax

        if samples.count > 0 {
            xPos = xValueFor(sample: samples.last!)
            if onePage {
                xMax = xPos
            }
            else if xPos > plotWidthInTime {
                if oldRange != xRangeNeedsUpdate {
                    xMin = xPos - plotWidthInTime
                    xMax = xPos
                }
            }
            else {
                xMin = 0.0
                xMax = max(xPos, 10.0)
            }
        }

        plotSpace.globalXRange = CPTPlotRange(location: NSNumber(value: -0.1), length: NSNumber(value: xPos * 1.02))

        if samples.count > 1 && xValueFor(sample:samples[samples.count - 2]) < plotSpace.xRange.endDouble {

            // Scroll the view to show the new points
            //
            let newRange = CPTPlotRange(location: NSNumber(value: xMin), length: NSNumber(value: (xMax - xMin) * 1.02))
            CPTAnimation.animate(plotSpace, property: "xRange", from: oldRange, to: newRange, duration: 0.125)
        }
        else if oldRange == xRangeNeedsUpdate || xMax < plotWidthInTime {
            let newRange = CPTPlotRange(location: -0.1, length: NSNumber(value: xMax * 1.02))
            CPTAnimation.animate(plotSpace, property: "xRange", from: oldRange, to: newRange, duration: 0.125)
        }

        updateYRange(onePage: onePage)
    }

    /** 
     Determine max sample value in visible X range.
     - returns: plot range of [0.0, max Y]
     */
    fileprivate func calculateYRange() -> CPTMutablePlotRange {
        let xRange = plotSpace.xRange
        let yMinMax = findMinMaxInRange(range: xRange) ?? (0.0, 10.0)
        let yMax = floor(yMinMax.max + 0.9)
        let yRange = CPTMutablePlotRange(location: NSNumber(value: 0.0), length: NSNumber(value: yMax))
        return yRange
    }

    /** 
     Determine max latency value and update graph elements to use it as max value on Y axis.
     */
    fileprivate func updateYRange(onePage: Bool = false) {
        let yRange = calculateYRange()
        let yMax = yRange.endDouble

        yAxis.majorTickLocations = Set<NSNumber>([0, yMax / 2.0, yMax].map { NSNumber(value: $0) })
        yAxis.visibleAxisRange = yRange
        yAxis.visibleRange = yRange
        yAxis.gridLinesRange = plotSpace.xRange
        xAxis.gridLinesRange = yRange

        yRange.expand(byFactor: 1.05)

        if onePage {
            plotSpace.yRange = yRange
        }
        else {
            let oldRange = plotSpace.yRange
            CPTAnimation.animate(plotSpace, property: "yRange", from: oldRange, to: yRange, duration: 0.125)
        }
    }
}

// - MARK: CPTScatterPlotDataSource Methods

extension GraphLatencyByTime: CPTScatterPlotDataSource {

    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt((plot as! LatencyPlotInterface).numberOfRecords())
    }

    func xValueFor(sample: Sample) -> Double {
        return sample.arrivalTime.timeIntervalSince(source!.startTime)
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        guard let field = CPTScatterPlotField(rawValue: Int(fieldEnum)) else { return nil }
        guard let p = plot as? LatencyPlotInterface else { fatalError("*** unexpected plot type") }
        switch field {
        case .X: return p.xValueOfRecord(record: Int(idx))
        case .Y: return p.yValueOfRecord(record: Int(idx))
        }
    }
}

// - MARK: CPTPlotSpaceDelegate Methods

extension GraphLatencyByTime: CPTPlotSpaceDelegate {

    func plotSpace(_ space: CPTPlotSpace, didChangePlotRangeFor coordinate: CPTCoordinate) {
        switch coordinate {
        case .Y:
            let yRange = plotSpace.yRange
            if yRange.locationDouble != 0.0 {
                plotSpace.yRange = CPTPlotRange(location: NSNumber(value: 0.0), length: yRange.length)
            }
        case .X:
            updateYRange()
        default: break
        }
    }
}

// - MARK: Legend Management

extension GraphLatencyByTime: CPTLegendDelegate {

    fileprivate func makeLegend(graph: CPTXYGraph) {
        let legend = CPTLegend(graph: graph)

        graph.legend = legend
        graph.legendAnchor = .top
        graph.legendDisplacement = CGPoint(x: 0.0, y: -5.0)
        legend.isHidden = true
        legend.fill = CPTFill(color: CPTColor.darkGray().withAlphaComponent(0.5))

        legend.textStyle = displaySkin.titleStyle;

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
    
    func legend(_ legend: CPTLegend, legendEntryFor plot: CPTPlot, wasSelectedAt idx: UInt) {
        plot.isHidden = !plot.isHidden
    }
}

// - MARK: CPTScatterPlotDelegate Methods

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

        let sample = source!.samples[self.annotationIndex]
        let x = sample.arrivalTime.timeIntervalSince(source!.startTime)
        let y = sample.latency

        let tag = latencyFormatter.string(from: NSNumber(value: y)) ?? "???"
        let textLayer = CPTTextLayer(text: "\(sample.identifier): " + tag, style: displaySkin.annotationStyle)
        textLayer.fill = CPTFill(color: CPTColor.black().withAlphaComponent(0.6))
        let pos = [NSNumber(value: x), NSNumber(value: y)]
        let plotSpace = hostedGraph!.allPlotSpaces().last as! CPTXYPlotSpace
        self.annotation = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: pos)
        self.annotation?.contentLayer = textLayer

        let xOffset = (Double(textLayer.frame.width) + LatencyPlot.kPlotSymbolSize) / 2.0
        if x < plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble / 2.0 {
            self.annotation?.displacement = CGPoint(x: xOffset, y: 0.0)
        }
        else {
            self.annotation?.displacement = CGPoint(x: -xOffset, y: 0.0)
        }
        hostedGraph?.plotAreaFrame?.plotArea?.addAnnotation(self.annotation)
    }
}
