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

    override func viewWillDisappear(_ animated: Bool) {
        userSettings.read()
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {
        print("heool")
    }

    override func synchronizeSettings() {
        super.synchronizeSettings()
        userSettings.read()
        // tableView.reloadData()
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        if specifier.key() == "dropboxLinkButtonText" {
            dropboxController.toggleAccountLinking(viewController: self)
        }
    }
}
