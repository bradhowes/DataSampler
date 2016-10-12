//
//  AppDelegate.swift
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import UserNotifications
import Dip
import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceToken: Data? = nil

    private var userSettings: UserSettings!
    private var dropboxController: DropboxController!
    private let recordingsStore: RecordingsStoreInterface = RecordingsStore()
    private let container = PassiveDependencyInjector.singleton

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

            self.userSettings = UserSettings()
            self.dropboxController = DropboxController(userSettings: userSettings, recordingsStore: recordingsStore)

            let pdi = PassiveDependencyInjector.singleton
            pdi.recordingsStore = recordingsStore
            pdi.recordingActivityLogic = RecordingActivityLogic(store: recordingsStore, demoDriver: DemoDriver())
            pdi.userSettings = self.userSettings
            pdi.dropboxController = self.dropboxController
            pdi.runDataGenerator = RunData.MakeRunData
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        self.dropboxController.handleRedirect(url: url)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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

