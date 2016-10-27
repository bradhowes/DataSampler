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

/** 
 Manages uploads to a linked Dropbox account.
 */
final public class DropboxController: NSObject, DropboxControllerInterface {

    /// Status of linking with a Dropbox account
    public var isLinked: Bool { return self.client != nil }

    private var userSettings: UserSettingsInterface
    private var recordingsStore: RecordingsStoreInterface
    private var fetcher: NSFetchedResultsController<Recording>?

    private var backgroundTask: DispatchWorkItem?
    private var client: DropboxClient? {
        didSet {
            DropboxControllerNotification.post(isLinked: client != nil)
        }
    }

    /**
     Initialize instance.
     - parameter userSettings: user settings that control linking
     - parameter recordingsStore: source of Recording objects that are ready to be uploaded
     */
    init(userSettings: UserSettingsInterface, recordingsStore: RecordingsStoreInterface) {
        self.userSettings = userSettings
        self.recordingsStore = recordingsStore
        super.init()

        // Receive notification when the Core Data stack is ready. 
        //
        RecordingsStoreNotification.observe(observer: self, selector: #selector(storeIsReady),
                                            recordingStore: self.recordingsStore)

        // Receive notification when linking changes state
        //
        UserSettingsChangedNotification.observe(observer: self, selector: #selector(dropboxLinkingChanged),
                                                setting: .dropboxLinkButtonText)

        DropboxClientsManager.setupWithAppKey("8dg497axhy58ypa")

        if userSettings.useDropbox && recordingsStore.isReady {
            makeClient()
        }
    }

    /**
     Perform a closure under a single-threaded guarantee of access.
     - parameter closure: the block to execute
     */
    private func synced(closure: () -> ()) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }

    /**
     Handle a request to upload a recording. Performs any uploads on a background thread.
     - parameter recording: the Recording to upload
     */
    public func upload(recording: Recording) {
        synced {

            // Only create one task for handling uploads
            //
            if self.backgroundTask == nil {
                self.backgroundTask = DispatchWorkItem {
                    self.startUpload(recording: recording)
                }
                DispatchQueue.global(qos: .background).async(execute: self.backgroundTask!)
            }
        }
    }

    /**
     Notification from the recordings store that it is available for fetching
     - parameter notification: the notification from the store
     */
    public func storeIsReady(notification: Notification) {
        self.makeClient()
    }

    /**
     Notification from user settings when linking status changes.
     - parameter notification: the notification from UserSettings
     */
    public func dropboxLinkingChanged(notification: Notification) {
        self.makeClient()
    }

    private func dropBackgroundTask(cancel: Bool = false) {
        synced {
            if cancel { self.backgroundTask?.cancel() }
            self.backgroundTask = nil
        }
    }

    /**
     See if there is another Recording waiting to be uploaded to Dropbox. NOTE: this clears the `backgroundTask` with
     malice.
     */
    private func checkForUploads() {
        dropBackgroundTask()
        if let recording = fetcher?.fetchedObjects?.first(where: { (recording) -> Bool in
            return !recording.uploaded && !recording.isRecording && recording.awaitingUpload
        }) {
            upload(recording: recording)
        }
    }

    /**
     Attempt to create a Dropbox client to perform uploads. The attempt is made in a background thread.
     */
    private func makeClient() {
        synced {

            // If there is an active background task, cancel it. The user could have disabled linking while we have an
            // active upload taking place.
            //
            if self.backgroundTask != nil {
                self.backgroundTask!.cancel()
                self.backgroundTask = nil
            }

            // Check if conditions are right for having a client
            //
            if !self.userSettings.useDropbox || !self.recordingsStore.isReady {
                client = nil
                return
            }

            // Create task to do the connection
            //
            self.backgroundTask = DispatchWorkItem {
                self.client = DropboxClientsManager.authorizedClient
                if self.client == nil {
                    self.synced { self.backgroundTask = nil }
                    return
                }

                self.fetcher = self.recordingsStore.cannedFetchRequest(name: "uploadable")
                if self.fetcher?.fetchedObjects == nil {
                    do {
                        try self.fetcher?.performFetch()
                        } catch {
                            fatalError("Failed to fetch: \(error)")
                    }
                }

                self.checkForUploads()
            }

            // Peform the above on the background thread
            //
            DispatchQueue.global(qos: .background).async(execute: self.backgroundTask!)
        }
    }

    /**
     Convert an iOS folder into one suitable for Dropbox.
     - parameter name: the String representation of the folder
     - returns: the sanitized version
     */
    private func sanitizeFolder(named folder: String) -> String {
        let chars = CharacterSet(charactersIn: "- .")
        let bits = folder.components(separatedBy: chars)
        return bits.joined()
    }

    /**
     Attempt to start an upload of a Recording
     - parameter recording: the Recording instance to upload
     */
    private func startUpload(recording: Recording) {
        guard let client = self.client else {
            dropBackgroundTask()
            return
        }

        let destFolder = sanitizeFolder(named: "/" + recording.directoryName)
        recording.uploadingStarted()

        // Create a Dropbox folder to hold the recording artifacts
        //
        client.files.createFolder(path: destFolder).response { (response, error) in
            if let response = response {
                print(response)
                recording.progress = 1.0 / 4.0
                self.uploadFile(index: 0, of: recording, into: destFolder)
            }
            else if let error = error {
                print(error)
                self.uploadFile(index: 0, of: recording, into: destFolder)
            }
        }
    }

    /**
     Upload a file artifict for a recording.
     - parameter index: the next index of `recording.sharableArtifacts` to upload
     - parameter recording: the Recording being processed
     - parameter destFolder: the destination folder to write into
     */
    private func uploadFile(index: Int, of recording: Recording, into destFolder: String) {
        guard let client = self.client else {
            dropBackgroundTask()
            return
        }

        let source = recording.sharableArtifacts[index]
        let dest = destFolder + "/" + source.lastPathComponent
        print("\(source) -> \(dest)")

        // Upload the file
        //
        client.files.upload(path: dest, input: source).response { (response, error) in
            if let response = response {
                print (response)
                if index + 1 < recording.sharableArtifacts.count {

                    // Upload the next file
                    //
                    recording.progress = Double(index + 2) / 4.0
                    self.uploadFile(index: index + 1, of: recording, into: destFolder)
                }
                else {

                    // Done! Update the recording state and see if there are more to upload
                    //
                    recording.uploadingCompleted()
                    self.checkForUploads()
                }
            }
            else if let error = error {
                print(error)
                recording.uploadingFailed()
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

    public func toggleAccountLinking(viewController: UIViewController) {
        if userSettings.useDropbox {
            disable(viewController: viewController)
        }
        else {
            enable(viewController: viewController)
        }
    }

    private func enable(viewController: UIViewController) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: viewController,
                                                      openURL: { (url: URL) -> Void in UIApplication.shared.open(url) })
    }

    private func disable(viewController: UIViewController) {
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
            self.dropBackgroundTask(cancel: true)
        })

        alert.addAction(cancelAction)
        alert.addAction(unlinkAction)
        viewController.present(alert, animated: true) {}
    }
}
