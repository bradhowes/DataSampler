//
//  AppNotifications.swift
//  Blah
//
//  Created by Brad Howes on 10/7/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

struct RecordingActivityLogicNotification {
    static let finished = Notification.Name("RecordingActivityLogic.finished")
    let recording: Recording

    init(recording: Recording) {
        self.recording = recording
    }

    init(notification: Notification) {
        self.recording = notification.object as! Recording
    }

    private func post() {
        let notif = Notification(name: RecordingActivityLogicNotification.finished, object: self.recording)
        NotificationCenter.default.post(notif)
    }

    static func post(recording: Recording) {
        RecordingActivityLogicNotification(recording: recording).post()
    }

    static func observe(observer: AnyObject, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector,
                                               name: RecordingActivityLogicNotification.finished, object: nil)
    }

    static func unobserve(observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: RecordingActivityLogicNotification.finished,
                                                  object: nil)
    }
}

struct RecordingsStoreNotification {
    static let ready = Notification.Name("RecordingsStore.ready")

    let recordingsStore: RecordingsStoreInterface
    init(recordingsStore: RecordingsStoreInterface) {
        self.recordingsStore = recordingsStore
    }

    init(notification: Notification) {
        self.recordingsStore = notification.object as! RecordingsStoreInterface
    }

    private func post() {
        let notif = Notification(name: RecordingsStoreNotification.ready, object: self.recordingsStore)
        NotificationCenter.default.post(notif)
    }

    static func post(recordingStore: RecordingsStoreInterface) {
        RecordingsStoreNotification(recordingsStore: recordingStore).post()
    }

    static func observe(observer: AnyObject, selector: Selector, recordingStore: RecordingsStoreInterface) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: RecordingsStoreNotification.ready,
                                               object: recordingStore)
    }

    static func unobserve(observer: AnyObject, recordingStore: RecordingsStoreInterface) {
        NotificationCenter.default.removeObserver(observer, name: RecordingsStoreNotification.ready,
                                                  object: recordingStore)
    }
}

struct RecordingsTableNotification {

    enum Kind: String {
        case recordingSelected, recordingDeleted
    }

    let recording: Recording

    init(recording: Recording) {
        self.recording = recording
    }

    init(notification: Notification) {
        self.recording = notification.userInfo!["recording"] as! Recording
    }

    private func post(kind: Kind) {
        let notif = Notification(name: Notification.Name(kind.rawValue), object: self,
                                 userInfo: ["recording": recording])
        NotificationCenter.default.post(notif)
    }

    static func post(kind: Kind, recording: Recording) {
        RecordingsTableNotification(recording: recording).post(kind: kind)
    }

    static func observe(kind: Kind, observer: AnyObject, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector,
                                               name: Notification.Name(kind.rawValue), object: nil)
    }

    static func unobserve(kind: Kind, observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: Notification.Name(kind.rawValue), object: nil)
    }
}

/**
 Manager for the newSample notification from RunData.
 */
struct RunDataNewSampleNotification {

    static let newSample = Notification.Name("RunData.newSample")

    /// The sample that arrived
    let sample: Sample
    /// The index of the sample
    let index: Int

    /**
     Construct new instance in preparation for sending a notification.
     - parameter sample: the sample to send
     - parameter index: the index of the sample being sent
     */
    init(sample: Sample, index: Int) {
        self.sample = sample
        self.index = index
    }

    /**
     Construct new instance using info from Notification payload.
     - parameter notification: the notification to unpack
     */
    init(notification: Notification) {
        let userInfo = notification.userInfo!
        self.sample = userInfo["sample"] as! Sample
        self.index = (userInfo["index"] as! NSNumber).intValue
    }

    /**
     Post a newSample notification containing property values
     - parameter sender: the RunData instance responsible for the notification
     */
    private func post(sender: RunDataInterface) {
        let notif = Notification(name: RunDataNewSampleNotification.newSample, object: sender,
                                 userInfo: ["sample": sample, "index": NSNumber(value: index)])
        NotificationCenter.default.post(notif)
    }

    /**
     Post a newSample notification containing the given values
     - parameter sender: the RunData instance responsible for the notification
     - parameter sample: the sample to send
     - parameter index: the index of the sample being sent
     */
    static func post(sender: RunDataInterface, sample: Sample, index: Int) {
        RunDataNewSampleNotification(sample: sample, index: index).post(sender: sender)
    }

    /**
     Add an observer for newSample notifications
     - parameter from: the RunData instance to observe
     - parameter observer: the object to notify when a newSample notification fires
     - parameter selector: the observer's method to call to process the notification
     */
    static func observe(from: RunDataInterface, observer: AnyObject, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: newSample, object: from)
    }

    /**
     Remove an observer from newSample notifications
     - parameter from: the RunData instance that was being observed
     - parameter observer: the object that was observing
     */
    static func unobserve(from: RunDataInterface, observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: newSample, object: from)
    }
}

struct HistogramBinChangedNotification {

    static let binChanged = Notification.Name("Histogram.binChanged")

    let index: Int

    init(index: Int) {
        self.index = index
    }

    init(notification: Notification) {
        self.index = (notification.userInfo!["index"] as! NSNumber).intValue
    }

    private func post(sender: Histogram) {
        let notif = Notification(name: HistogramBinChangedNotification.binChanged, object: sender,
                                 userInfo: ["index": NSNumber(value: index)])
        NotificationCenter.default.post(notif)
    }

    static func post(sender: Histogram, index: Int) {
        HistogramBinChangedNotification(index: index).post(sender: sender)
    }

    static func observe(from: Histogram, observer: AnyObject, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: binChanged, object: from)
    }

    static func unobserve(from: Histogram, observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: binChanged, object: from)
    }
}

struct UserSettingsChangedNotification {
    static let settingChanged = "UserSettings.settingChanged."
    static func notificationName(setting: UserSettingName) -> Notification.Name {
        return Notification.Name(settingChanged + setting.rawValue)
    }

    static func observe(observer: AnyObject, selector: Selector, setting: UserSettingName) {
        NotificationCenter.default.addObserver(observer, selector: selector,
                                               name: notificationName(setting: setting), object: nil)
    }

    static func unobserve(observer: AnyObject, setting: UserSettingName) {
        NotificationCenter.default.removeObserver(observer,
                                                  name: notificationName(setting: setting),
                                                  object: nil)
    }
}

struct UserSettingsChangedNotificationWith<ValueType> {

    let name: UserSettingName
    let oldValue: ValueType
    let newValue: ValueType

    init(name: UserSettingName, oldValue: ValueType, newValue: ValueType) {
        self.name = name
        self.oldValue = oldValue
        self.newValue = newValue
    }

    init(notification: Notification) {
        self.name = UserSettingName(rawValue: (notification.userInfo!["name"]) as! String)!
        self.oldValue = (notification.userInfo!["oldValue"]) as! ValueType
        self.newValue = (notification.userInfo!["newValue"]) as! ValueType
    }

    func post(sender: SettingInterface) {
        let notif = Notification(name: UserSettingsChangedNotification.notificationName(setting: name),
                                 object: sender,
                                 userInfo: ["oldValue": oldValue, "newValue": newValue, "name": name.rawValue])
        NotificationCenter.default.post(notif)
    }
}
