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

    /**
     Formatting function for latency values
     - parameter obj: an NSNumber object containing the latency value
     - returns: the label to use
     */
    override func string(for obj: Any?) -> String? {
        guard let obj = obj as? NSNumber else { return nil }
        let dvalue = obj.doubleValue
        var value: String = String.localizedStringWithFormat("%.1f", dvalue)
        if value.hasSuffix(".0") {
            value.removeSubrange(value.index(value.endIndex, offsetBy: -2)..<value.endIndex)
        }

        return value
    }
}
