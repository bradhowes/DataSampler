//
//  ConfigurableCell.swift
//  Blah
//
//  Created by Brad Howes on 10/28/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Defines interface for a UITableViewCell that can be configured
 */
protocol ConfigurableCell: class {

    associatedtype Model

    /**
     Configure a UITableViewCell
     - parameter activityHandler: object to handle the processing of any cell buttons
     */
    func configure(dataSource: Model, selected: Bool)
}
