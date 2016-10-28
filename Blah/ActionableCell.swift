//
//  ConfigurableCell.swift
//  Blah
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

/** 
 Interface for a UITableViewCell-like instance that has buttons that perform actions.
 */
protocol ActionableCell: class {

    /// Property to hold instance which process actions for the cell.
    var actionHandler: ActionableCellHandler! { get set }

    /**
     Notification that whatever action took place is now complete.
     */
    func actionComplete()
}

/**
 Defines interface for an object that can respond to buttons in an `ActionableCell` instance.
 */
protocol ActionableCellHandler: class {

    /// Provide upload status
    func canPerform<T>(action: T, recording: Recording) -> Bool

    /**
     Process a request to share recording data
     - parameter cell: the cell that was swiped
     - parameter button: the button that was pressed
     - parameter recording: the recording to share
     - returns: true to dismiss the button
     */
    func performRequest<T>(action: T, cell: ActionableCell, button: UIView, recording: Recording) -> Bool
}
