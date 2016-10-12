//
//  ConfigurableCell.swift
//  Blah
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol ConfigurableCell: class {

    associatedtype DataSource

    func configure(dataSource: DataSource)
}
