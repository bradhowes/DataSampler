//
//  DropboxControllerInterface.swift
//  DataSampler
//
//  Created by Brad Howes on 10/25/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

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

    /// Determine current linking status. Returns `true` if linked
    var isLinked: Bool { get }

    /**
     Toggle account linking with Dropbox.
     - parameter viewController: the currently active view controller when the link change request took place
     */
    func toggleAccountLinking(viewController: UIViewController)

    /**
     Request to upload a `Recording` instance. May not happen immediately.
     - parameter recording: the `Recording` instance to upload.
     */
    func upload(recording: Recording)
}

