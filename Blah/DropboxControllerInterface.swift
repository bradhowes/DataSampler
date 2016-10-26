//
//  DropboxControllerInterface.swift
//  Blah
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
    func toggleAccountLinking(viewController: UIViewController)
}

