//
//  BRHTextRecorder.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit

class BRHTextRecorder: NSObject, UITextViewDelegate{

    var textView: UITextView? {
        willSet {
            textView?.delegate = nil
        }
        didSet {
            guard let tv = textView else { return }
            tv.delegate = self
            tv.text = String(validatingUTF8: logText.utf8String!) ?? ""
            tv.scrollRangeToVisible(NSMakeRange(logText.length, 0))
        }
    }

    private func writeLog(timer: Timer?) {
        guard let logPath = self.logPath else { return }
        if timer == nil {
            flushTimer?.invalidate()
        }

        flushTimer = nil

        guard let s = String(validatingUTF8: logText.utf8String!) else { return }
        let block = {
            do {
                try s.write(to: logPath, atomically: false, encoding: .utf8)
            } catch {
                print("*** failed to write to \(logPath)")
            }
        }

        if timer != nil {
            DispatchQueue.global().async(execute: block)
        }
        else {
            DispatchQueue.global().sync(execute: block)
        }
    }

    var logPath: URL? {
        didSet {
            if oldValue != nil { writeLog(timer: nil) }
            if logPath != nil {
                logPath = logPath?.appendingPathComponent(fileName)
                writeLog(timer: nil)
            }
        }
    }

    private var fileName: String
    private var logText = NSMutableString()
    private var dateTimeFormatter: DateFormatter
    private var flushTimer: Timer?
    private var saveInterval: TimeInterval
    private var scrollToEnd: Bool

    internal init(fileName: String) {
        self.logPath = nil
        self.fileName = fileName
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.setLocalizedDateFormatFromTemplate("HH:mm:ss.SSS")
        self.flushTimer = nil
        self.saveInterval = 5.0
        self.scrollToEnd = true
    }

    deinit {
        flushTimer?.invalidate()
    }

    internal func save() {
        writeLog(timer: nil)
    }
    
    internal func clear() {
        logPath = nil
        logText = ""
    }

    func logPathFor(folder: URL) -> URL {
        return folder.appendingPathComponent(fileName)
    }
    
    func logContentFor(folder: URL) -> String {
        do {
            return try String(contentsOf: logPathFor(folder: folder), encoding: .utf8)
        }
        catch {
            return ""
        }
    }

    private func flushToDisk() {
        if flushTimer == nil {
            flushTimer = Timer(fire: Date(), interval: saveInterval, repeats: false, block: { timer in
                self.writeLog(timer: timer)
            })
        }
    }

    func timestamp() -> String {
        return dateTimeFormatter.string(from: Date())
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollToEnd = false
    }

    internal func add(_ line: String) {
        logText.append(line)
        guard let textView = self.textView else { return }
        let when = DispatchTime.now()
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            let fromBottom = textView.contentSize.height - textView.contentOffset.y - 2 * textView.bounds.size.height
            textView.textStorage.append(NSAttributedString(string: line, attributes: textView.typingAttributes))
            if fromBottom < 0 || self.scrollToEnd {
                self.scrollToEnd = true
                textView.scrollRangeToVisible(NSMakeRange(textView.textStorage.length, 0))
            }
        })
    
        flushToDisk()
    }
}
