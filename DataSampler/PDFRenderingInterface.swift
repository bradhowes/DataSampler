//
//  PDFRenderingInterface.swift
//  DataSampler
//
//  Created by Brad Howes on 10/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for visualizing the contents of a recording.
 */
public protocol PDFRenderingInterface: class {

    /**
     Generate PDF
     - parameter dataSource: data to use to generate the PDF
     - returns: NSData containing the PDF or nil if there was an error
     */
    func render(dataSource: RunDataInterface) -> NSData?
}
