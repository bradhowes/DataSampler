//
//  LowerViewManager.swift
//  DataSampler
//
//  Created by Brad Howes on 10/4/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

/**
 Inner struct that manages the lower view in the main view.

 Views have associated buttons that, when pressed, cause the associated view to be shown.
 There are currently two ways to reveal a view:

 * slideUpDown - vertically slide old/new views
 * slideLeftRight - horizontally slide old/new views

 If the pressed button has a tag value smaller than the previously shown view, then the direction of the sliding is
 down/up or right/left. If the the tag value is greater than the previously shown view, then the direction is
 opposite -- up/down or left/right

 */
struct LowerViewManager {

    enum Kind : Int {
        case histogram, log, events
    }

    /**
     Error indicator for when a managed view is missing a required layout constraint
     */
    enum Failure : Error {
        case MissingConstraint
        case InvalidTag
    }

    private var lowerViews = [Kind:LowerView]()
    private var active: Kind = .histogram

    /**
     Add a view/button pair to the managed collection.

     Creates a new `LowerView` instance and if successful inserts it into the array of managed views

     - parameter view: a `UIView` instance to manage
     - parameter button: the `UIBarButtonItem` associated with the view
     */
    mutating func add(view: UIView, button: UIBarButtonItem) throws {
        guard let value = LowerView(view: view, button: button) else { throw Failure.MissingConstraint }
        guard let key = Kind(rawValue: view.tag) else { throw Failure.InvalidTag }
        lowerViews[key] = value
    }

    /**
     Slide two views, the old one slides out while the new one slides in.
     - parameter activate: which view to slid in and make current
     - parameter dir: which direction to slide in
     */
    private mutating func transition(activate: Kind, dir: LowerView.Direction) {
        if activate == active { return }
        lowerViews[active]!.slide(dir: dir)
        active = activate
        lowerViews[active]!.slide(dir: dir)
    }

    /**
     Make a view active, sliding it vertically into view.
     - parameter activate: the view to activate and slide in
     */
    mutating func slideVertically(activate: Kind) {
        let dir = activate.rawValue < active.rawValue ? LowerView.Direction.up : LowerView.Direction.down
        transition(activate: activate, dir: dir)
    }

    /**
     Make a view active, sliding it vertically into view.
     - parameter activate: the view to activate and slide in
     */
    mutating func slideHorizontally(activate: Kind) {
        let dir = active.rawValue < activate.rawValue ? LowerView.Direction.left : LowerView.Direction.right
        transition(activate: activate, dir: dir)
    }

    /**
     Begin the sliding operation. Disable all bar button items until the sliding is done.
     */
    func beginSlide() {
        lowerViews.forEach { $0.value.enableButton(state: false) }
    }

    /**
     End the sliding operation. Enable all bar button items.
     */
    func endSlide() {
        lowerViews.forEach { $0.value.enableButton(state: true) }
    }
}
