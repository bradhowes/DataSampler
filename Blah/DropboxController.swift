//
//  DropboxController.swift
//  Blah
//
//  Created by Brad Howes on 10/11/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import SwiftyDropbox
import CoreData

class DropboxController: NSObject {

    private var userSettings: UserSettingsInterface
    private var recordingsStore: RecordingsStoreInterface
    private var fetcher: NSFetchedResultsController<Recording>?
    private var client: DropboxClient?
    private var recording: Recording?

    init(userSettings: UserSettingsInterface, recordingsStore: RecordingsStoreInterface) {
        self.userSettings = userSettings
        self.recordingsStore = recordingsStore
        super.init()

        RecordingsStoreNotification.observe(observer: self, selector: #selector(storeIsReady),
                                            recordingStore: self.recordingsStore)
        DropboxClientsManager.setupWithAppKey("8dg497axhy58ypa")

        if recordingsStore.isReady {
            makeClient()
        }

    }

    func storeIsReady(notification: Notification) {
        makeClient()
    }

    func nextRecordingToUpload() -> Recording? {
        return fetcher?.fetchedObjects?.first(where: { (recording) -> Bool in
            if recording.uploaded == true { return false }
            if recording.isRecording == true { return false }
            return recording.awaitingUpload
        })
    }

    func makeClient() {

        self.fetcher = recordingsStore.cannedFetchRequest(name: "uploadable")
        if fetcher?.fetchedObjects == nil {
            do {
                try fetcher?.performFetch()
            } catch {
                assertionFailure("Failed to fetch: \(error)")
            }
        }

        client = DropboxClientsManager.authorizedClient
        if client != nil {
            DispatchQueue.main.async {
                self.checkForUploads()
            }
        }
    }

    func checkForUploads() {
        if recording == nil {
            recording = nextRecordingToUpload()
            if recording != nil {
                startUpload()
            }
        }
    }

    func sanitizeFolderName(_ name: String) -> String {
        let chars = CharacterSet(charactersIn: "- .")
        let bits = name.components(separatedBy: chars)
        return bits.joined()
    }

    func startUpload() {
        guard let rec = self.recording else { return }
        guard let client = self.client else { return }
        let destFolder = sanitizeFolderName("/" + rec.directoryName)
        rec.progress = 0.0
        rec.uploading = true
        client.files.createFolder(path: destFolder).response { (response, error) in
            if let response = response {
                print(response)
                rec.progress = 0.2
                self.uploadLog(for: rec, into: destFolder)
            }
            else if let error = error {
                rec.uploading = false
                print(error)
            }
        }
    }

    func uploadLog(for rec: Recording, into destFolder: String) {
        let dest = destFolder + "/" + Logger.singleton.fileName
        let source = rec.folder.appendingPathComponent(Logger.singleton.fileName)
        self.client?.files.upload(path: dest, input: source).response { (response, error) in
            if let response = response {
                print (response)
                self.uploadEvents(for: rec, into: destFolder)
            }
            else if let error = error {
                rec.progress = 0.0
                rec.uploading = false
                print(error)
            }
        }
    }

    func uploadEvents(for rec: Recording, into destFolder: String) {
        let dest = destFolder + "/" + EventLog.singleton.fileName
        let source = rec.folder.appendingPathComponent(EventLog.singleton.fileName)
        rec.progress = 0.5
        self.client?.files.upload(path: dest, input: source).response { (response, error) in
            if let response = response {
                print (response)
                rec.uploading = false
                rec.progress = 1.0
                rec.uploaded = true
                rec.awaitingUpload = false
                rec.save()
                DispatchQueue.main.async {
                    self.checkForUploads()
                }
            }
            else if let error = error {
                rec.progress = 0.0
                rec.uploading = false
                print(error)
            }
        }
    }

    func handleRedirect(url: URL) {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success:
                print("Success! User is logged into Dropbox.")
                userSettings.useDropbox = true
                userSettings.write()
                makeClient()
            case .cancel:
                print("Authorization flow was manually canceled by user!")
            case .error(_, let description):
                print("Error: \(description)")
            }
        }
    }

    func toggle(viewController: SettingsViewController) {
        if userSettings.useDropbox {
            disable(viewController: viewController)
        }
        else {
            enable(viewController: viewController)
        }
    }

    func enable(viewController: SettingsViewController) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: viewController,
                                                      openURL: { (url: URL) -> Void in UIApplication.shared.open(url) })
    }

    func disable(viewController: SettingsViewController) {
        let title = "Dropbox"
        let msg = "Are you sure you want to unlink from Dropbox? This will prevent the app from saving future recordings to your Dropbox folder"
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action: UIAlertAction) in
        })
        let unlinkAction = UIAlertAction(title: "Confirm", style: .destructive, handler: {(action: UIAlertAction) in
            self.userSettings.useDropbox = false
            self.userSettings.write()
            DropboxClientsManager.unlinkClients()
            self.client = nil
        })

        alert.addAction(cancelAction)
        alert.addAction(unlinkAction)
        viewController.present(alert, animated: true) {
            
        }
    }
}
