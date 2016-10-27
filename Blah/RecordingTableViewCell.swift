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

final class RecordingTableViewCell: MGSwipeTableCell {

    enum Button: Int {
        case upload, share, delete
    }

    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var detail: UITextView!

    fileprivate var activityHandler: CellActivityHandler!
    fileprivate var recording: Recording!
}

extension RecordingTableViewCell: ConfigurableCell {

    func configure(dataSource recording: Recording, activityHandler: CellActivityHandler) {

        self.recording = recording
        self.activityHandler = activityHandler
        self.delegate = self

        textLabel?.text = recording.displayName

        var status = ""
        var color = UIColor.blue
        if recording.isRecording {
            status = "Recording"
            color = UIColor.red
            accessoryType = .checkmark
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

        let size = ByteCountFormatter.string(fromByteCount: recording.size, countStyle: .file)
        detailTextLabel?.text = "\(recording.duration) • \(size) - \(status)"

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

        leftButtons = []
        rightButtons = []

        leftSwipeSettings.transition = .drag
        rightSwipeSettings.transition = .drag

        if !recording.isRecording {
            if !recording.uploading {
                if activityHandler.canUpload {
                    leftButtons.append(MGSwipeButton(title: "", icon: UIImage(named:"upload.png"),
                                                     backgroundColor: UIColor.white))
                    leftButtons.last!.tag = Button.upload.rawValue
                }
                rightButtons.append(MGSwipeButton(title: "Delete", backgroundColor: UIColor.red))
                rightButtons.last!.tag = Button.delete.rawValue
            }
            leftButtons.append(MGSwipeButton(title: "", icon: UIImage(named:"share.png"),
                                             backgroundColor: UIColor.white))
            leftButtons.last!.tag = Button.share.rawValue
        }
    }
}

extension RecordingTableViewCell: MGSwipeTableCellDelegate {

    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection,
                        fromExpansion: Bool) -> Bool {
        switch direction {
        case .rightToLeft: activityHandler.deleteRequest(button: rightButtons[index] as! UIButton, recording: recording)
        case .leftToRight:
            let button = leftButtons[index] as! UIButton
            if button.tag == Button.upload.rawValue {
                activityHandler.uploadRequest(button: button, recording: recording)
            }
            else if button.tag == Button.share.rawValue {
                activityHandler.shareRequest(button: button, recording: recording)
            }
        }
        return true
    }
}
