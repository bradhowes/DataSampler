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

final class Recording : NSManagedObject, CoreDataEntityProtocol {

    static let defaultSortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]

    var displayName: String {
        return Recording.displayName(from: self.startTime as! Date)
    }

    var directoryName: String {
        return Recording.directoryName(from: self.startTime as! Date)
    }

    var folder: URL? {
        get {
            let fileManager = FileManager.default
            guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                Logger.log("*** failed to obtain document directory")
                return nil
            }
            return docDir.appendingPathComponent(directoryName, isDirectory: true)
        }
    }

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

    private var byteSize: Int64 = 0

    init(context: NSManagedObjectContext, startTime: Date) {
        super.init(entity: Recording.entity(context: context), insertInto: context)

        self.startTime = startTime as NSDate?
        self.endTime = self.startTime
        self.size = "Recording"
        self.awaitingUpload = false
        self.uploaded = false
        self.driver = UserSettings.singleton.notificationDriver
        self.emitInterval = Int32(UserSettings.singleton.emitInterval)

        Logger.log("recording directory: \(folder!)")

        // Create folder to hold the recording data
        //
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: folder!, withIntermediateDirectories: true, attributes: nil)
            Logger.log("created recording directory")
        } catch {
            Logger.log("failed to create directory")
        }
    }

    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    func finished(runData: RunData) {
        Logger.log("Recording.finished")
        let now = Date()
        self.endTime = now as NSDate?
        if let folder = self.folder {

            let archivePath = folder.appendingPathComponent("runData.archive")
            let archiveData = NSKeyedArchiver.archivedData(withRootObject: runData)

            Logger.log("archiving run data: \(archiveData.count)")
            DispatchQueue.global().async {
                var bytes : Int64 = Int64(archiveData.count)
                do {
                    try archiveData.write(to: archivePath)
                } catch {
                    Logger.log("*** failed to write to \(archivePath)")
                }

                Logger.save(to: folder) { bytes += $0 }
                EventLog.save(to: folder) { bytes += $0 }

                Logger.log("size: \(bytes)")
                self.size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)

                RecordingsStore.save()
            }
        }
        else {
            RecordingsStore.save()
        }
    }

    func restore() {
        guard let folder = self.folder else {
            Logger.log("*** recording folder is nil")
            return
        }

        let archivePath = folder.appendingPathComponent("runData.archive")
        do {
            let archiveData = try Data(contentsOf: archivePath)
            Logger.log("archiveData size: \(archiveData.count)")
            guard let obj = NSKeyedUnarchiver.unarchiveObject(with: archiveData) else {
                return
            }

            let runData = obj as! RunData
            runData.startTime = self.startTime! as Date
            runData.name = self.displayName
            AppDelegate.singleton.runData.replace(with: runData)

            Logger.restore(from: folder)
            EventLog.restore(from: folder)
        } catch {
            Logger.log("*** unable to reconstitute \(archivePath)")
            return
        }
    }

    func delete() {
        guard let folder = self.folder else { return }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: folder.path)
            Logger.log("removed recording directory \(folder)")
        } catch {
            Logger.log("failed to remove directory \(folder) - \(error)")
        }

        RecordingsStore.singleton.delete(recording: self)
    }
}
