//
//  BRHHistogram.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

final class Histogram : NSObject {

    static let changedNotification = Notification.Name(rawValue: "HistogramChanged")

    private(set) var bins: Array<Int> = []
    private(set) var maxBinIndex: Int

    private func makeBins(size: Int) {
        bins = Array<Int>(repeating: 0, count: size)
        maxBinIndex = 0
    }
    
    private func notify(binIndex: Int?) {
        NotificationCenter.default.post(name: Histogram.changedNotification, object: self,
                                        userInfo: ["binIndex": binIndex])
    }

    init(size: Int) {
        assert(size > 0)
        maxBinIndex = 0
        super.init()
        makeBins(size: size)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func resize(size: Int) {
        makeBins(size: size)
    }

    func maxBinChanged(notification: Notification) {
        guard let userInfo = notification.userInfo, let sizeObj = userInfo["new"] else { return }
        if let size = sizeObj as? Int {
            makeBins(size: size)
            notify(binIndex: nil)
        }
    }

    func binAt(index: Int) -> Int {
        return bins[index]
    }

    func binIndexFor(value: Double) -> Int {
        let binIndex = Int(floor(value))
        return max(min(binIndex, bins.count - 1), 0)
    }

    func add(value: Double, silently: Bool = false) {
        let index = binIndexFor(value: value)
        bins[index] += 1
        if bins[index] > bins[maxBinIndex] {
            maxBinIndex = index
        }
        
        if !silently { notify(binIndex: index) }
    }

    func replace(values: Array<LatencySample>) {
        makeBins(size: bins.count)
        values.forEach { add(value: $0.latency, silently: true) }
        notify(binIndex: nil)
    }

    func replace(with rhs: Histogram) {
        self.bins = rhs.bins
        self.maxBinIndex = rhs.maxBinIndex
        notify(binIndex: nil)
    }

    func clear() {
        makeBins(size: bins.count)
        notify(binIndex: nil)
    }
}

extension Histogram : GraphLatencyHistogramSource {

    func numberOfRecords() -> UInt {
        return UInt(bins.count)
    }

    func valueForRecord(_ index: UInt) -> Int {
        return bins[Int(index)]
    }

    func maxValue() -> Int {
        return bins[maxBinIndex]
    }
}
