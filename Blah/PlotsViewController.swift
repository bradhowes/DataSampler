//
//  FirstViewController.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

final class PlotsViewController: UIViewController {

    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private var startButton: UIBarButtonItem!
    @IBOutlet private var stopButton: UIBarButtonItem!
    @IBOutlet private weak var histogramButton: UIBarButtonItem!
    @IBOutlet private weak var logButton: UIBarButtonItem!
    @IBOutlet private weak var eventsButton: UIBarButtonItem!

    @IBOutlet private weak var plotView: GraphLatencyByTime!
    @IBOutlet private weak var histogramView: GraphLatencyHistogram!
    @IBOutlet private weak var logView: UITextView!
    @IBOutlet private weak var eventsView: UITextView!

    private var viewedRecording: Recording?

    private var recordingsStore: RecordingsStoreInterface!
    private var recordingActivityLogic: RecordingActivityLogicInterface!
    private var userSettings: UserSettingsInterface!

    private var runDataGenerator: ((UserSettingsInterface) -> RunDataInterface)!

    /// Show the status bar with white text
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    /// The manager controlling the lower views
    private var lowerViewManager = LowerViewManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recordingsStore = PassiveDependencyInjector.singleton.recordingsStore
        self.recordingActivityLogic = PassiveDependencyInjector.singleton.recordingActivityLogic
        self.userSettings = PassiveDependencyInjector.singleton.userSettings
        self.runDataGenerator = PassiveDependencyInjector.singleton.runDataGenerator

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
        Logger.log("Hello world!")
        EventLog.singleton.textView = eventsView
        EventLog.log("Hello", "world!")

        // Be a delegate for the tab bar in order to show a UIView transition when switching tabs
        //
        tabBarController!.delegate = self

        // Begin observing notifications from the RecordingsTableViewController
        //
        observeRecordingsTableNotifications()

        clear()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

        let runData = self.runDataGenerator(userSettings)
        viewedRecording = recordingActivityLogic.startRecording(userSettings: userSettings, runData: runData)
        plotView.source = viewedRecording!.runData
        histogramView.source = viewedRecording!.runData.histogram
    }

    /**
     Stop recording.
     - parameter button: button that was pressed
     */
    @IBAction func stopButtonPressed(_ button:UIBarButtonItem) {
        setStartStopButton(startButton)
        recordingActivityLogic.stopRecording()
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
     Begin watching for notifications from the RecordingsTableViewController
     */
    private func observeRecordingsTableNotifications() {
        RecordingsTableNotification.observe(kind: .recordingSelected, observer: self,
                                            selector: #selector(recordingSelected))
        RecordingsTableNotification.observe(kind: .recordingDeleted, observer: self,
                                            selector: #selector(recordingDeleted))
    }

    /**
     Handle the `recordingSelected` notification. Switch various views to show the selected Recording instance.
     - parameter notification: received notification
     */
    func recordingSelected(notification: Notification) {
        let recording = RecordingsTableNotification(notification: notification).recording
        if recording !== viewedRecording {
            viewedRecording = recording
            plotView.source = recording.runData
            histogramView.source = recording.runData.histogram
            recordingActivityLogic.select(recording: recording)
        }
    }

    /**
     Handle the `recordingDeleted` notification. If the Recording being deleted is what is currently installed, then
     install an empty RunData.
     - parameter notification: received notification
     */
    func recordingDeleted(notification: Notification) {
        let recording = RecordingsTableNotification(notification: notification).recording
        if recording === viewedRecording {
            viewedRecording = nil
            clear()
            recordingActivityLogic.delete(recording: recording)
        }
    }

    private func clear() {
        let runData = self.runDataGenerator(userSettings)
        plotView.source = runData
        histogramView.source = runData.histogram
    }
}

extension PlotsViewController: UITabBarControllerDelegate {

    /**
     Switching to another tab. Use a transition animation between the views.
     - parameter tabBarController: the UITabBarController to work with
     - parameter viewController: the UIViewController that will become active
     - returns: true to switch to the new view
     */
    public func tabBarController(_ tabBarController: UITabBarController,
                                 shouldSelect viewController: UIViewController) -> Bool {

        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView: UIView = viewController.view
        guard fromView != toView else { return false }
        UIView.transition(from: fromView, to: toView, duration: 0.25, options: [.transitionCrossDissolve]) {
            (finished: Bool) in
        }

        return true
    }

}

