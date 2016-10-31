//
//  ActivityLogic.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/** 
 Manages state changes to `Recording` instances.
 */
final class RecordingActivityLogic: NSObject, RecordingActivityLogicInterface {

    /// Object that can render the graphs using `Recording` data.
    weak var visualizer: VisualizerInterface! {
        didSet {
            visualizer.visualize(dataSource: newRunData())
        }
    }

    /// Object that can generate a PDF of the graphs using `Recording` data.
    weak var pdfRenderer: PDFRenderingInterface!

    /// Returns `true` when `Recording` instances can be uploaded to Dropbox
    var canUpload: Bool { return dropboxController.isLinked }

    private let recordingsStore: RecordingsStoreInterface
    private let dropboxController: DropboxControllerInterface
    private let demoDriver: DriverInterface?
    private var currentRecording: Recording?
    private var selectedRecording: Recording?

    /**
     Initialize new instance.
     - parameter store: the Core Data storage to use for creating new `Recording` instances
     - parameter dropboxController: the Dropbox controller to use for uploading recordings
     - parameter demoDriver: the driver to use for generating synthetic data
     */
    init(store: RecordingsStoreInterface, dropboxController: DropboxControllerInterface,
         demoDriver: DriverInterface? = nil) {
        self.recordingsStore = store
        self.dropboxController = dropboxController
        self.demoDriver = demoDriver
        super.init()
    }

    /**
     Create a new `RunData` object for use with a new recording.
     - returns: new `RunData` instance
     */
    private func newRunData() -> RunDataInterface {
        return recordingsStore.newRunData()
    }

    /**
     Begin a new recording. Creates a new `Recording` instance and begins receiving data.
     */
    func start() {

        currentRecording = recordingsStore.newRecording()
        selectedRecording = currentRecording

        Logger.clear()
        EventLog.clear()

        currentRecording!.started()
        visualizer.visualize(dataSource: currentRecording!.runData)

        demoDriver?.start(runData: currentRecording!.runData)
    }

    /**
     Stops the current recording.
     */
    func stop() {
        demoDriver?.stop()
        guard let recording = self.currentRecording else { fatalError("*** nil recording") }
        recording.stopped(pdfRenderer: self.pdfRenderer)
        self.currentRecording = nil
        if recording.awaitingUpload {
            self.dropboxController.upload(recording: recording)
        }
    }

    /**
     Select a recording for viewing.
     - parameter recording: the `Recording` instance to show
     */
    func select(recording: Recording) {
        if selectedRecording != recording {
            selectedRecording = recording
            visualizer.visualize(dataSource: recording.runData)
            Logger.restore(from: recording.folder)
            EventLog.restore(from: recording.folder)
        }
    }

    /**
     Delete a recording.
     - parameter recording: the `Recording` instance to delete
     */
    func delete(recording: Recording) {
        if selectedRecording == recording {
            selectedRecording = nil
            let runData = newRunData()
            visualizer.visualize(dataSource: runData)
            Logger.clear()
            EventLog.clear()
        }
        recording.delete()
    }

    /**
     Upload recording assets to Dropbox.
     - parameter recording: the `Recording` instance to upload.
     */
    func upload(recording: Recording) {
        if !recording.uploading {
            recording.uploadingRequested()
            dropboxController.upload(recording: recording)
        }
    }
}
