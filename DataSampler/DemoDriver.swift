//
//  DemoDriver.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class DemoDriver: NSObject, SamplingDriverInterface {

    private var timer: Timer! = nil

    /**
     Start the driver. Generates artificial samples every `emitInterval` seconds, with random latency.
     - parameter emitInterval: interval in seconds for sampling
     - parameter runData: storage for incoming samples
     */
    func start(emitInterval: Int, runData: RunDataInterface) {

        let uniform = RandomUniform()
        let gaussian = RandomGaussian()
        var identifier = 1

        // Create timer to continue to add synthesized data
        //
        let block: (Timer?)->() = { timer in
            let arrivalTime = Date()
            let emissionTime = arrivalTime - gaussian.gaussian(lower: 0.001, upper: 3.0)
            let latency = arrivalTime - emissionTime
            if uniform.uniform(lower: 0.0, upper: 1.0) > 0.05 {
                let sample = Sample(identifier: identifier, latency: latency, emissionTime: emissionTime,
                                    arrivalTime: arrivalTime, medianLatency: 0.0, averageLatency: 0.0)
                runData.recordLatency(sample: sample)
            }
            identifier += 1
        }

        timer = Timer.scheduledTimer(withTimeInterval: Double(emitInterval), repeats: true, block: block)

        // Emit a sample now.
        //
        block(nil)
    }

    /**
     Stop the driver.
     */
    func stop() {
        timer.invalidate()
        timer = nil
    }
}
