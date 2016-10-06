//
//  BRHRandomness.swift
//  Blah
//
//  Created by Brad Howes on 9/22/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import GameKit

/// Uniform random number generator. Provides methods for generating numbers in ranges.
class BRHRandomUniform {
    
    /// Random number source
    private(set) var randomSource: GKARC4RandomSource
    
    /**
     Intialize random number generator using given seed value. This should guarantee that random values from the
     generator will always follow the same sequence when using the same seed value.
     
     - parameter seed: the seed value to use to initialize the generator
     */
    init() {
        randomSource = GKARC4RandomSource()
        randomSource.dropValues(1000)
    }

    /**
     Return a random `Double` value that is withing a given range, the probability of each number in the range being
     uniform.
     
     - parameter lower: lower bound of the range (inclusive)
     - parameter upper: upper bound of the range (inclusive)
     
     - returns: new `Double` value
     */
    func uniform(lower: Double, upper: Double) -> Double {
        return Double(randomSource.nextUniform()) * (upper - lower) + lower
    }
}
