//
//  SecondViewController.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import InAppSettingsKit

/** 
 Controller for the settings view. Does little more than present the view and update user settings.
 */
final class SettingsViewController : IASKAppSettingsViewController, IASKSettingsDelegate, DropboxControllerDependent, UserSettingsDependent {

    var dropboxController: DropboxControllerInterface!
    var userSettings: UserSettingsInterface!

    /**
     Customization point for view/controller after construction from storyboard
     */
    override func viewDidLoad() {
        self.delegate = self
        super.viewDidLoad()
    }

    /**
     Update in-memory settings from system's UserDefaults.
     - parameter animated: true if animated (ignored)
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userSettings.read()
    }

    /**
     Override of `IASKAppSettingsViewController` method. After synchronizing settings with UserDefaults, read the
     setting values into UserSettings properties.
     */
    override func synchronizeSettings() {
        super.synchronizeSettings()
        userSettings.read()
    }

    // - MARK: IASKAppSettingsDelegate Methods

    /**
     Notification from `IASKAppSettingsViewController` that the view controller is going away. NOTE: this does *not* 
     fire when the view is part of a tab bar, however we still must provide it in order to satisfy the 
     `IASKSettingsDelegate` protocol.
     - parameter sender: the view controller that ended (ignored)
     */
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {

    }

    /**
     Notification from `IASKAppSettingsViewController` that a custom button in the view was touched. Only one we have
     is for Dropbox linking.
     - parameter sender: the view controller sending the notification
     - parameter specifier: information about the button that was touched.
     */
    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        if specifier.key() == "dropboxLinkButtonText" {
            dropboxController.toggleAccountLinking(viewController: self)
        }
    }
}
