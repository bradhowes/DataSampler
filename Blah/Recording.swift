//
//  BRHRecording.swift
//  Blah
//
//  Created by Brad Howes on 10/4/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import CoreData
import JSQCoreDataKit
import PDFGenerator

public final class Recording : NSManagedObject, CoreDataEntityProtocol {

    public static let defaultSortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

    private static var durationFormatter = { PlotTimeFormatter() }()

    private static var directoryNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return dateFormatter
    }()

    private static var displayNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .default
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()
    
    private class func directoryName(from date: Date) -> String {
        return Recording.directoryNameDateFormatter.string(from: date)
    }

    private class func displayName(from date: Date) -> String {
        return Recording.displayNameDateFormatter.string(from: date)
    }

    private func dateFrom(interval: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: interval)
    }

    private var updateTimer: Timer?

    var displayName: String {
        return Recording.displayName(from: dateFrom(interval: startTime))
    }

    var directoryName: String {
        return Recording.directoryName(from: dateFrom(interval: startTime))
    }

    var duration: String {
        let duration = isRecording ? Date().timeIntervalSince(dateFrom(interval: startTime)) : endTime - startTime
        return Recording.durationFormatter.string(double: duration)
    }

    lazy var folder: URL = {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(self.directoryName, isDirectory: true)
    }()

    lazy var runData: RunDataInterface = {
        let archivePath = self.folder.appendingPathComponent("runData.archive")
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

    var isRecording: Bool { return startTime == endTime }

    let graphsFileName: String = "graphs.pdf"

    lazy var logFileURL: URL = { return self.folder.appendingPathComponent(Logger.singleton.fileName) }()
    lazy var eventsFileURL: URL = { return self.folder.appendingPathComponent(EventLog.singleton.fileName) }()
    lazy var graphsFileURL: URL = { return self.folder.appendingPathComponent(self.graphsFileName) }()
    lazy var sharableArtifacts: [URL] = { return [self.logFileURL, self.eventsFileURL, self.graphsFileURL] }()

    init(context: NSManagedObjectContext, userSettings: UserSettingsInterface, runData: RunDataInterface) {
        super.init(entity: Recording.entity(context: context), insertInto: context)

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

        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer: Timer) in
            self.progress += 1.0
        }

        // Create folder to hold the recording data
        //
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: self.folder, withIntermediateDirectories: true, attributes: nil)
            Logger.log("created recording directory")
        } catch {
            Logger.log("failed to create directory")
        }
    }

    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    func save() {
        guard let context = self.managedObjectContext else {
            Logger.log("*** managedObjectContext is nil")
            return
        }
        saveContext(context) { Logger.log("saveContext: \($0)") }
    }

    func stopped(pdfRenderer: PDFRenderingInterface?) {
        Logger.log("Recording.finished")

        self.updateTimer?.invalidate()
        self.updateTimer = nil
        let now = Date()
        endTime = now.timeIntervalSinceReferenceDate

        // Generate PDF of the graphs
        //
        var bytes: Int64 = pdfRenderer?.render(recording: self) ?? 0
        DispatchQueue.global().async {

            let archivePath = self.folder.appendingPathComponent("runData.archive")
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
