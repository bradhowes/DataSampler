//
//  Dependencies.swift
//  Blah
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import JSQCoreDataKit
import CoreData

/**
 Interface for recorded run data.
 */
public protocol RunDataInterface {

    typealias FactoryType = (UserSettingsInterface) -> RunDataInterface

    /**
     Factory method which will create a new RunDataInterface instance
     - parameter userSettings: the UserSettings collection to use for configuration settings
     - returns: new RunData instance
     */
    static func MakeRunData(userSettings: UserSettingsInterface) -> RunDataInterface

    var name: String { get set }
    var startTime: Date { get set }

    var samples: [Sample] { get }
    var missing: [Sample] { get }
    var orderedSamples: OrderedArray<Sample> { get }
    var histogram: Histogram { get }

    var emitInterval: Int { get }
    var estArrivalInterval: Double { get }

    var minSample: Sample? { get }
    var maxSample: Sample? { get }

    func orderedSampleAt(index: Int) -> Sample?
    func recordLatency(sample: Sample)
}

/**
 Protocol for a class that is dependent on a `DropboxControllerInterface` instance
 */
public protocol DropboxControllerDependent: class {
    var dropboxController: DropboxControllerInterface! { get set }
}

/**
 Protocol for a class that implements the `DropboxController` interface.
 */
public protocol DropboxControllerInterface: class {
    func toggleAccountLinking(viewController: UIViewController)
}

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

/**
 Protocol for a class that is dependent on a `RecordingActivityLogicInterface` instance
 */
public protocol RecordingActivityLogicDependent: class {
    var recordingActivityLogic: RecordingActivityLogicInterface! { get set }
}

/** 
 Protocol for visualizing the contents of a recording.
 */
public protocol VisualizerInterface: class {
    /**
     Generate or update displays using the given data
     - parameter dataSource: data to visualize
     */
    func visualize(dataSource: RunDataInterface)
}

/**
 Protocol for a class that implements the `RecordingActivityLogic` interface.
 */
public protocol RecordingActivityLogicInterface: class {

    /// Entity that uses the contents of a recording for drawing.
    var visualizer: VisualizerInterface? { get set }

    /**
     Start recording a new experiment
     */
    func startRecording()

    /**
     Stop recording
     */
    func stopRecording()

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
}

/**
 Protocol for a class that is dependent on a `RecordingsStoreInterface` instance
 */
public protocol RecordingsStoreDependent: class {
    var recordingsStore: RecordingsStoreInterface! { get set }
}

/**
 Protocol for a class that implements the `RecordingsStore` interface.
 */
public protocol RecordingsStoreInterface: class {

    var stack: CoreDataStack? { get }
    var isReady: Bool { get }

    func cannedFetchRequest(name: String) -> NSFetchedResultsController<Recording>
    func newRunData() -> RunDataInterface
    func newRecording() -> Recording?
    func save()
}
