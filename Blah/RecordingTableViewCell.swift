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

final class RecordingTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var detail: UITextView!
}

extension RecordingTableViewCell: ConfigurableCell {

    func configure(dataSource recording: Recording) {

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
    }
}
