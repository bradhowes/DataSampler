//
//  BRHTextRecorder.swift
//  DataSampler
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit

/** 
 Instances of TextRecorder accumulate lines of text, optionally showing them in a UITextView. The API supports saving
 to and restoring from files on disk.
 */
class TextRecorder: NSObject, UITextViewDelegate {

    /// The UITextView to show recorded text
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

    var timestampGenerator: TimestampGeneratorInterface

    /// If true, no additional data is recorded.
    private(set) var isHistorical: Bool

    /// The name of the file to use when reading/writing to disk
    private(set) var fileName: String

    /// Holds the accumulated text
    private(set) var logText = NSMutableString()

    private var scrollToEnd: Bool

    internal init(fileName: String, timestampGenerator: TimestampGeneratorInterface) {
        self.isHistorical = false
        self.fileName = fileName
        self.timestampGenerator = timestampGenerator
        self.scrollToEnd = true
    }

    public func save(to: URL, done: @escaping (Int64)->() ) {
        let logPath = to.appendingPathComponent(fileName)
        Logger.log("writing to \(logPath)")
        guard let s = String(validatingUTF8: logText.utf8String!) else { return }
        do {
            try s.write(to: logPath, atomically: false, encoding: .utf8)
        } catch {
            print("*** failed to write to \(logPath)")
        }
        done(Int64(s.unicodeScalars.count / 4))
    }

    public func restore(from: URL) {
        let logPath = from.appendingPathComponent(fileName)
        do {
            self.isHistorical = true
            let s = try String(contentsOf: logPath)
            self.logText = NSMutableString(string: s)
            DispatchQueue.main.async {
                guard let tv = self.textView else { return }
                tv.text = String(validatingUTF8: s) ?? ""
                tv.scrollRangeToVisible(NSMakeRange(0, 0))
            }
        } catch {
            Logger.log("*** failed to restore text from \(logPath)")
        }
    }

    public func clear() {
        isHistorical = false
        logText = ""
        DispatchQueue.main.async {
            self.textView?.text = ""
        }
    }

    internal func timestamp() -> String {
        return timestampGenerator.value
    }

    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollToEnd = false
    }

    /**
     Add a line to the internal text string and to any attached text view.
     - parameter line: the line to add
     - returns: the line that was added
     */
    internal func add(_ line: String) -> String {

        // Don't manipulate log if we are in read-only mode
        //
        guard !isHistorical else { return line }

        // Thread-safe manipulation of state.
        //
        synchronized(obj: self) {

            // Remember the line
            //
            logText.append(line)
            guard let textView = self.textView else { return }

            // Add the line to the associated UITextView instance
            //
            DispatchQueue.main.async {
                let fromBottom = textView.contentSize.height - textView.contentOffset.y - 2 * textView.bounds.size.height
                textView.textStorage.append(NSAttributedString(string: line, attributes: textView.typingAttributes))
                if fromBottom < 0 || self.scrollToEnd {
                    self.scrollToEnd = true
                    textView.scrollRangeToVisible(NSMakeRange(textView.textStorage.length, 0))
                }
            }
        }
        return line
    }
}
