//
//  BRHTextRecorder.swift
//  Blah
//
//  Created by Brad Howes on 9/26/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import UIKit

class TextRecorder: NSObject, UITextViewDelegate {

    private(set) var isHistorical: Bool

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

    private(set) var fileName: String
    private(set) var logText = NSMutableString()

    private var dateTimeFormatter: DateFormatter
    private var scrollToEnd: Bool

    internal init(fileName: String) {
        self.isHistorical = false
        self.fileName = fileName
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.setLocalizedDateFormatFromTemplate("HH:mm:ss.SSS")
        self.scrollToEnd = true
    }

    public func save(to: URL, done: @escaping (Int64)->() ) {
        let logPath = to.appendingPathComponent(fileName)
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
                tv.scrollRangeToVisible(NSMakeRange(self.logText.length, 0))
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
        return dateTimeFormatter.string(from: Date())
    }

    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollToEnd = false
    }

    internal func add(_ line: String) {
        guard !isHistorical else { return }
        synchronized(obj: self) {
            logText.append(line)
            guard let textView = self.textView else { return }
            DispatchQueue.main.async {
                let fromBottom = textView.contentSize.height - textView.contentOffset.y - 2 * textView.bounds.size.height
                textView.textStorage.append(NSAttributedString(string: line, attributes: textView.typingAttributes))
                if fromBottom < 0 || self.scrollToEnd {
                    self.scrollToEnd = true
                    textView.scrollRangeToVisible(NSMakeRange(textView.textStorage.length, 0))
                }
            }
        }
    }
}
