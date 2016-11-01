//
//  VisualizerInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/25/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import PDFGenerator

/**
 Protocol for visualizing the contents of a recording.
 */
public protocol VisualizerInterface: class {

    /**
     Generate or update displays using the given data
     - parameter dataSource: data to visualize
     */
    func visualize(dataSource: RunDataInterface)
}
