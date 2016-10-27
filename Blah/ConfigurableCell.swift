//
//  ConfigurableCell.swift
//  Blah
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

protocol CellActivityHandler: class {
    var canUpload: Bool { get }

    func shareRequest(button: UIButton, recording: Recording)
    func uploadRequest(button: UIButton, recording: Recording)
    func deleteRequest(button: UIButton, recording: Recording)
}

protocol ConfigurableCell: class {

    associatedtype DataSource

    func configure(dataSource: DataSource, activityHandler: CellActivityHandler)
}
