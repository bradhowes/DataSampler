//
//  RecordingsTableViewController
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class RecordingsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    private var stack: CoreDataStack? { return RecordingsStore.singleton.stack }
    private var fetcher: NSFetchedResultsController<Recording>? { return RecordingsStore.singleton.fetcher }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetcher?.delegate = self
        fetchData()
    }

    func fetchData() {
        do {
            try fetcher?.performFetch()
            tableView.reloadData()
        } catch {
            assertionFailure("Failed to fetch: \(error)")
        }
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetcher?.fetchedObjects?.count ?? 0
        Logger.log("fetched \(count) recording entries")
        if section == 0 && count > 0 {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        }
        else {
            self.navigationItem.rightBarButtonItem = nil
        }
        return count
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let recording = fetcher?.object(at: indexPath) else { return }
        cell.textLabel?.text = recording.displayName
        cell.detailTextLabel?.text = recording.size
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingCell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let recording = fetcher?.object(at: indexPath) else { return }
        DispatchQueue.global().async {
            recording.restore()
        }

        self.tabBarController?.selectedIndex = 0
    }

    // MARK: Table view delegate

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let recording = fetcher?.object(at: indexPath) else { return false }
        return recording.size! != "Recording"
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let obj = fetcher?.object(at: indexPath) else { return }
            obj.delete()
        }
    }

    // MARK: Fetched results controller delegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        Logger.log("RecordingsTableViewController.didChange: \(type)")
        switch type {
        case .insert: tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete: tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default: break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update: configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
