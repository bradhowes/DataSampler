//
//  AppDelegate.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftyDropbox

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceToken: Data? = nil

    private var dropboxController: DropboxController!
    private var recordingsStore: RecordingsStoreInterface!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if launchOptions == nil || launchOptions!.count == 0 {

            // Normal execution
            //
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                print("-- requestAuthorization: \(granted) \(error)")
                if granted {
                    application.registerForRemoteNotifications()
                }
            }

            setupDependencies()
        }

        return true
    }

    /**
     Create various class instances to be used within the application. Scan for view controllers in our controller 
     graph that have dependent protocols, and inject the appropriate dependency.
     */
    func setupDependencies() {

        let userSettings = UserSettings()
        let recordingsStore = RecordingsStore(userSettings: userSettings, runDataFactory: RunData.MakeRunData)
        let dropboxController = DropboxController(userSettings: userSettings, recordingsStore: recordingsStore)
        let recordingActivityLogic = RecordingActivityLogic(store: recordingsStore, demoDriver: DemoDriver())

        guard let rvc = window?.rootViewController as? TabBarController else {
            fatalError("expected TabBarController as first view controller")
        }

        // Visit the tab view controllers and install any needed dependencies
        //
        rvc.childViewControllers.forEach { viewController in
            let injector = { (viewController: AnyObject) in

                // Unfortunately, I don't see any good way to do this 'as?' dynamically with types.
                //
                if let tmp = viewController as? UserSettingsDependent {
                    tmp.userSettings = userSettings
                }
                if let tmp = viewController as? RecordingsStoreDependent {
                    tmp.recordingsStore = recordingsStore
                }
                if let tmp = viewController as? DropboxControllerDependent {
                    tmp.dropboxController = dropboxController
                }
                if let tmp = viewController as? RecordingActivityLogicDependent {
                    tmp.recordingActivityLogic = recordingActivityLogic
                }
            }

            // Two of the views are hosted by a UINavigationController, so we have to special-case them.
            //
            if let tmp = viewController as? UINavigationController {
                injector(tmp.topViewController!)
            }
            else {
                injector(viewController)
            }
        }

        self.dropboxController = dropboxController
        self.recordingsStore = recordingsStore
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        self.dropboxController.handleRedirect(url: url)
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("-- registered")
        self.deviceToken = deviceToken
    }

    func applicationWillResignActive(_ application: UIApplication) {
        recordingsStore.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        recordingsStore.save()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        recordingsStore.save()
    }
}

