//
//  ActivityLogic.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol RecordingActivityLogicInterface {

    var visualizer: VisualizerInterface? { get set }

    func startRecording()
    func stopRecording()
    func delete(recording: Recording)
    func select(recording: Recording)
}

final class RecordingActivityLogic: NSObject, RecordingActivityLogicInterface {

    var visualizer: VisualizerInterface? {
        didSet {
            visualizer?.visualize(dataSource: newRunData())
        }
    }

    private let recordingsStore: RecordingsStoreInterface
    private var demoDriver: DriverInterface
    private var currentRecording: Recording?
    private var selectedRecording: Recording?

    init(store: RecordingsStoreInterface, demoDriver: DriverInterface) {
        self.recordingsStore = store
        self.demoDriver = demoDriver
        super.init()

        // Begin observing notifications from the RecordingsTableViewController for when a recording is deleted or
        // selected there.
        //
        observeRecordingsTableNotifications()
    }

    /**
     Begin watching for notifications from the RecordingsTableViewController
     */
    private func observeRecordingsTableNotifications() {
        RecordingsTableNotification.observe(kind: .recordingSelected, observer: self,
                                            selector: #selector(recordingSelected))
        RecordingsTableNotification.observe(kind: .recordingDeleted, observer: self,
                                            selector: #selector(recordingDeleted))
    }

    private func newRunData() -> RunDataInterface {
        return recordingsStore.newRunData()
    }

    func startRecording() {

        // Create a new Recording instance for the data we will gather
        //
        currentRecording = recordingsStore.newRecording()!
        selectedRecording = currentRecording
        Logger.clear()
        EventLog.clear()
        visualizer?.visualize(dataSource: currentRecording!.runData)
        demoDriver.start(runData: currentRecording!.runData)
    }

    func stopRecording() {
        demoDriver.stop()
        currentRecording!.finished()
        RecordingActivityLogicNotification.post(recording: currentRecording!)
        currentRecording = nil
    }

    func select(recording: Recording) {
        if selectedRecording != recording {
            selectedRecording = recording
            visualizer?.visualize(dataSource: recording.runData)
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
    }

    /**
     Handle the `recordingSelected` notification. Switch various views to show the selected Recording instance.
     - parameter notification: received notification
     */
    func recordingSelected(notification: Notification) {
        select(recording: RecordingsTableNotification(notification: notification).recording)
    }

    /**
     Handle the `recordingDeleted` notification. If the Recording being deleted is what is currently installed, then
     install an empty RunData.
     - parameter notification: received notification
     */
    func recordingDeleted(notification: Notification) {
        delete(recording: RecordingsTableNotification(notification: notification).recording)
    }
}
