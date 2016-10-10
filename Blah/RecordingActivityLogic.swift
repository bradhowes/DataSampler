//
//  ActivityLogic.swift
//  Blah
//
//  Created by Brad Howes on 10/10/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol RecordingActivityLogicInterface {
    func startRecording(userSettings: UserSettingsInterface, runData: RunDataInterface) -> Recording
    func stopRecording()
    func delete(recording: Recording)
    func select(recording: Recording)
}

class RecordingActivityLogic: NSObject, RecordingActivityLogicInterface {

    private let recordingsStore: RecordingsStoreInterface
    private var currentRecording: Recording?
    private var demoDriver: DriverInterface

    init(store: RecordingsStoreInterface, demoDriver: DriverInterface) {
        self.recordingsStore = store
        self.demoDriver = demoDriver
        super.init()
    }

    func startRecording(userSettings: UserSettingsInterface, runData: RunDataInterface) -> Recording {

        // Create a new Recording instance for the data we will gather
        //
        currentRecording = recordingsStore.newRecording(userSettings: userSettings, runData: runData)!

        Logger.clear()
        EventLog.clear()

        demoDriver.start(runData: currentRecording!.runData)

        return currentRecording!
    }

    func stopRecording() {
        currentRecording!.finished()
        currentRecording = nil
        demoDriver.stop()
    }

    func delete(recording: Recording) {
        Logger.clear()
        EventLog.clear()
    }

    func select(recording: Recording) {
        Logger.restore(from: recording.folder)
        EventLog.restore(from: recording.folder)
    }
}
