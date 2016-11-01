//
//  Dependencies.swift
//  DataSampler
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import CoreData

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

    var isReady: Bool { get }

    func cannedFetchRequest(name: String) -> NSFetchedResultsController<Recording>
    func newRunData() -> RunDataInterface
    func newRecording() -> Recording
    func save()
}
