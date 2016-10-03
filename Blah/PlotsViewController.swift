//
//  FirstViewController.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

class PlotsViewController: UIViewController {

    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private var startButton: UIBarButtonItem!
    @IBOutlet private var stopButton: UIBarButtonItem!
    @IBOutlet private weak var histogramButton: UIBarButtonItem!
    @IBOutlet private weak var logButton: UIBarButtonItem!
    @IBOutlet private weak var eventsButton: UIBarButtonItem!

    @IBOutlet private weak var plotView: BRHLatencyByTimeGraph!
    @IBOutlet private weak var histogramView: BRHLatencyHistogramGraph!
    @IBOutlet private weak var logView: UITextView!
    @IBOutlet private weak var eventsView: UITextView!

    private var lowerViewManager = LowerViewManager()

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
         
         Creates a new LowerView instance and if successful inserts it into the array of managed views
         
         - parameter view: a UIView instance to manage
         - parameter button: the UIBarButtonItem associated with the view
         */
        mutating func add(view: UIView, button: UIBarButtonItem) throws {
            guard let value = LowerView(view: view, button: button) else { throw Failure.MissingConstraint }
            guard let key = Kind(rawValue: view.tag) else { throw Failure.InvalidTag }
            lowerViews[key] = value
        }

        /**
         Slide two views, the old one slides out while the new one slides it.
         
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
         Make a view active, sliding it into view.
         - parameter activate: the view to activate and slide in
         */
        mutating func slideVertically(activate: Kind) {
            let dir = activate.rawValue < active.rawValue ? LowerView.Direction.up : LowerView.Direction.down
            transition(activate: activate, dir: dir)
        }

        /**
         @brief Slide views horizontally

         @param index the view to make current
         */
        mutating func slideHorizontally(activate: Kind) {
            let dir = active.rawValue < activate.rawValue ? LowerView.Direction.left : LowerView.Direction.right
            transition(activate: activate, dir: dir)
        }
    }

    /**
     @brief A pairing of view and bar button which is managed by a LowerViewManager instance.
     
     Instances know how to slide themselves around horizontally and vertically in either direction.
     */
    struct LowerView {

        static let inactiveTint = UIColor(red: 10.0/255.0, green: 96.0/255.0, blue: 254.0/255.0, alpha: 1.0)
        static let activeTint = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha:1.0)

        enum Direction { case left, right, up, down }
 
        weak var view: UIView!
        weak var button: UIBarButtonItem!
        weak var top: NSLayoutConstraint!
        weak var bottom: NSLayoutConstraint!
        weak var left: NSLayoutConstraint!
        weak var right: NSLayoutConstraint!

        /**
         @brief Initialize new instance. Scans the constraints held by the parent view and records the ones that are
         useful for sliding purposes, namely:
         
         * top -- the constraint managing the top edge of the view
         * bottom -- the constraint managing the bottom edge of the view
         * leading -- the constraint managing the left edge of the view
         * trailing -- the constraint managing the right edge of the view
         
         @param view the UIView object to manage
         @param button the UIBarButtonItem that, when pressed, makes the linked UIView visible
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
                           completion: { _ in
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        plotView.layer.zPosition = 1_000
        do {
            try lowerViewManager.add(view: histogramView, button: histogramButton)
            try lowerViewManager.add(view: logView, button: logButton)
            try lowerViewManager.add(view: eventsView, button: eventsButton)
        } catch {
            print(error)
            abort()
        }

        if var items = toolbar.items {
            items.remove(at: 1)
            toolbar.setItems(items, animated:false)
        }

        plotView.source = AppDelegate.singleton().runData
        histogramView.source = AppDelegate.singleton().runData.histogram
        
        BRHLogger.sharedInstance().textView = logView
        BRHLogger.log("Hello world!")
        BRHEventLog.sharedInstance().textView = eventsView
        BRHEventLog.log("Hello", "world!")
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func activateLowerView(_ button: UIBarButtonItem) {
        lowerViewManager.slideHorizontally(activate: LowerViewManager.Kind(rawValue: button.tag)!)
    }

    @IBAction func startButtonPressed(_ button:UIBarButtonItem) {
        updateControlButton(stopButton)
    }

    @IBAction func stopButtonPressed(_ button:UIBarButtonItem) {
        updateControlButton(startButton)
    }
    
    private func updateControlButton(_ button: UIBarButtonItem) {
        if var items = toolbar.items {
            items[0] = button
            toolbar.setItems(items, animated:false)
        }
    }
}

