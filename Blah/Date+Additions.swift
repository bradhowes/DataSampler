//
//  BRHDate+Additions.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

func -(_ lhs: Date, _ rhs: Date) -> TimeInterval {
    return lhs.timeIntervalSince(rhs)
}
