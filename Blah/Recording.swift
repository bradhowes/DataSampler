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

    static let defaultSortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

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
    
    var displayName: String {
        return Recording.displayName(from: self.startTime as! Date)
    }

    var directoryName: String {
        return Recording.directoryName(from: self.startTime as! Date)
    }

    lazy var folder: URL = {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(self.directoryName, isDirectory: true)
    }()

    lazy var runData: RunData = {
        var tmp = RunData()
        let archivePath = self.folder.appendingPathComponent("runData.archive")
        do {
            let archiveData = try Data(contentsOf: archivePath)
            Logger.log("archiveData size: \(archiveData.count)")
            guard let obj = NSKeyedUnarchiver.unarchiveObject(with: archiveData) else {
                return tmp
            }

            tmp = obj as! RunData
            tmp.startTime = self.startTime! as Date
            tmp.name = self.displayName
        } catch {
            Logger.log("*** unable to reconstitute \(archivePath)")
        }

        return tmp
    }()

    override func willSave() {
        super.willSave()
        Logger.log("Recording.willSave - \(startTime) updated: \(isUpdated) deleted: \(isDeleted)")
    }

    init(context: NSManagedObjectContext, startTime: Date) {
        super.init(entity: Recording.entity(context: context), insertInto: context)

        self.startTime = startTime as NSDate?
        self.endTime = self.startTime
        self.size = "Recording"
        self.awaitingUpload = false
        self.uploaded = false
        self.driver = UserSettings.notificationDriver
        self.emitInterval = Int32(UserSettings.emitInterval)
        self.runData = RunData()
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

    func finished() {
        Logger.log("Recording.finished")

        let now = Date()
        self.endTime = now as NSDate?

        // Create folder to hold the recording data
        //
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: self.folder, withIntermediateDirectories: true, attributes: nil)
            Logger.log("created recording directory")
        } catch {
            Logger.log("failed to create directory")
        }

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

            Logger.save(to: self.folder) { bytes += $0 }
            EventLog.save(to: self.folder) { bytes += $0 }

            Logger.log("+ size: \(bytes)")
            self.size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)

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
        //RecordingsStore.delete(recording: self)
    }
}
