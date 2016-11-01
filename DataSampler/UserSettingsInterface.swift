//
//  UserSettingsInterface.swift
//  DataSampler
//
//  Created by Brad Howes on 10/25/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for a class that is dependent on a `UserSettingsInterface` instance
 */
public protocol UserSettingsDependent: class {
    var userSettings: UserSettingsInterface! { get set }
}

/**
 Protocol for a class that implements the `UserSettings` interface.
 */
public protocol UserSettingsInterface: class {

    /// The driver to use for generating notifications
    var notificationDriver: String { get set }

    /// The interval in seconds between notification requests
    var emitInterval: Int { get set }

    /// The number of bars in the histogram bar chart
    var maxHistogramBin: Int { get set }

    /// If true, support uploading to Dropbox
    var useDropbox: Bool { get set }

    /// Text to show in Dropbox link button (depends on current linked state)
    var dropboxLinkButtonText: String { get }

    /// If true, automatically upload finished recordings
    var uploadAutomatically: Bool { get set }

    /// Name of remote server that will generate notifications
    var remoteServerName: String { get set }

    /// Port of remote server for service that will generate notifications
    var remoteServerPort: Int { get set }

    /// If true, keep requesting a notification until one is received by app
    var resendUntilFetched: Bool { get set }

    /// The filename for the APNs production certificate
    var apnsProdCertFileName: String { get set }

    /// The password for the APNs production certificate
    var apnsProdCertPassword: String { get set }

    /// The filename for the APNs developement certificate
    var apnsDevCertFileName: String { get set }

    /// The password for the APNs developement certificate
    var apnsDevCertPassword: String { get set }

    /// The number of user settings
    var count: Int { get }

    /**
     Dump out current setting keys/values to console
     */
    func dump()

    /**
     Read setting values from UserDefaults
     */
    func read()

    /**
     Update UserDefaults with current setting values
     */
    func write()
}

