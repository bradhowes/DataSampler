//
//  RecordingTableViewCell.swift
//  Blah
//
//  Created by Brad Howes on 10/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit
import CircleProgressView
import MGSwipeTableCell
import PDFGenerator

/**
 Functionality for a cell in the `RecordingsTableView` view. Each cell shows information about an associated `Recording`
 instance. Swiping on the cell reveals action buttons:

 - left swipe: Delete button
 - right swipe: Dropbox upload button, share button
 
 Since this is purely a view class, all activity for the action buttons is perfomed by the `ActionableCellHandler`
 instance set in the `actionHandler` property.
 */

final class RecordingsTableViewCell: MGSwipeTableCell, ActionableCell {

    /// The actions that the cell supports
    enum Action: Int {
        case upload, share, delete
    }

    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var detail: UITextView!

    /// The object that will perform the actions on behalf of the cell.
    weak var actionHandler: ActionableCellHandler!

    /// The `Recording` instance associated with the cell.
    fileprivate var recording: Recording!

    /**
     Implementation of `ActionableCell`. Hides any visible action buttons.
     */
    func actionComplete() {
        hideSwipe(animated: true)
    }

    /// Configuration of actions for the cell. Defines which side of the cell actions will appear.
    fileprivate static let Actions: [(side: MGSwipeDirection, action: Action, gen: ()->UIView)] = [
        (side: .leftToRight, action: .upload, {return MGSwipeButton(title: "", icon: UIImage(named: "upload.png"), backgroundColor: UIColor.white)}),
        (side: .leftToRight, action: .share, {return MGSwipeButton(title: "", icon: UIImage(named: "share.png"), backgroundColor: UIColor.white)}),
        (side: .rightToLeft, action: .delete, {return MGSwipeButton(title: "Delete", backgroundColor: UIColor.red)})
    ]

    /**
     Override of `UITableViewCell`. This instance is about to be used to show recording info.
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        actionHandler = nil
        recording = nil
    }
}

// - MARK: ConfigurableCell Implementation

extension RecordingsTableViewCell: ConfigurableCell {

    typealias DataSource = Recording

    /**
     Implementation of `ConfigurableCell` interface. Sets the content of the cell depending on the state of the given
     `Recording` object.
     - parameter recording: the `Recording` instance to associate with the cell
     - parameter selected: `true` if the cell is currently selected and being displayed in the plots
     */
    func configure(dataSource recording: Recording, selected: Bool) {

        self.recording = recording
        self.delegate = self

        textLabel?.text = recording.displayName

        // Build the status text to show depending on recording and uploading states
        //
        var status = ""
        var color = UIColor.blue
        if recording.isRecording {
            status = "Recording"
            color = UIColor.red
        }
        else if recording.uploaded {
            status = "Uploaded"
            color = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        }
        else if recording.uploading {
            status = "Uploading"
            color = UIColor(colorLiteralRed: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        }
        else if recording.awaitingUpload {
            status = "Awaiting upload"
        }
        else {
            status = "Not uploaded"
        }

        detailTextLabel?.textColor = color

        if recording.isRecording {
            detailTextLabel?.text = "\(recording.duration) - \(status)"
        }
        else {
            let size = ByteCountFormatter.string(fromByteCount: recording.size, countStyle: .file)
            detailTextLabel?.text = "\(recording.duration) • \(size) - \(status)"
        }

        // Show a progress indicator if uploading
        //
        if recording.uploading {
            if accessoryView == nil {
                let pv = CircleProgressView(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0))
                pv.backgroundColor = UIColor.white
                pv.trackBackgroundColor = UIColor.white
                pv.trackWidth = 5.0
                pv.trackFillColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                accessoryView = pv
            }
            (accessoryView as! CircleProgressView).progress = recording.progress
        }
        else {
            accessoryView = nil
        }

        // Show a checkmark if cell is currently selected
        //
        accessoryType = selected ? .checkmark : .none

        // Configure the left/right swipe buttons for the cell
        //
        leftButtons = []
        rightButtons = []

        leftSwipeSettings.transition = .drag
        rightSwipeSettings.transition = .drag

        for (dir, action, gen) in RecordingsTableViewCell.Actions {
            if actionHandler.canPerform(action: action, recording: recording) {
                var buttons: [UIView] = {
                    switch dir {
                    case .leftToRight: return leftButtons
                    case .rightToLeft: return rightButtons}
                }()
                buttons.append(gen())
                buttons.last!.tag = action.rawValue
            }
        }
    }
}

// - MARK: MGSwipeTableCellDelegate methods

extension RecordingsTableViewCell: MGSwipeTableCellDelegate {

    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection,
                        fromExpansion: Bool) -> Bool {
        let button = { () -> UIView in
            switch direction {
            case .rightToLeft: return rightButtons[index]
            case .leftToRight: return leftButtons[index]
            }
        }()
        let tag = Action(rawValue: button.tag)!
        return actionHandler.performRequest(action: tag, cell: self, button: button, recording: recording)
    }
}
