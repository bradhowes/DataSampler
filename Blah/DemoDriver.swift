//
//  DemoDriver.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol DriverInterface {
    func start(runData: RunDataInterface)
    func stop()
}

class DemoDriver: NSObject, DriverInterface {

    private var runData: RunDataInterface!
    private var timer: Timer!

    override init() {
        self.timer = nil
        self.runData = nil
        super.init()
    }

    func start(runData: RunDataInterface) {
        self.runData = runData

        let rnd = BRHRandomUniform()
        var identifier = 1
        var elapsed = Date()

        // Create timer to continue to add synthesized data
        //
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            elapsed = elapsed.addingTimeInterval(2.0)
            let emissionTime = elapsed
            let latency = rnd.uniform(lower: 0.5, upper: 10.0) *
                (rnd.uniform(lower: 0.0, upper: 1.0) > 0.95 ? rnd.uniform(lower: 2.0, upper: 10.0) : 1.0)
            elapsed = elapsed.addingTimeInterval(latency)
            let arrivalTime = elapsed
            if rnd.uniform(lower: 0.0, upper: 1.0) > 0.1 {
                let sample = Sample(identifier: identifier, latency: latency, emissionTime: emissionTime,
                                    arrivalTime: arrivalTime, medianLatency: 0.0, averageLatency: 0.0)
                self.runData.recordLatency(sample: sample)
            }
            identifier += 1
        }
    }

    func stop() {
        timer.invalidate()
        timer = nil
        runData = nil
    }
}
