//
//  BRHBinFormatter.swift
//  Pods
//
//  Created by Brad Howes on 9/16/16.
//
//

import Foundation

/** 
 A label formatter for a bar chart with the X axis showing histogram bins
 */
final class HistogramBinFormatter : NumberFormatter {

    /// The index of the last bin in the histogram
    private let lastBin: Int

    /// The label to use for the last bin
    private let lastBinLabel: String

    /**
     Obtain a label for the given index value
     - parameter value: the index to format
     - returns: the label to use
     */
    private static func formatValue(_ value: Int) -> String {
        return "\(value)"
    }

    /**
     Construct a new formatter
     - parameter lastBin: the index of the last bin in the histogram
     */
    init(lastBin: Int) {
        self.lastBin = lastBin
        self.lastBinLabel = HistogramBinFormatter.formatValue(lastBin) + "+"
        super.init()
    }

    /**
     Implement constructor for NSCoder. Not used by us, but we need it nonetheless.
     - parameter decoder: the NSCoder to take values from
     */
    required init?(coder decoder: NSCoder) {
        self.lastBin = decoder.decodeInteger(forKey: "lastBin")
        self.lastBinLabel = HistogramBinFormatter.formatValue(lastBin)
        super.init(coder: decoder)
    }

    /**
     Formatting function for bin indices
     - parameter obj: an NSNumber object containing the index of the bin
     - returns: the label to use for the bin
     */
    override func string(for obj: Any?) -> String? {
        guard let obj = obj as? NSNumber else { return nil }
        let value = obj.intValue
        switch value {
        case 0: return "<1"
        case lastBin: return lastBinLabel
        default: return HistogramBinFormatter.formatValue(value)
        }
    }
}
