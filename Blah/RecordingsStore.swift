//
//  RecordingsTableViewController
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import CoreData
import JSQCoreDataKit

/** 
 Manager of the Core Data stack for recordings.
 */
final class RecordingsStore : NSObject {

    static let singleton: RecordingsStore = RecordingsStore()

    private(set) var stack: CoreDataStack?
    private(set) var fetcher: NSFetchedResultsController<Recording>?

    override init() {
        super.init()
        Logger.log("RecordingsStore.init")
        let model = CoreDataModel(name: "RecordingModel")
        let factory = CoreDataStackFactory(model: model)
        factory.createStack { (result: StackResult) -> Void in
            switch result {
            case .success(let stack):
                Logger.log("created Core Data stack")
                self.stack = stack
                guard let mainContext = self.stack?.mainContext else {
                    Logger.log("*** RecordingsStore.init: nil stack")
                    return
                }
                self.fetcher = NSFetchedResultsController(fetchRequest: Recording.fetchRequest,
                                                          managedObjectContext: mainContext,
                                                          sectionNameKeyPath: nil, cacheName: nil)

                Logger.log("fetcher: \(self.fetcher)")

            case .failure(let err):
                Logger.log("*** failed to create Core Data stack: \(err)")
                assertionFailure("Error creating stack: \(err)")
            }
        }
    }

    class func newRecording(startTime: Date) -> Recording? {
        return singleton.newRecording(startTime: startTime)
    }

    class func save() {
        return singleton.save()
    }

    class func delete(recording: Recording) {
        singleton.delete(recording: recording)
    }

    private func newRecording(startTime: Date) -> Recording? {
        Logger.log("creating new recording")
        guard let mainContext = stack?.mainContext else {
            Logger.log("*** RecordingsStore.newRecording: nil stack")
            return nil
        }
        return Recording(context: mainContext, startTime: startTime)
    }

    private func save() {
        guard let mainContext = stack?.mainContext else {
            Logger.log("*** RecordingsStore.save: nil stack")
            return
        }
        Logger.log("saving main context")
        saveContext(mainContext, wait: true) { Logger.log("saveContext: \($0)") }
    }

    private func delete(recording: Recording) {
        guard let stack = self.stack else { return }
        stack.mainContext.performAndWait {
            self.stack?.mainContext.delete(recording)
        }
        saveContext(stack.mainContext)
    }
}
