//
//  BRHLatencyHistogramGraphSource.swift
//  Blah
//
//  Created by Brad Howes on 9/16/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol BRHLatencyHistogramGraphSource {
    
    func numberOfRecords() -> UInt
    
    func valueForRecord(_ index: UInt) -> Int
    
    func maxValue() -> Int
}
