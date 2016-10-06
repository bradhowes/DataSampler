//
//  BRHLatencyFormatter.swift
//  Pods
//
//  Created by Brad Howes on 9/16/16.
//
//

import Foundation

final class PlotLatencyFormatter : NumberFormatter {

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
