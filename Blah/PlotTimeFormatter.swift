//
//  BRHTimeFormatter.swift
//  Pods
//
//  Created by Brad Howes on 9/16/16.
//
//

import Foundation

/**
 A label formatter for a scatter plot chart with the X axis showing time values
 */
final class PlotTimeFormatter : NumberFormatter {

    /**
     Generate a label for the given value.
     - parameter obj: the value to convert
     - returns: formatted strine value
     */
    override func string(for obj: Any?) -> String? {
        guard let obj = obj as? NSNumber else { return nil }
        var dvalue = obj.doubleValue
        dvalue.round(.toNearestOrEven)
        var value = Int(dvalue)
        let hours = value >= 3600 ? value / 3600 : 0
        value = value - hours * 3600
        let minutes = value >= 60 ? value / 60 : 0
        value = value - minutes * 60
        let seconds = Int(value)

        var result = ""
        if hours > 0 { result = result.appendingFormat("%ldh", hours) }
        if minutes > 0 { result = result.appendingFormat("%ldm", minutes) }
        if seconds > 0 || result == "" { result = result.appendingFormat("%lds", seconds) }
        
        return result
    }
}
