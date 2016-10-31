//
//  URL+Additions.swift
//  Blah
//
//  Created by Brad Howes on 10/30/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

extension URL {

    /**
     Obtain a unique, temporary URL.
     - returns: unique, temporary URL
     */
    static func temporary() -> URL {
        return try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil,
                                            create: true).appendingPathComponent(UUID().uuidString)
    }

    /// Obtain the location for all documents of the application.
    static var documents: URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                                            create: true)
    }
}
