//
//  RecordingActivityLogicInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/25/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for a class that is dependent on a `RecordingActivityLogicInterface` instance
 */
public protocol RecordingActivityLogicDependent: class {
    var recordingActivityLogic: RecordingActivityLogicInterface! { get set }
}

/**
 Protocol for a class that implements the `RecordingActivityLogic` interface.
 */
public protocol RecordingActivityLogicInterface: class {

    /// Entity that uses the contents of a recording for drawing.
    var visualizer: VisualizerInterface! { get set }

    var pdfRenderer: PDFRenderingInterface! { get set }

    var canUpload: Bool { get }

    /**
     Start recording a new experiment
     */
    func start()

    /**
     Stop recording
     */
    func stop()

    /**
     Delete the given recording
     - parameter recording: instance to delete
     */
    func delete(recording: Recording)

    /**
     Select the given recording for viewing.
     - parameter recording: instance to view
     */
    func select(recording: Recording)

    func share(recording: Recording)

    func upload(recording: Recording)
}
