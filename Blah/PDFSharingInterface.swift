//
//  SharingInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import PDFGenerator

public protocol PDFRenderable: class {
    var pdfContent: PDFPage { get }
}

/**
 Protocol for visualizing the contents of a recording.
 */
public protocol PDFSharingInterface: class {

    func share()
}
