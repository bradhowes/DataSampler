//
//  BRHLatencyHistogramGraphSource.swift
//  DataSampler
//
//  Created by Brad Howes on 9/16/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol BRHLatencyByTimeGraphSource {
    
    func numberOfRecords() -> UInt

    func sample(_ index: UInt) -> BRHLatencySample
}
