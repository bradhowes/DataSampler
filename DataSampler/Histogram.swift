//
//  BRHHistogram.swift
//  Blah
//
//  Created by Brad Howes on 9/15/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/** 
 Protocol for an object that observes changes in a Histogram instance.
 */
public protocol HistogramObserver: class {

    /**
     Notification that a given bin of a Histogram has changed value.
     - parameter histogram: the Historgram that changed
     - parameter index: the bin of the Histogram that changed [0-N) where N is the histogram size
     */
    func histogramBinChanged(_ histogram: Histogram, index: Int)
}

/** 
 Definition of a histogram, a collection of integer counters that record occurances
 */
public final class Histogram : NSObject {

    public weak var observer: HistogramObserver?

    private(set) var bins: Array<Int> = []
    private(set) var maxBinIndex: Int

    private func makeBins(size: Int) {
        bins = Array<Int>(repeating: 0, count: size)
        maxBinIndex = 0
    }

    /**
     Initialize new instance
     - parameter size: the number of bins to hold in the histogram
     */
    init(size: Int) {
        assert(size > 0)
        maxBinIndex = 0
        super.init()
        makeBins(size: size)
    }

    /**
     Resize the histogram to hold a different number of bins.
     - parameter size: new size for the histogram
     */
    func resize(size: Int) {
        if bins.count != size {
            makeBins(size: size)
        }
    }

    /**
     Obtain the count value for a given bin
     - parameter index: the index of the bin to fetch
     - returns: the count value
     */
    func binAt(index: Int) -> Int {
        return bins[index]
    }

    /**
     Determine which bin a given value will fall into
     - parameter value: the value to bin
     - returns: the index for the value
     */
    func binIndexFor(value: Double) -> Int {
        let binIndex = Int(floor(value))
        return max(min(binIndex, bins.count - 1), 0)
    }

    /**
     Add a value to the histogram. Determines the bin the value belongs to, then increments its counter.
     - parameter value: the value to add
     */
    func add(value: Double) {
        let index = binIndexFor(value: value)
        bins[index] += 1
        if bins[index] > bins[maxBinIndex] {
            maxBinIndex = index
        }

        observer?.histogramBinChanged(self, index: index)
    }
}
