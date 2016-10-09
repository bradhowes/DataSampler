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

/**
 Manages a view of recordings
 */
final class RecordingsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    private var recordingsStore: RecordingsStoreInterface!
    private var fetcher: NSFetchedResultsController<Recording>!

    private var selectedRecording: Recording? = nil
    private var selectedRecordingIndex: IndexPath? = nil

   /**
     View loaded. Load recording data.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        recordingsStore = PassiveDependencyInjector.singleton.recordingsStore
        fetcher = recordingsStore.recordingsFetcher()
        fetcher?.delegate = self

        // Fetch recordings.
        //
        do {
            try fetcher?.performFetch()
            tableView.reloadData()
        } catch {
            assertionFailure("Failed to fetch: \(error)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // - NOTE: for some reason, we need this to remove ugly "jump" of the title when the appearance of the view
        // is controlled by a transition animation
        //
        navigationController?.navigationBar.layer.removeAllAnimations()
    }

    /**
     View controller method to control table editing.
     - parameter editing: editing state
     - parameter animated: animating state change if true
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // MARK: Table view data source

    /**
     Configure a UITableViewCell with recording info for display.
     - parameter cell: the UITableViewCell to format
     - parameter indexPath: the row of the table to update
     */
    private func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let recording = fetcher?.object(at: indexPath) else { return }
        cell.textLabel?.text = recording.displayName
        cell.detailTextLabel?.text = recording.size
        cell.detailTextLabel?.textColor = recording.size == "Recording" ? UIColor.red : UIColor.darkGray
        cell.accessoryType = recording == selectedRecording ? .checkmark : .none
    }

    /**
     Data source method to obtain the number of sections in the table. There is only one here.
     - parameter tableView: the UITableView to report on
     - returns: the section count (1)
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /**
     Data source method to obtaion the number of rows in a section.
     - parameter tableView: the UITableView to report on
     - parameter section: the section to report on
     - returns: the number of rows
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }
        let count = fetcher?.fetchedObjects?.count ?? 0

        // Don't allow editing if the table is empty.
        //
        self.navigationItem.rightBarButtonItem = count > 0 ? self.editButtonItem : nil
        return count
    }

    /**
     Data source method that returns a formatted UITableViewCell for a given table row index.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the index of the row to return
     - returns: formatted UITableViewCell to display
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingCell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    /**
     Data source method invoked when a row is selected.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the index of the row that was selected
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Deselect the row per Apple's guidelines
        //
        tableView.deselectRow(at: indexPath, animated: false)

        // Uncheck any previous selection
        //
        if selectedRecordingIndex != nil {
            let cell = tableView.cellForRow(at: selectedRecordingIndex!)
            cell?.accessoryType = .none
        }

        // Remember the selected recording and row
        //
        selectedRecording = fetcher?.object(at: indexPath)
        selectedRecordingIndex = indexPath

        // Mark the selected row and show recorded info main view
        //
        let cell = tableView.cellForRow(at: selectedRecordingIndex!)
        cell? .accessoryType = .checkmark

        RecordingsTableNotification.post(kind: .recordingSelected, recording: selectedRecording!)

        // Move to the main view
        //
        self.tabBarController?.selectedIndex = 0
    }

    // MARK: Table view delegate

    /**
     Table view delegate method that asks if a row can be edited.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the index of the row being queried
     - returns: true if editable
     */
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let recording = fetcher?.object(at: indexPath) else { return false }
        return true || recording.size! != "Recording"
    }

    /**
     Table view delegate method to handle changes in editing state of a row. Here we respond to row deletion by deleting
     the Recording instance associated with the row.
     - parameter tableView: the UITableView to work with
     - parameter editingStyle: what kind of editing was performed
     - parameter indexPath: the index of the row that was edited
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DispatchQueue.global().async {
                guard let obj = self.fetcher?.object(at: indexPath) else { return }
                obj.delete()
            }
        }
    }

    // MARK: Fetched results controller delegate

    /**
     Notification from fetch results controller that a batch of changes will take place.
     - parameter controller: the fetched results controller to work with
     */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    /**
     Notification from fetch results controller that sections were added to or remove from the table
     - parameter controller: the fetched results controller to work with
     - parameter sectionInfo: description of the section
     - parameter sectionIndex: the index of the section
     - parameter type: the operation that was performed
     */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete: tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default: break
        }
    }

    /**
     Notification from fetch results controller that a row was added, deleted, changed, or moved.
     - parameter controller: the fetched results controller to work with
     - parameter anObject: the Recording instance assocated with the edited row
     - parameter indexPath: the row of the table that was edited
     - parameter type: the operation that was performed
     - parameter newIndexPath: the new row in the table (optional)
     */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let recording = anObject as! Recording
        switch type {
        case .insert:

            // Deselect any previously-selected row
            //
            if selectedRecordingIndex != nil {
                let cell = tableView.cellForRow(at: selectedRecordingIndex!)
                cell?.accessoryType = .none
            }

            // Remember the recording of the selected row
            //
            selectedRecording = recording
            selectedRecordingIndex = newIndexPath

            // Do the row insertion
            //
            tableView.insertRows(at: [newIndexPath!], with: .fade)

        case .delete:

            // If the row being deleted is the current selection, remove it from any views
            //
            if recording === selectedRecording {
                selectedRecording = nil
                selectedRecordingIndex = nil
                RecordingsTableNotification.post(kind: .recordingDeleted, recording: recording)
            }

            // Do the row deletion
            //
            tableView.deleteRows(at: [indexPath!], with: .fade)

        case .update:

            // Row was updated. Update the cell with new recording info.
            //
            Logger.log("+ updating \(indexPath!)")
            configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)

        case .move:

            // Rows are being moved via two operations: a deletion followed by an insertion.
            //
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)

            // Update selected state if the row was selected
            //
            if selectedRecordingIndex == indexPath || recording === selectedRecording {
                selectedRecordingIndex = newIndexPath
            }
        }
    }

    /**
     Notification from fetch results controller that all changes are complete.
     - parameter controller: the fetched results controller to work with
     */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
