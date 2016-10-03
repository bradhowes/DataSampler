//
//  BRHBinFormatter.swift
//  Pods
//
//  Created by Brad Howes on 9/16/16.
//
//

import Foundation

final class BRHBinFormatter : NumberFormatter {
    private let lastBin: Int
    private let lastBinLabel: String
    
    private static func formatValue(_ value: Int) -> String {
        return "\(value)"
    }

    init(lastBin: Int) {
        self.lastBin = lastBin
        self.lastBinLabel = BRHBinFormatter.formatValue(lastBin) + "+"
        super.init()
    }

    required init?(coder decoder: NSCoder) {
        self.lastBin = decoder.decodeInteger(forKey: "lastBin")
        self.lastBinLabel = BRHBinFormatter.formatValue(lastBin)
        super.init(coder: decoder)
    }

    override func string(for obj: Any?) -> String? {
        guard let obj = obj as? NSNumber else { return nil }
        let value = obj.intValue
        switch value {
        case 0: return "<1"
        case lastBin: return lastBinLabel
        default: return BRHBinFormatter.formatValue(value)
        }
    }
}
