//
//  DriverInterface.swift
//  Blah
//
//  Created by Brad Howes on 11/1/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol SamplingDriverInterface {

    /**
     Start a new sampling session.
     - parameter emitInterval: the sampling interval
     - parameter runData: the storage for incoming samples
     */
    func start(emitInterval: Int, runData: RunDataInterface)

    /**
     Stop a sampling session.
     */
    func stop()
}
