//
//  BRHLatencyFormatter.swift
//  Pods
//
//  Created by Brad Howes on 9/16/16.
//
//

import Foundation

/**
 A label formatter for a scatter plot chart with the Y axis showing latency values
 */
final class PlotLatencyFormatter : NumberFormatter {

    override init() {
        super.init()
        maximumFractionDigits = 1
        minimumFractionDigits = 0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        maximumFractionDigits = 1
        minimumFractionDigits = 0
    }

    /**
     Formatting function for latency values
     - parameter obj: an NSNumber object containing the latency value
     - returns: the label to use
     */
    override func string(for obj: Any?) -> String? {
        guard var value = super.string(for: obj) else { return nil }
        if value.hasSuffix(".0") {
            value.removeSubrange(value.index(value.endIndex, offsetBy: -2)..<value.endIndex)
        }

        return value
    }
}
