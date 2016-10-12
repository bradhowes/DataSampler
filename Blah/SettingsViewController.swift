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
final class SettingsViewController : IASKAppSettingsViewController, IASKSettingsDelegate {

    private var userSettings: UserSettingsInterface!
    private var dropboxController: DropboxController!

    /**
     Customization point for view/controller after construction from storyboard
     */
    override func viewDidLoad() {
        self.delegate = self
        userSettings = PassiveDependencyInjector.singleton.userSettings
        dropboxController = PassiveDependencyInjector.singleton.dropboxController

        updateLinkButtonText()

        UserSettingsChangedNotification.observe(observer: self, selector: #selector(doUpdateLinkButtonText),
                                                setting: UserSettingName.useDropbox)
        super.viewDidLoad()
    }

    func updateLinkButtonText() {
        UserDefaults.standard["dropboxLinkButtonText"] = userSettings.useDropbox ? "Unlink" : "Link"
        UserDefaults.standard.synchronize()
    }

    func doUpdateLinkButtonText(notification: NSNotification) {
        updateLinkButtonText()
    }

    /**
     Notification from system that memory is tight. Drop any data we can recreate elsewhere.
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Update NSUserDefaults values using values from Parameters class
     - parameter animated: true if the view should animate its appearance
     */
    override func viewWillAppear(_ animated: Bool) {
        // Just in case the settings changed since we last presented this view -- say from the iOS Settings app
        // userSettings.read()
        super.viewWillAppear(animated)

        // - NOTE: for some reason, we need this to remove ugly "jump" of the title when the appearance of the view
        // is controlled by a transition animation
        //
        navigationController?.navigationBar.layer.removeAllAnimations()
    }

    /**
     Update the Parameters class instances using values from NSUserDefaults
     - parameter animated: true if the view snould animate its disappearance
     */
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userSettings.read()
        userSettings.dump()
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {
        userSettings.read()
        userSettings.dump()
    }

    override func synchronizeSettings() {
        super.synchronizeSettings()
        userSettings.read()
        updateLinkButtonText()
        tableView.reloadData()
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        if specifier.key() == "dropboxLinkButtonText" {
            dropboxController.toggle(viewController: self)
        }
    }
}
