//
//  SharingInterface.swift
//  Blah
//
//  Created by Brad Howes on 10/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol SharingDependent: class {
    var sharingManager: SharingInterface { get set }
}

protocol SharingInterface: class {
    func share(recording: Recording)
}
