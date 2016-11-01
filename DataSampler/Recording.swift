//
//  BRHRecording.swift
//  Blah
//
//  Created by Brad Howes on 10/4/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import CoreData
import Foundation

/** 
 A `Recording` instance contains all of the data and meta-data associated with a recording session. Instances are 
 persisted in Core Data.
 */
public final class Recording : NSManagedObject {

    /// The file name for the archived `RunData` data
    private static let runDataFileName = "runData.archive"

    /// The file name for the PDF containg graph images
    private static let pdfFileName: String = "graphs.pdf"

    /// The formatter to use when showing recording durations
    private static var durationFormatter = { PlotTimeFormatter() }()

    /// The formatter to use when generating directory names for recording data.
    private static var directoryNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return dateFormatter
    }()

    /// The formatter to use when showing a recording date/time
    private static var displayNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .default
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()

    /**
     Create a directory name for the given Date value
     - parameter date: the Date value to use
     - returns: a valid iOS directory name derived from the given Date
     */
    private class func directoryName(from date: Date) -> String {
        return Recording.directoryNameDateFormatter.string(from: date)
    }

    /**
     Create a String representation of the given Date value
     - parameter date: the Date value to format
     - returns: the String representation to show
     */
    private class func displayName(from date: Date) -> String {
        return Recording.displayNameDateFormatter.string(from: date)
    }

    /**
     Create a Date value from the given time interval.
     - parameter interval: the time interval to format
     - returns: the Date value
     */
    private func dateFrom(interval: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: interval)
    }

    /// Internal timer that updates a recording meta data while a recording is in process.
    private var updateTimer: Timer?

    /// The URL for the logging file
    private lazy var logFileURL: URL = { return self.folder.appendingPathComponent(Logger.singleton.fileName) }()

    /// The URL for the events file
    private lazy var eventsFileURL: URL = { return self.folder.appendingPathComponent(EventLog.singleton.fileName) }()

    /// The URL for the PDF graphs file
    private lazy var pdfFileURL: URL = { return self.folder.appendingPathComponent(Recording.pdfFileName) }()
    
    /// The entity name found in the xcdatamodel file.
    static let entityName = "Recording"

    /// The sort descriptor to use by default
    static let defaultSortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

    // - MARK: Public properties

    /// The display name for the recording
    var displayName: String {
        return Recording.displayName(from: dateFrom(interval: startTime))
    }

    /// The directory name for the recording
    var directoryName: String {
        return Recording.directoryName(from: dateFrom(interval: startTime))
    }

    /// The formatted recording duration
    var duration: String {
        let duration = isRecording ? Date().timeIntervalSince(dateFrom(interval: startTime)) : endTime - startTime
        return Recording.durationFormatter.string(double: duration)
    }

    /// The location of the recording folder
    lazy var folder: URL = {
        return URL.documents.appendingPathComponent(self.directoryName, isDirectory: true)
    }()

    /// Obtain the RunData instance associated with this recording. If there is an archive file for `RunData` then 
    /// reanimate from it. Otherwise, create a new `RunData` instance.
    lazy var runData: RunDataInterface = {
        let archivePath = self.folder.appendingPathComponent(Recording.runDataFileName)
        do {
            let archiveData = try Data(contentsOf: archivePath)
            Logger.log("archiveData size: \(archiveData.count)")
            if let obj = NSKeyedUnarchiver.unarchiveObject(with: archiveData) as? RunData {
                obj.startTime = self.dateFrom(interval: self.startTime)
                obj.name = self.displayName
                return obj
            }
        } catch {
            Logger.log("*** unable to reconstitute \(archivePath)")
        }

        return RunData()
    }()

    /// Holds `true` if currently recording data
    var isRecording: Bool { return startTime == endTime }

    /// The collection of artifacts for the recording
    lazy var sharableArtifacts: [URL] = { return [self.logFileURL, self.eventsFileURL, self.pdfFileURL] }()

    /**
     Initialize a new `Recording` instance
     - parameter context: the managed object context to associate with
     - parameter userSettings: the `UserSettings` instance to pull runtime settings from
     - parameter runData: the `RunData` instance to use to store incoming samples
     */
    init(context: NSManagedObjectContext, userSettings: UserSettingsInterface, runData: RunDataInterface) {
        super.init(entity: NSEntityDescription.entity(forEntityName: Recording.entityName, in: context)!, insertInto: context)

        let now = Date()
        self.runData = runData
        self.runData.startTime = now
        self.runData.name = now.description

        self.startTime = now.timeIntervalSinceReferenceDate
        self.endTime = self.startTime
        self.size = 0
        self.awaitingUpload = userSettings.uploadAutomatically
        self.uploaded = false
        self.emitInterval = Int32(userSettings.emitInterval)
        self.driver = userSettings.notificationDriver

        self.progress = 0.0
        self.uploading = false
    }

    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    func save() {
        Logger.log("Recording.save - BEGIN")
        guard let context = self.managedObjectContext else {
            Logger.log("Recording.save *** managedObjectContext is nil")
            return
        }

        do {
            try context.save()
        } catch {
            Logger.log("Recording.save - context.save: \(error)")
        }

        Logger.log("Recording.save - END")
    }

    func started() {

        // Create folder to hold the recording data.
        //
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: self.folder, withIntermediateDirectories: true, attributes: nil)
            Logger.log("created recording directory")
        } catch {
            Logger.log("failed to create directory")
        }

        // Create timer that will periodically update this managed object in order to show elapsed time in the table
        // view.
        //
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer: Timer) in
            self.progress += 1.0
        }

    }

    func stopped(pdfRenderer: PDFRenderingInterface?) {
        Logger.log("Recording.finished")

        self.updateTimer?.invalidate()
        self.updateTimer = nil
        let now = Date()
        endTime = now.timeIntervalSinceReferenceDate

        // Generate PDF of the graphs
        //
        var bytes: Int64 = 0
        if let pdfData = pdfRenderer?.render(dataSource: self.runData) ?? nil {

            bytes = Int64(pdfData.length)

            // Save PDF to disk
            //
            do {
                try pdfData.write(to: pdfFileURL, options: .atomic)
            } catch {
                print("*** failed to write PDF data to \(pdfFileURL) - \(error)")
            }
        }

        DispatchQueue.global().async {

            let archivePath = self.folder.appendingPathComponent(Recording.runDataFileName)
            let archiveData = NSKeyedArchiver.archivedData(withRootObject: self.runData)
            bytes += archiveData.count

            do {
                try archiveData.write(to: archivePath)
            } catch {
                Logger.log("*** failed to write to \(archivePath)")
            }

            Logger.save(to: self.folder) { bytes += $0 }
            EventLog.save(to: self.folder) { bytes += $0 }
            Logger.log("+ size: \(bytes)")

            self.size = bytes
            self.save()
        }
    }

    func delete() {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: self.folder.path)
            Logger.log("removed recording directory \(folder)")
        } catch {
            Logger.log("failed to remove directory \(folder) - \(error)")
        }

        self.managedObjectContext?.delete(self)
        save()
    }
}

// - MARK: Uploading State Changes

extension Recording {

    func uploadingRequested() {
        uploaded = false
        awaitingUpload = true
        progress = 0.0
        save()
    }

    func uploadingStarted() {
        progress = 0.0
        uploading = true
    }

    func uploadingCompleted() {
        uploaded = true
        uploading = false
        awaitingUpload = false
        progress = 1.0
        save()
    }

    func uploadingFailed() {
        progress = 0.0
        uploading = false
        save()
    }
}
