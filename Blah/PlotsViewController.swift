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

    @IBOutlet private weak var plotView: GraphLatencyByTime!
    @IBOutlet private weak var histogramView: GraphLatencyHistogram!
    @IBOutlet private weak var logView: UITextView!
    @IBOutlet private weak var eventsView: UITextView!

    private var lowerViewManager = LowerViewManager()
    private var recording: Recording?

    private var demoTimer: Timer?

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

        plotView.source = AppDelegate.singleton.runData
        histogramView.source = AppDelegate.singleton.runData.histogram
        
        Logger.singleton.textView = logView
        Logger.log("Hello world!")
        EventLog.singleton.textView = eventsView
        EventLog.log("Hello", "world!")
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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

    @IBAction func startButtonPressed(_ button:UIBarButtonItem) {
        updateControlButton(stopButton)

        let now = Date()
        recording = RecordingsStore.singleton.newRecording(startTime: now)
        AppDelegate.singleton.runData.begin(startTime: now)

        Logger.clear()
        EventLog.clear()

        RecordingsStore.singleton.save()

        let rnd = BRHRandomUniform()
        var identifier = 1
        var elapsed = now

        // Create timer to continue to add synthesized data
        //
        demoTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            elapsed = elapsed.addingTimeInterval(2.0)
            let emissionTime = elapsed
            let latency = rnd.uniform(lower: 0.5, upper: 10.0) *
                (rnd.uniform(lower: 0.0, upper: 1.0) > 0.95 ? rnd.uniform(lower: 2.0, upper: 10.0) : 1.0)
            elapsed = elapsed.addingTimeInterval(latency)
            let arrivalTime = elapsed
            if rnd.uniform(lower: 0.0, upper: 1.0) > 0.1 {
                let sample = LatencySample(identifier: identifier, latency: latency,
                                           emissionTime: emissionTime,
                                           arrivalTime: arrivalTime,
                                           medianLatency: 0.0, averageLatency: 0.0)
                AppDelegate.singleton.runData.recordLatency(sample: sample)
            }
            identifier += 1
        }

        plotView.redraw()
        histogramView.redraw()
    }

    @IBAction func stopButtonPressed(_ button:UIBarButtonItem) {
        demoTimer?.invalidate()
        updateControlButton(startButton)
        recording?.finished(runData: AppDelegate.singleton.runData)
        RecordingsStore.singleton.save()
        recording = nil
    }

    private func updateControlButton(_ button: UIBarButtonItem) {
        if var items = toolbar.items {
            items[0] = button
            toolbar.setItems(items, animated:false)
        }
    }
}
