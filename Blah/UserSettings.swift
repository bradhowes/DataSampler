//
//  UserSettings.swift
//  Blah
//
//  Created by Brad Howes on 9/19/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

/**
 Enumeration of string constants that will be used as keys into UserDefaults. Minimizes typos.
 */
private enum Tags: String {
    case notificationDriver, emitInterval, maxHistogramBin, dropboxLinkButtonText, uploadAutomatically
    case remoteServerName, remoteServerPort, resendUntilFetched
    case apnsProdCertFileName, apnsProdCertPassword
    case apnsDevCertFileName, apnsDevCertPassword
}

/**
 Allow the use of a `Tag` enum to initialize a `DefaultsKey` instance.
 */
private extension DefaultsKey {
    convenience init(tag: Tags) {
        self.init(tag.rawValue)
    }
}

// MARK: - Key definitions

/**
 Create keys in `DefaultsKeys` so that they can be used later on in indexing operations on `DefaultsKeys`.
 */
extension DefaultsKeys {
    static let notificationDriver = DefaultsKey<String>(tag: .notificationDriver)
    static let emitInterval = DefaultsKey<String>(tag: .emitInterval)
    static let maxHistogramBin = DefaultsKey<String>(tag: .maxHistogramBin)
    static let dropboxLinkButtonText = DefaultsKey<String>(tag: .dropboxLinkButtonText)
    static let uploadAutomatically = DefaultsKey<Bool>(tag: .uploadAutomatically)
    static let remoteServerName = DefaultsKey<String>(tag: .remoteServerName)
    static let remoteServerPort = DefaultsKey<String>(tag: .remoteServerPort)
    static let resendUntilFetched = DefaultsKey<Bool>(tag: .resendUntilFetched)
    static let apnsProdCertFileName = DefaultsKey<String>(tag: .apnsProdCertFileName)
    static let apnsProdCertPassword = DefaultsKey<String>(tag: .apnsProdCertPassword)
    static let apnsDevCertFileName = DefaultsKey<String>(tag: .apnsDevCertFileName)
    static let apnsDevCertPassword = DefaultsKey<String>(tag: .apnsDevCertPassword)
}

/**
 Define converters between a Swift native type and one used for UserDefaults.
 */
protocol ValueConverter {

    /** 
     The native Swift type we wish to work in (eg `Int` or `String`)
     */
    associatedtype ValueType

    /**
     Convert a Swift native type value to NSObject-based type
     - parameter value: the value to convert
     - returns: the converted value
     */
    static func valueToAnyObject(_ value: ValueType) -> AnyObject?

    /**
     Convert an NSObject-based type to a Swift native type.
     - parameter value: the value to convert
     - returns: the converted value
     */
    static func anyObjectToValue(_ value: AnyObject?) -> ValueType?
}

/**
 Define Int<->NSNumber converters
 */
struct IntValueConverter : ValueConverter {
    static func valueToAnyObject(_ value: Int) -> AnyObject? { return NSNumber(value: value as Int) }
    static func anyObjectToValue(_ value: AnyObject?) -> Int? {
        switch value {
        case let z as NSNumber: return z.intValue
        case let z as NSString: return Int(z as String)
        default: return nil
        }
    }
}

/**
 Double<->NSNumber converters
 */
struct DoubleValueConverter : ValueConverter {
    static func valueToAnyObject(_ value: Double) -> AnyObject? { return NSNumber(value: value as Double) }
    static func anyObjectToValue(_ value: AnyObject?) -> Double? {
        switch value {
        case let z as NSNumber: return z.doubleValue
        case let z as NSString: return Double(z as String)
        default: return nil
        }
    }
}

/**
 String<->String converters (no-op)
 */
struct StringValueConverter : ValueConverter {
    static func valueToAnyObject(_ value: String) -> AnyObject? { return NSString(utf8String: value) }
    static func anyObjectToValue(_ value: AnyObject?) -> String? {
        return value != nil ? (value as! String) : nil
    }
}

/**
 Bool<->NSNumber converters
 */
struct BoolValueConverter : ValueConverter {
    static func valueToAnyObject(_ value: Bool) -> AnyObject? { return NSNumber(value: value as Bool) }
    static func anyObjectToValue(_ value: AnyObject?) -> Bool? {
        return value != nil ? (value as! NSNumber).boolValue : nil
    }
}

/** 
 Description protocol for settings.
 */
protocol SettingDescription {

    /// Setting description getter
    var settingDescription: String { get }
}

/**
 Base class for all user settings. Registers a default value for when a setting does not yet exist in
 UserDefaults. Also registers two closures, one to write current setting value to NSUserDefaults and the other
 to set the current value from a NSUserDefaults entry.
 */
class SettingBase {
    typealias Synchro = ()->Void

    /// Mapping between setting name (key) and the default value to use when the setting does not exist in UserDefaults
    static var defaults: [String:AnyObject] = [:]
    /// Vector of functions to call to flush native values into `UserDefaults`
    static var writers: [Synchro] = []
    /// Vector of functions to call to load `UserDefaults` and convert into native values.
    static var readers: [Synchro] = []
    /// Collection of setting descriptors
    static var settings: [SettingDescription] = []

    /**
     Remove all previously-registered user settings.
     */
    static func reset() {
        defaults = [:]
        writers = []
        readers = []
        settings = []
    }

    /**
     Register a new setting
     - parameter key: the name of the setting
     - parameter value: default value to use if none exists
     - parameter writer: function to create an NSObject-derived value for storing in UserDefaults
     - parameter reader: function to create a native Swift type from UserDefaults value
     */
    func registerSetting(_ key: String, value: AnyObject?, writer: @escaping Synchro, reader: @escaping Synchro) {
        SettingBase.defaults[key] = value
        SettingBase.writers.append(writer)
        SettingBase.readers.append(reader)
    }

    /**
     Update NSUserDefaults using the internal values
     */
    static func write() {
        SettingBase.writers.forEach { $0() }
    }

    /**
     Update the internal values using contents from NSUserDefaults.
     */
    static func read() {
        SettingBase.readers.forEach { $0() }
    }
}

/**
 Define a user setting that knows how to convert between a natural type (eg. Int or Double) and the type used to
 hold the value in the NSUserDefaults database.
 */
final class Setting<ValueType, VC: ValueConverter>: SettingBase, SettingDescription, CustomDebugStringConvertible where
ValueType: Equatable, ValueType == VC.ValueType {

    let key: String
    let changedNotification: Notification.Name
    var value: ValueType

    /**
     Initialize new instance

     - parameter key: the NSUserDefaults key for the user setting
     - parameter value: the initial value for the user setting if not present in NSUserDefaults
     */
    fileprivate init(tag: Tags, value: ValueType) {
        self.key = tag.rawValue
        self.changedNotification = Notification.Name(rawValue: "UserSettings." + self.key)
        self.value = value
        super.init()
        SettingBase.settings.append(self)
        self.registerSetting(self.key, value: VC.valueToAnyObject(self.value),
                             writer: {
                                Defaults[self.key] = VC.valueToAnyObject(self.value)
            },
                             reader: {
                                if let value = VC.anyObjectToValue(Defaults.object(forKey: self.key) as AnyObject?) {
                                    if self.value != value {
                                        print("-- setting \(self.key) changed - old: \(self.value) new: \(value)")
                                        self.value = value
                                        NotificationCenter.default.post(name: self.changedNotification,
                                                                        object: self,
                                                                        userInfo: ["old": self.value, "new": value])
                                    }
                                }
                                else {
                                    Defaults[self.key] = VC.valueToAnyObject(self.value)
                                }
        })
    }
    
    /// Pretty-printed representation for the setting
    var description: String { return "<BRHSetting: '\(key)' '\(value)'>" }
    /// Debugger representation for the setting
    var debugDescription: String { return description }
    /// Internal representation for the setting
    var settingDescription: String { return description }
}

typealias StringSetting = Setting<String, StringValueConverter>
typealias IntSetting = Setting<Int, IntValueConverter>
typealias DoubleSetting = Setting<Double, DoubleValueConverter>
typealias BoolSetting = Setting<Bool, BoolValueConverter>

/**
 Collection of all user settings.
 */
final class UserSettings {
    static let singleton: UserSettings = UserSettings()
    static let updatedNotification = Notification.Name(rawValue: "UserSettings.updatedNotification")

    var notificationDriver: StringSetting
    var emitInterval: IntSetting
    var maxHistogramBin: IntSetting
    var dropboxLinkButtonText: StringSetting
    var uploadAutomatically: BoolSetting
    var remoteServerName: StringSetting
    var remoteServerPort: IntSetting
    var resendUntilFetched: BoolSetting
    var apnsProdCertFileName: StringSetting
    var apnsProdCertPassword: StringSetting
    var apnsDevCertFileName: StringSetting
    var apnsDevCertPassword: StringSetting

    /**
     Initialize user settings collection. Sets up default values in NSUserDefaults.
     */
    private init() {
        SettingBase.reset()
        notificationDriver = StringSetting(tag: .notificationDriver, value: "remote")
        emitInterval = IntSetting(tag: .emitInterval, value: 120)
        maxHistogramBin = IntSetting(tag: .maxHistogramBin, value: 30)
        dropboxLinkButtonText = StringSetting(tag: .dropboxLinkButtonText, value: "Link")
        uploadAutomatically = BoolSetting(tag: .uploadAutomatically, value: true)
        remoteServerName = StringSetting(tag: .remoteServerName, value: "brhemitter.azurewebsites.net")
        remoteServerPort = IntSetting(tag: .remoteServerPort, value: 80)
        resendUntilFetched = BoolSetting(tag: .resendUntilFetched, value: true)
        apnsProdCertFileName = StringSetting(tag: .apnsProdCertFileName, value: "apn-nhtest-prod.p12")
        apnsProdCertPassword = StringSetting(tag: .apnsProdCertPassword, value: "")
        apnsDevCertFileName = StringSetting(tag: .apnsDevCertFileName, value: "apn-nhtest-dev.p12")
        apnsDevCertPassword = StringSetting(tag: .apnsDevCertPassword, value: "")
        Defaults.register(defaults: SettingBase.defaults)
        read()
        dump()
    }

    /**
     Update NSUserDefaults using the internal values
     */
    func write() {
        SettingBase.write()
    }

    /**
     Update the internal values using contents from NSUserDefaults.
     */
    func read() {
        SettingBase.read()
        NotificationCenter.default.post(name: UserSettings.updatedNotification, object: self, userInfo: nil)
        dump()
    }

    /**
     Print out the current application settings.
     */
    func dump() {
        SettingBase.settings.forEach { print($0.settingDescription) }
    }
}

/** 
 Create shortcuts in the UserSettings class so we don't have to type '.singleton'
 */
extension UserSettings {
    static var notificationDriver: String { return singleton.notificationDriver.value }
    static var emitInterval: Int { return singleton.emitInterval.value }
    static var maxHistogramBin: Int { return singleton.maxHistogramBin.value }
    static var dropboxLinkButtonText: String { return singleton.dropboxLinkButtonText.value }
    static var uploadAutomatically: Bool { return singleton.uploadAutomatically.value }
    static var remoteServerName: String { return singleton.remoteServerName.value }
    static var remoteServerPort: Int { return singleton.remoteServerPort.value }
    static var resendUntilFetched: Bool { return singleton.resendUntilFetched.value }
    static var apnsProdCertFileName: String { return singleton.apnsDevCertFileName.value }
    static var apnsProdCertPassword: String { return singleton.apnsProdCertPassword.value }
    static var apnsDevCertFileName: String { return singleton.apnsDevCertFileName.value }
    static var apnsDevCertPassword: String { return singleton.apnsDevCertPassword.value }
}
