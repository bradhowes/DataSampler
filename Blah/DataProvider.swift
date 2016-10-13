//
//  DataProvider.swift
//  Blah
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol DataProvider: class {

    associatedtype Object

    func objectAtIndexPath(_ indexPath: IndexPath) -> Object
    func numberOfItemsInSection(_ section: Int) -> Int
}

protocol DataProviderDelegate: class {

    associatedtype Object

    func dataProviderDidUpdate(_ updates: [DataProviderUpdate<Object>]?)
}

enum DataProviderUpdate<Object> {

    case insert(IndexPath)
    case update(IndexPath, Object)
    case move(IndexPath, IndexPath)
    case delete(IndexPath)
}
