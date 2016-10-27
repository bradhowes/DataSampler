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
final class RecordingActivityLogic: NSObject, RecordingActivityLogicInterface, PDFRenderingDependent {

    /// Object that can render the graphs using `Recording` data.
    weak var visualizer: VisualizerInterface? {
        didSet {
            visualizer?.visualize(dataSource: newRunData())
        }
    }

    /// Object that can generate a PDF of the graphs using `Recording` data.
    weak var pdfRenderer: PDFRenderingInterface!

    /// Returns `true` when `Recording` instances can be uploaded to Dropbox
    var canUpload: Bool { return dropboxController.isLinked }

    private let recordingsStore: RecordingsStoreInterface
    private let dropboxController: DropboxControllerInterface
    private let demoDriver: DriverInterface

    private var currentRecording: Recording?
    private var selectedRecording: Recording?

    init(store: RecordingsStoreInterface, dropboxController: DropboxControllerInterface, demoDriver: DriverInterface) {
        self.recordingsStore = store
        self.dropboxController = dropboxController
        self.demoDriver = demoDriver
        super.init()
    }

    private func newRunData() -> RunDataInterface {
        return recordingsStore.newRunData()
    }

    func start() {
        currentRecording = recordingsStore.newRecording()
        if currentRecording == nil {
            fatalError("failed to create new Recording")
        }

        selectedRecording = currentRecording
        Logger.clear()
        EventLog.clear()
        visualizer?.visualize(dataSource: currentRecording!.runData)
        demoDriver.start(runData: currentRecording!.runData)
    }

    func stop() {
        demoDriver.stop()
        guard let recording = self.currentRecording else { return }
        recording.stopped(pdfRenderer: self.pdfRenderer)
        self.currentRecording = nil
        if recording.awaitingUpload {
            self.dropboxController.upload(recording: recording)
        }
    }

    func select(recording: Recording) {
        if selectedRecording != recording {
            selectedRecording = recording
            visualizer?.visualize(dataSource: recording.runData)
            // pdfRenderer.render(recording: recording) // !!!
            Logger.restore(from: recording.folder)
            EventLog.restore(from: recording.folder)
        }
    }

    func delete(recording: Recording) {
        if selectedRecording == recording {
            selectedRecording = nil
            let runData = newRunData()
            visualizer?.visualize(dataSource: runData)
            Logger.clear()
            EventLog.clear()
        }
        recording.delete()
    }

    func share(recording: Recording) {

    }

    func upload(recording: Recording) {
        if !recording.uploading {
            recording.uploadingRequested()
            dropboxController.upload(recording: recording)
        }
    }
}
