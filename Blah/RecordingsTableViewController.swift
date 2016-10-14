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
import CircleProgressView

/**
 Manages a view of recordings
 */
final class RecordingsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate,
RecordingsStoreDependent {

    /// Source for recordings. The Core Data stack may not be ready when we receive this dependency so be careful
     var recordingsStore: RecordingsStoreInterface! {
        didSet {
            if recordingsStore.isReady {
                storeIsReady()
            }
            else {
                RecordingsStoreNotification.observe(observer: self, selector: #selector(storeIsReady),
                                                    recordingStore: recordingsStore)
            }
        }
    }

    private var fetcher: NSFetchedResultsController<Recording>!
    private var selectedRecording: Recording? = nil
    private var selectedRecordingIndex: IndexPath? = nil

   /**
     View loaded. Load recording data.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        guard recordingsStore.isReady else { return }

        tableView.delegate = self
        if fetcher == nil {
            storeIsReady()
        }

        fetchRecordings()
        tableView.reloadData()
    }

    /**
     Notification handler invoked when RecordingsStore reports that is ready.
     - parameter notification: the notification from the store
     */
    func storeIsReady(notification: Notification? = nil) {
        fetcher = recordingsStore.cannedFetchRequest(name: "blah")
        fetcher.delegate = self
    }

    /**
     Fetch recordings from the store.
     */
    func fetchRecordings() {
        do {
            try fetcher?.performFetch()
        } catch {
            assertionFailure("Failed to fetch: \(error)")
        }
    }

    /**
     The view is about to be shown. Make sure our edit state is in the right configuration.
     - parameter animated: true if animating
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEditButtons()
    }

    /**
     The view is about to disappear. Turn off editing.
     - parameter animated: true if animating
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if tableView.isEditing {
            setEditing(false, animated: false)
        }
    }

    /**
     View controller method to control table editing.
     - parameter editing: editing state
     - parameter animated: animating state change if true
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        updateEditButtons()
    }

    // MARK: Table view data source

    /**
     Configure a UITableViewCell with recording info for display.
     - parameter cell: the UITableViewCell to format
     - parameter indexPath: the row of the table to update
     */
    private func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let recording = fetcher?.object(at: indexPath) else { return }
        guard let cell = cell as? RecordingTableViewCell else { fatalError("unexpected UITableViewCell") }
        cell.configure(dataSource: recording)
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
        return count
    }

    /**
     Update the buttons involved in editing the rows. Here are the rules.
     
     If not editing:
     - No rows, no 'Edit'
     - One row currently recording, no 'Edit'
     - Otherwise, show 'Edit'
     If editing, then:
     - Show 'Cancel' button on left
     - Show 'Trash' button on right but only if there is at least one row selected
     */
    private func updateEditButtons() {
        var canEdit = false
        let numRows = tableView.numberOfRows(inSection: 0)
        if numRows == 1 {
            let recording = fetcher?.object(at: IndexPath(row: 0, section: 0))
            canEdit = !(recording!.isRecording)
        }
        else if numRows > 1 {
            canEdit = true
        }

        if canEdit {
            if tableView.isEditing {
                self.navigationItem.leftBarButtonItem =
                    UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
                let count = tableView.indexPathsForSelectedRows?.count ?? 0
                if count > 0 {
                    self.navigationItem.rightBarButtonItem =
                        UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(doDelete))
                    self.navigationItem.rightBarButtonItem?.tintColor = UIColor.red
                }
                else {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
            else {
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = self.editButtonItem
            }
        }
        else {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        }

        if !canEdit && tableView.isEditing {
            setEditing(false, animated: true)
        }
    }

    /**
     Event handler for the trash can button. Delete all of the selected `Recording` objects
     - parameter sender: the button that was touched
     */
    func doDelete(sender: UIBarButtonItem) {
        guard let items = tableView.indexPathsForSelectedRows else { return }
        items.forEach { fetcher?.object(at: $0).delete() }
        setEditing(false, animated: true)
    }

    /**
     Event handler for the 'Cancel' button. End edit mode.
     - parameter sender: the button that was touched
     */
    func doCancel(sender: UIBarButtonItem) {
        setEditing(false, animated: true)
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

        if tableView.isEditing {

            // We support multiple selections. If there is at least one, add a 'Delete' button
            //
            updateEditButtons()
            return
        }

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

        // Mark the selected row and show recorded info in main view
        //
        let cell = tableView.cellForRow(at: selectedRecordingIndex!)
        cell? .accessoryType = .checkmark
        RecordingsTableNotification.post(kind: .recordingSelected, recording: selectedRecording!)

        // Move to the main view
        //
        tabBarController?.selectedIndex = 0
    }

    /**
     Notification that user deselected a row. We only care about this while in edit mode so we can update the edit
     buttons based on the number of selected rows.
     - parameter tableView: the view being edited
     - parameter indexPath: the row that was deselected
     */
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateEditButtons()
        }
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
        return !recording.isRecording
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
            guard let obj = self.fetcher?.object(at: indexPath) else { return }
            obj.delete()
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
        updateEditButtons()
    }
}
