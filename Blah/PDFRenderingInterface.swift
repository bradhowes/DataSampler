//
//  SharingInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for visualizing the contents of a recording.
 */
public protocol PDFRenderingInterface: class {

    func render(recording: Recording) -> Int64
}
