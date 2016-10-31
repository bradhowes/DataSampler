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
final public class RecordingsStore : NSObject, RecordingsStoreInterface {

    internal var dependentType: Any.Type { return RecordingsStoreDependent.self }

    private let userSettings: UserSettingsInterface
    private let runDataFactory: RunDataInterface.FactoryType
    private(set) var stack: CoreDataStack?

    private(set) public var isReady: Bool

    /**
     Intialize new instance. The store may not be available for some time for requests. It will send out a notification
     when it is ready.
     - parameter userSettings: user settings that control some aspects of new `Recording` objects.
     - parameter runDataFactory: a factory method used to create `RunData` objects
     */
    init(userSettings: UserSettingsInterface, runDataFactory: @escaping RunDataInterface.FactoryType) {
        self.userSettings = userSettings
        self.runDataFactory = runDataFactory
        self.isReady = false

        super.init()

        Logger.log("RecordingsStore.init")
        let model = CoreDataModel(name: "RecordingModel")
        let factory = CoreDataStackFactory(model: model)
        factory.createStack { (result: StackResult) -> Void in
            switch result {
            case .success(let stack):
                Logger.log("created Core Data stack")
                self.stack = stack
                self.isReady = true
                RecordingsStoreNotification.post(recordingStore: self)
            case .failure(let err):
                Logger.log("*** failed to create Core Data stack: \(err)")
                assertionFailure("Error creating stack: \(err)")
            }
        }
    }

    /**
     Obtain a new NSFetchedResultsController with a canned query.
     - parameter name: the canned query to perform
     - returns: a new `Recording` fetch request wrapped in a NSFetchedResultsController
     */
    public func cannedFetchRequest(name: String) -> NSFetchedResultsController<Recording> {
        guard let mainContext = self.stack?.mainContext else {
            fatalError("invalid context")
        }

        let managedObjectModel = mainContext.persistentStoreCoordinator!.managedObjectModel
        let fr = managedObjectModel.fetchRequestTemplate(forName: name)!.copy() as! NSFetchRequest<Recording>
        fr.sortDescriptors = Recording.defaultSortDescriptors
        fr.fetchBatchSize = 30

        // NOTE: using NSFetchedResultsController is probably overkill for all purposes other than UITableView support.
        //
        let fetcher = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: mainContext,
                                                 sectionNameKeyPath: nil, cacheName: name)
        return fetcher
    }

    /**
     Create a new `RunData` object for a new recording
     - returns: object that implements the `RunDataInterface`
     */
    public func newRunData() -> RunDataInterface {
        return runDataFactory(userSettings)
    }

    /**
     Create a new `Recording` instance attached to the main Core Data context.
     - returns: new `Recording` instance
     */
    public func newRecording() -> Recording {
        Logger.log("creating new recording")
        guard let mainContext = stack?.mainContext else {
            fatalError("*** RecordingsStore.newRecording: nil stack")
        }
        return Recording(context: mainContext, userSettings: userSettings, runData: newRunData())
    }

    /**
     Save all changes to Core Data
     */
    public func save() {
        guard let mainContext = stack?.mainContext else {
            Logger.log("*** RecordingsStore.save: nil stack")
            return
        }
        Logger.log("saving main context")
        saveContext(mainContext) { Logger.log("savedContext: \($0)") }
    }

    /**
     Delete a recording instance, removing it from Core Data forever.
     - parameter recording: the `Recording` instance to delete
     */
    private func delete(recording: Recording) {
        guard let stack = self.stack else { return }
        stack.mainContext.performAndWait {
            self.stack?.mainContext.delete(recording)
        }
        saveContext(stack.mainContext)
    }
}
