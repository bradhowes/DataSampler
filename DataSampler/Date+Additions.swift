//
//  BRHDate+Additions.swift
//  DataSampler
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Allow for subtraction operator between two Date objects.
 - parameter lhs: first Date object
 - parameter rhs: second date object
 - returns: difference between the two Date as seconds
 */
func -(_ lhs: Date, _ rhs: Date) -> TimeInterval {
    return lhs.timeIntervalSince(rhs)
}
