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
final class RandomUniform {
    
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

final class RandomGaussian {

    /// Random number source
    private let randomSource: GKARC4RandomSource
    private let gaussian: GKGaussianDistribution
    private let span: Int

    /**
     Intialize random number generator using given seed value. This should guarantee that random values from the
     generator will always follow the same sequence when using the same seed value.

     - parameter seed: the seed value to use to initialize the generator
     */
    init(span: Int = 100) {
        self.randomSource = GKARC4RandomSource()
        self.randomSource.dropValues(1000)
        self.span = span
        self.gaussian = GKGaussianDistribution(randomSource: randomSource, lowestValue: 0, highestValue: span)
    }

    /**
     Return a random `Double` value that is withing a given range, the probability of each number in the range being
     uniform.

     - parameter lower: lower bound of the range (inclusive)
     - parameter upper: upper bound of the range (inclusive)

     - returns: new `Double` value
     */
    func gaussian(lower: Double, upper: Double) -> Double {
        return Double(self.gaussian.nextInt()) / Double(span) * (upper - lower) + lower
    }
}
