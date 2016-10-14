//
//  FirstViewController.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

/** 
 The main view controller for the app. The view is split in two, with the upper-half showing an XY scatter plot and the
 lower-half showing one of three views:
 
 * histogram of sample values
 * log view
 * events view

 */
final class PlotsViewController: UIViewController, RecordingActivityLogicDependent {

    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private var startButton: UIBarButtonItem!
    @IBOutlet private var stopButton: UIBarButtonItem!
    @IBOutlet private weak var histogramButton: UIBarButtonItem!
    @IBOutlet private weak var logButton: UIBarButtonItem!
    @IBOutlet private weak var eventsButton: UIBarButtonItem!

    @IBOutlet private(set) weak var plotView: GraphLatencyByTime!
    @IBOutlet private(set) weak var histogramView: GraphLatencyHistogram!
    @IBOutlet private weak var logView: UITextView!
    @IBOutlet private weak var eventsView: UITextView!

    /// Current recording being shown in the display
    private var viewedRecording: Recording?

    /// Injected dependency for managing recordings
    var recordingActivityLogic: RecordingActivityLogicInterface!

    /// Show the status bar with white text
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    /// The manager controlling the lower views
    private var lowerViewManager = LowerViewManager()

    /**
     Instance's view is ready and linked with the controller. Setup management of the lower views.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        recordingActivityLogic.visualizer = self

        histogramButton.accessibilityLabel = "Histogram"
        logButton.accessibilityLabel = "Log"
        eventsButton.accessibilityLabel = "Events"

        // Add lower views to the LowerViewManager so we can properly slide them in/out
        //
        do {
            try lowerViewManager.add(view: histogramView, button: histogramButton)
            try lowerViewManager.add(view: logView, button: logButton)
            try lowerViewManager.add(view: eventsView, button: eventsButton)
        } catch {
            print(error)
            abort()
        }

        // Remove the 'stop' button from the toolbar
        //
        var items = toolbar.items!
        items.remove(at: 1)
        toolbar.setItems(items, animated: false)

        // Attach the Logger and EventLog to their respective text views
        //
        Logger.singleton.textView = logView
        EventLog.singleton.textView = eventsView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**
     Change the toolbar to show the right start/stop button
     - parameter button: the button to show
     */
    private func setStartStopButton(_ button: UIBarButtonItem) {
        if var items = toolbar.items {
            items[0] = button
            toolbar.setItems(items, animated: true)
        }
    }

    /**
     Activate a new lower view due to a button press. 
     The UIBarButtonItem must have a unique tag value which indicates the view to show.
     - parameter button: the button that was pressed
     */
    @IBAction func activateLowerView(_ button: UIBarButtonItem) {
        lowerViewManager.slideHorizontally(activate: LowerViewManager.Kind(rawValue: button.tag)!)
    }

    /**
     Start recording.
     - parameter button: the button that was pressed
     */
    @IBAction func startButtonPressed(_ button:UIBarButtonItem) {
        setStartStopButton(stopButton)
        recordingActivityLogic.startRecording()
    }

    /**
     Stop recording.
     - parameter button: button that was pressed
     */
    @IBAction func stopButtonPressed(_ button:UIBarButtonItem) {
        setStartStopButton(startButton)
        recordingActivityLogic.stopRecording()
    }
}

extension PlotsViewController: VisualizerInterface {
    func visualize(dataSource: RunDataInterface) {
        self.plotView.source = dataSource
        self.histogramView.source = dataSource.histogram
    }
}
