//
//  SecondViewController.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import InAppSettingsKit

class SettingsViewController : IASKAppSettingsViewController, IASKSettingsDelegate {

    override func viewDidLoad() {
        self.delegate = self
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Update NSUserDefaults values using values from Parameters class
     
     - parameter animated: true if the view should animate its appearance
     */
    override func viewWillAppear(_ animated: Bool) {
        // Just in case the settings changed since we last presented this view -- say from the iOS Settings app
        UserSettings.singleton.syncFromUserDefaults()
        super.viewWillAppear(animated)
    }

    /**
     Update the Parameters class instances using values from NSUserDefaults
     
     - parameter animated: true if the view snould animate its disappearance
     */
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UserSettings.singleton.syncFromUserDefaults()
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {
        print("-- settingsViewControllerDidEnd")
    }
}

