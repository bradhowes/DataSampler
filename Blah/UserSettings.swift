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
    case notificationDriver, emitInterval, maxHistogramBin, useDropbox, uploadAutomatically
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
    static let emitInterval = DefaultsKey<Int>(tag: .emitInterval)
    static let maxHistogramBin = DefaultsKey<Int>(tag: .maxHistogramBin)
    static let useDropbox = DefaultsKey<Bool>(tag: .useDropbox)
    static let uploadAutomatically = DefaultsKey<Bool>(tag: .uploadAutomatically)
    static let remoteServerName = DefaultsKey<String>(tag: .remoteServerName)
    static let remoteServerPort = DefaultsKey<Int>(tag: .remoteServerPort)
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
    static func valueToAnyObject(_ value: ValueType) -> AnyObject

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
    static func valueToAnyObject(_ value: Int) -> AnyObject { return NSNumber(value: value as Int) }
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
    static func valueToAnyObject(_ value: Double) -> AnyObject { return NSNumber(value: value as Double) }
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
    static func valueToAnyObject(_ value: String) -> AnyObject { return NSString(utf8String: value)! }
    static func anyObjectToValue(_ value: AnyObject?) -> String? {
        return value != nil ? (value as! String) : nil
    }
}

/**
 Bool<->NSNumber converters
 */
struct BoolValueConverter : ValueConverter {
    static func valueToAnyObject(_ value: Bool) -> AnyObject { return NSNumber(value: value as Bool) }
    static func anyObjectToValue(_ value: AnyObject?) -> Bool? {
        return value != nil ? (value as! NSNumber).boolValue : nil
    }
}

/**
 Base class for all user settings. Registers a default value for when a setting does not yet exist in
 UserDefaults. Also registers two closures, one to write current setting value to NSUserDefaults and the other
 to set the current value from a NSUserDefaults entry.
 */
protocol SettingInterface {

    var key: String { get }
    var defaultValue: AnyObject { get }
    var settingDescription: String { get }

    func read()
    func write()
}

/**
 Define a user setting that knows how to convert between a natural type (eg. Int or Double) and the type used to
 hold the value in the NSUserDefaults database.
 */
final class Setting<ValueType, VC: ValueConverter>: SettingInterface, CustomDebugStringConvertible where
ValueType: Equatable, ValueType == VC.ValueType {

    var key: String
    var value: ValueType {
        didSet {
            let notification = UserSettingsChangedNotification(name: key, oldValue: oldValue, newValue: value)
            print("didSet: \(key) old: \(oldValue) new: \(value)")
            notification.post(sender: self)
        }
    }
    var defaultValue: AnyObject

    /**
     Initialize new instance

     - parameter key: the NSUserDefaults key for the user setting
     - parameter value: the initial value for the user setting if not present in NSUserDefaults
     */
    fileprivate init(tag: Tags, defaultValue: ValueType) {
        self.key = tag.rawValue
        self.value = VC.anyObjectToValue(Defaults.object(forKey: key) as AnyObject?) ?? defaultValue
        self.defaultValue =  VC.valueToAnyObject(defaultValue)
    }

    func read() {
        if let value = VC.anyObjectToValue(Defaults.object(forKey: self.key) as AnyObject?) {
            if self.value != value {
                self.value = value
            }
        }
        else {
            Defaults[self.key] = defaultValue
        }
    }

    func write() {
        Defaults[self.key] = VC.valueToAnyObject(self.value)
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

protocol UserSettingsInterface {
    var notificationDriver: String { get set }
    var emitInterval: Int { get set }
    var maxHistogramBin: Int { get set }
    var useDropbox: Bool { get set }
    var uploadAutomatically: Bool { get set }
    var remoteServerName: String { get set }
    var remoteServerPort: Int { get set }
    var resendUntilFetched: Bool { get set }
    var apnsProdCertFileName: String { get set }
    var apnsProdCertPassword: String { get set }
    var apnsDevCertFileName: String { get set }
    var apnsDevCertPassword: String { get set }

    func dump()
    func read()
    func write()
}

/**
 Collection of all user settings.
 */
final class UserSettings: UserSettingsInterface {

    private var defaults: [String:AnyObject] = [:]
    private(set) var settings: [String:SettingInterface] = [:]

    /**
     Remove all previously-registered user settings.
     */
    func reset() {
        defaults = [:]
        settings = [:]
    }

    private var _notificationDriver: StringSetting
    private var _emitInterval: IntSetting
    private var _maxHistogramBin: IntSetting
    private var _useDropbox: BoolSetting
    private var _uploadAutomatically: BoolSetting
    private var _remoteServerName: StringSetting
    private var _remoteServerPort: IntSetting
    private var _resendUntilFetched: BoolSetting
    private var _apnsProdCertFileName: StringSetting
    private var _apnsProdCertPassword: StringSetting
    private var _apnsDevCertFileName: StringSetting
    private var _apnsDevCertPassword: StringSetting

    var notificationDriver: String {
        get { return self._notificationDriver.value }
        set { self._notificationDriver.value = newValue }
    }

    var emitInterval: Int {
        get { return self._emitInterval.value }
        set { self._emitInterval.value = newValue }
    }

    var maxHistogramBin: Int {
        get { return self._maxHistogramBin.value }
        set { self._maxHistogramBin.value = newValue }
    }

    var useDropbox: Bool {
        get { return self._useDropbox.value }
        set { self._useDropbox.value = newValue }
    }

    var uploadAutomatically: Bool {
        get { return self._uploadAutomatically.value }
        set { self._uploadAutomatically.value = newValue }
    }

    var remoteServerName: String {
        get { return self._remoteServerName.value }
        set { self._remoteServerName.value = newValue }
    }

    var remoteServerPort: Int {
        get { return self._remoteServerPort.value }
        set { self._remoteServerPort.value = newValue }
    }

    var resendUntilFetched: Bool {
        get { return self._resendUntilFetched.value }
        set { self._resendUntilFetched.value = newValue }
    }

    var apnsProdCertFileName: String {
        get { return self._apnsProdCertFileName.value }
        set { self._apnsProdCertFileName.value = newValue }
    }

    var apnsProdCertPassword: String {
        get { return self._apnsProdCertPassword.value }
        set { self._apnsProdCertPassword.value = newValue }
    }

    var apnsDevCertFileName: String {
        get { return self._apnsProdCertFileName.value }
        set { self._apnsProdCertFileName.value = newValue }
    }

    var apnsDevCertPassword: String {
        get { return self._apnsDevCertPassword.value }
        set { self._apnsDevCertPassword.value = newValue }
    }

    /**
     Initialize user settings collection. Sets up default values in NSUserDefaults.
     */
    init() {
        _notificationDriver = StringSetting(tag: .notificationDriver, defaultValue: "remote")
        _emitInterval = IntSetting(tag: .emitInterval, defaultValue: 120)
        _maxHistogramBin = IntSetting(tag: .maxHistogramBin, defaultValue: 30)
        _useDropbox = BoolSetting(tag: .useDropbox, defaultValue: false)
        _uploadAutomatically = BoolSetting(tag: .uploadAutomatically, defaultValue: true)
        _remoteServerName = StringSetting(tag: .remoteServerName, defaultValue: "brhemitter.azurewebsites.net")
        _remoteServerPort = IntSetting(tag: .remoteServerPort, defaultValue: 80)
        _resendUntilFetched = BoolSetting(tag: .resendUntilFetched, defaultValue: true)
        _apnsProdCertFileName = StringSetting(tag: .apnsProdCertFileName, defaultValue: "apn-nhtest-prod.p12")
        _apnsProdCertPassword = StringSetting(tag: .apnsProdCertPassword, defaultValue: "")
        _apnsDevCertFileName = StringSetting(tag: .apnsDevCertFileName, defaultValue: "apn-nhtest-dev.p12")
        _apnsDevCertPassword = StringSetting(tag: .apnsDevCertPassword, defaultValue: "")

        register(_notificationDriver)
        register(_emitInterval)
        register(_maxHistogramBin)
        register(_useDropbox)
        register(_uploadAutomatically)
        register(_remoteServerName)
        register(_remoteServerPort)
        register(_resendUntilFetched)
        register(_apnsProdCertFileName)
        register(_apnsProdCertPassword)
        register(_apnsDevCertFileName)
        register(_apnsDevCertPassword)

        UserDefaults.standard.register(defaults: defaults)

        read()
        dump()
    }

    func register(_ setting: SettingInterface) {
        defaults[setting.key] = setting.defaultValue
        settings[setting.key] = setting
    }

    /**
     Update NSUserDefaults using the internal values
     */
    func write() {
        settings.forEach { $1.write() }
    }

    /**
     Update the internal values using contents from NSUserDefaults.
     */
    func read() {
        settings.forEach { $1.read() }
        dump()
    }

    /**
     Print out the current application settings.
     */
    func dump() {
        settings.forEach { print("\($0)") }
    }
}
