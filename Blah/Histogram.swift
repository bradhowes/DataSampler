//
//  BRHHistogram.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

final class Histogram : NSObject {

    private(set) var bins: Array<Int> = []
    private(set) var maxBinIndex: Int

    private func makeBins(size: Int) {
        bins = Array<Int>(repeating: 0, count: size)
        maxBinIndex = 0
    }

    init(size: Int) {
        assert(size > 0)
        maxBinIndex = 0
        super.init()
        makeBins(size: size)
    }

    func resize(size: Int) {
        makeBins(size: size)
    }

    func binAt(index: Int) -> Int {
        return bins[index]
    }

    func binIndexFor(value: Double) -> Int {
        let binIndex = Int(floor(value))
        return max(min(binIndex, bins.count - 1), 0)
    }

    func add(value: Double) {
        let index = binIndexFor(value: value)
        bins[index] += 1
        if bins[index] > bins[maxBinIndex] {
            maxBinIndex = index
        }
        
        HistogramBinChangedNotification.post(sender: self, index: index)
    }
}
