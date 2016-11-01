//
//  DataSource.swift
//  DataSampler
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol DataSourceDelegate: class {

    associatedtype Object

    func cellIdentifierFor(object: Object) -> String
}
