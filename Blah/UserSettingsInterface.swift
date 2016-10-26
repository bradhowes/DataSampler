//
//  UserSettingsInterface.swift
//  Blah
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

    var notificationDriver: String { get set }
    var emitInterval: Int { get set }
    var maxHistogramBin: Int { get set }
    var useDropbox: Bool { get set }
    var dropboxLinkButtonText: String { get }
    var uploadAutomatically: Bool { get set }
    var remoteServerName: String { get set }
    var remoteServerPort: Int { get set }
    var resendUntilFetched: Bool { get set }
    var apnsProdCertFileName: String { get set }
    var apnsProdCertPassword: String { get set }
    var apnsDevCertFileName: String { get set }
    var apnsDevCertPassword: String { get set }

    var count: Int { get }

    func dump()
    func read()
    func write()
}

