//
//  Dependencies.swift
//  Blah
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class PassiveDependencyInjector: NSObject {
    static var singleton: PassiveDependencyInjector = PassiveDependencyInjector()

    var recordingsStore: RecordingsStoreInterface!

    private override init() {
        super.init()
    }
}
