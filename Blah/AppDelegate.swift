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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceToken: Data? = nil

    private var recordingsStore: RecordingsStoreInterface = RecordingsStore()
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

            PassiveDependencyInjector.singleton.recordingsStore = self.recordingsStore
        }
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

