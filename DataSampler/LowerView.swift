//
//  LowerView.swift
//  DataSampler
//
//  Created by Brad Howes on 10/4/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

/**
 A pairing of view and bar button which is managed by a `LowerViewManager` instance.
 Instances know how to slide themselves around horizontally and vertically in either direction.
 */
struct LowerView {

    static let inactiveTint = UIColor(red: 10.0/255.0, green: 96.0/255.0, blue: 254.0/255.0, alpha: 1.0)
    static let activeTint = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha:1.0)

    enum Direction { case left, right, up, down }

    private(set) weak var view: UIView!
    private(set) weak var button: UIBarButtonItem!
    private weak var top: NSLayoutConstraint!
    private weak var bottom: NSLayoutConstraint!
    private weak var left: NSLayoutConstraint!
    private weak var right: NSLayoutConstraint!

    /**
     Initialize new instance. Scans the constraints held by the parent view and records the ones that are
     useful for sliding purposes, namely:

     * top -- the constraint managing the top edge of the view
     * bottom -- the constraint managing the bottom edge of the view
     * leading -- the constraint managing the left edge of the view
     * trailing -- the constraint managing the right edge of the view

     - parameter view: the `UIView` object to manage
     - parameter button: the `UIBarButtonItem` that, when pressed, makes the linked `UIView` visible
     */
    init?(view: UIView, button: UIBarButtonItem) {
        guard let constraints = view.superview?.constraints else { return nil }
        self.view = view
        self.button = button

        // Is there an easier, less verbose way of doing this?
        //
        constraints.forEach {
            if $0.firstItem === view {
                switch $0.firstAttribute {
                case .top: self.top = $0
                case .bottom: self.bottom = $0
                case .leading: self.left = $0
                case .trailing: self.right = $0
                default: break
                }
            }
            else if $0.secondItem === view {
                switch $0.secondAttribute {
                case .top: self.top = $0
                case .bottom: self.bottom = $0
                case .leading: self.left = $0
                case .trailing: self.right = $0
                default: break
                }
            }
        }
    }

    /**
     Slide the view in the direction managed by the given constraints. Uses Core Animation to show the
     view sliding in/out. The direction of the sliding is determined by the ordering of the constraints, and
     whether the view slides into or out of view depends on the visibility of the view:

     - `isHidden == true`: slide in (make visible)
     - `isHidden == false`: slide out (make invisible)

     - parameter a: the constraint for left or top
     - parameter b: the constraint for right or bottom
     */
    private func slide(from: NSLayoutConstraint, to: NSLayoutConstraint) {
        let slidingIn = view.isHidden
        let offset = from === left || from === right ? view.frame.size.width : view.frame.size.height

        // Start state
        //
        if slidingIn {
            to.constant = offset
            from.constant = -offset
            view.superview?.layoutIfNeeded()
        }

        // End state
        //
        if slidingIn {
            to.constant = 0
            from.constant = 0
            view.isHidden = false
        }
        else {
            to.constant = -offset
            from.constant = offset
        }

        // Animate transition from start to end state
        //
        UIView.animate(withDuration: 0.25,
                       animations: { self.view.superview?.layoutIfNeeded() },
                       completion: { finished in
                        if !finished {
                            print("*** animation cancelled")
                        }
                        self.view.superview?.layoutIfNeeded()
                        self.view.isHidden = !slidingIn
                        self.button.tintColor = slidingIn ? LowerView.activeTint : LowerView.inactiveTint
        })
    }

    /**
     Slide the view in the given direction. If the view is visible, slide it out. Otherwise, slide it out.
     - parameter dir: the dirction to slide
     */
    func slide(dir: Direction) {
        switch dir {
        case .left: slide(from: right, to: left)
        case .right: slide(from: left, to: right)
        case .up: slide(from: bottom, to: top)
        case .down: slide(from: top, to: bottom)
        }
    }

    /**
     Change the enabled state of the tool bar button for the view.
     - parameter state: true if enabled
     */
    func enableButton(state: Bool) {
        self.button.isEnabled = state
    }
}

