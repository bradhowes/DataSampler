//
//  UserSettings.swift
//  Blah
//
//  Created by Brad Howes on 9/19/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

protocol UserSettingsInterface {
    var notificationDriver: String { get set }
    var emitInterval: Int { get set }
    var maxHistogramBin: Int { get set }
    var useDropbox: Bool { get set }
    var dropboxLinkButtonText: String { get }
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
 Enumeration of string constants that will be used as keys into UserDefaults. Minimizes typos.
 */
public enum UserSettingName: String {
    case notificationDriver, emitInterval, maxHistogramBin, useDropbox, dropboxLinkButtonText, uploadAutomatically
    case remoteServerName, remoteServerPort, resendUntilFetched
    case apnsProdCertFileName, apnsProdCertPassword
    case apnsDevCertFileName, apnsDevCertPassword
}

/**
 Protocol for a user setting. Registers a default value for when a setting does not yet exist in
 UserDefaults.
 */
protocol SettingInterface {

    /// The name of the user setting
    var name: UserSettingName { get }
    var defaultValue: Any { get }
    var settingDescription: String { get }

    func read()
    func write()
}

/**
 Define converters between a Swift native type and one used for UserDefaults
 */
protocol ValueConverterInterface {

    /** 
     The native Swift type we wish to work in (eg `Int` or `String`)
     */
    associatedtype ValueType

    /**
     Convert a Swift native type value to NSObject-based type
     - parameter value: the value to convert
     - returns: the converted value
     */
    static func valueToAny(_ value: ValueType) -> Any

    /**
     Convert an NSObject-based type to a Swift native type.
     - parameter value: the value to convert
     - returns: the converted value
     */
    static func anyToValue(_ value: Any?) -> ValueType?
}

/**
 Define Int<->NSNumber converters
 */
struct IntValueConverter : ValueConverterInterface {
    static func valueToAny(_ value: Int) -> Any { return NSNumber(value: value) }
    static func anyToValue(_ value: Any?) -> Int? {
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
struct DoubleValueConverter : ValueConverterInterface {
    static func valueToAny(_ value: Double) -> Any { return NSNumber(value: value) }
    static func anyToValue(_ value: Any?) -> Double? {
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
struct StringValueConverter : ValueConverterInterface {
    static func valueToAny(_ value: String) -> Any { return NSString(utf8String: value)! }
    static func anyToValue(_ value: Any?) -> String? {
        return value != nil ? (value as! String) : nil
    }
}

/**
 Bool<->NSNumber converters
 */
struct BoolValueConverter : ValueConverterInterface {
    static func valueToAny(_ value: Bool) -> Any { return NSNumber(value: value) }
    static func anyToValue(_ value: Any?) -> Bool? {
        return value != nil ? (value as! NSNumber).boolValue : nil
    }
}

extension UserDefaults {
    subscript(key: UserSettingName) -> Any? {
        get { return object(forKey: key.rawValue) }
        set { set(newValue, forKey: key.rawValue) }
    }
}

/**
 Define a user setting that knows how to convert between a natural type (eg. Int or Double) and the type used to
 hold the value in the NSUserDefaults database.
 */
final class Setting<ValueType, VC: ValueConverterInterface>: SettingInterface, CustomDebugStringConvertible
    where ValueType: Equatable, ValueType == VC.ValueType {

    var name: UserSettingName
    var value: ValueType {
        didSet {
            let notification = UserSettingsChangedNotificationWith<ValueType>(name: name, oldValue: oldValue,
                                                                              newValue: value)
            print("didSet: \(name) old: \(oldValue) new: \(value)")
            notification.post(sender: self)
        }
    }

    var defaultValue: Any

    /**
     Initialize new instance

     - parameter key: the NSUserDefaults key for the user setting
     - parameter value: the initial value for the user setting if not present in NSUserDefaults
     */
    fileprivate init(name: UserSettingName, defaultValue: ValueType) {
        self.name = name
        self.value = VC.anyToValue(UserDefaults.standard[name] as Any?) ?? defaultValue
        self.defaultValue = VC.valueToAny(defaultValue)
    }

    func read() {
        if let value = VC.anyToValue(UserDefaults.standard[name]) {
            if self.value != value {
                self.value = value
            }
        }
        else {
            UserDefaults.standard[name] = defaultValue
        }
    }

    func write() {
        UserDefaults.standard[name] = VC.valueToAny(self.value)
    }

    /// Pretty-printed representation for the setting
    var description: String { return "<BRHSetting: '\(name)' '\(value)'>" }
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
final class UserSettings: UserSettingsInterface {

    private(set) var defaults: [String:Any] = [:]
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
    private var _dropboxLinkButtonText: StringSetting
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
        set {
            _useDropbox.value = newValue
            _dropboxLinkButtonText.value = dropboxLinkButtonText
        }
    }

    var dropboxLinkButtonText: String { return useDropbox ? "Unlink" : "Link" }

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
        _notificationDriver = StringSetting(name: .notificationDriver, defaultValue: "remote")
        _emitInterval = IntSetting(name: .emitInterval, defaultValue: 120)
        _maxHistogramBin = IntSetting(name: .maxHistogramBin, defaultValue: 30)
        _useDropbox = BoolSetting(name: .useDropbox, defaultValue: false)
        _dropboxLinkButtonText = StringSetting(name: .dropboxLinkButtonText, defaultValue: "Link")
        _uploadAutomatically = BoolSetting(name: .uploadAutomatically, defaultValue: true)
        _remoteServerName = StringSetting(name: .remoteServerName, defaultValue: "brhemitter.azurewebsites.net")
        _remoteServerPort = IntSetting(name: .remoteServerPort, defaultValue: 80)
        _resendUntilFetched = BoolSetting(name: .resendUntilFetched, defaultValue: true)
        _apnsProdCertFileName = StringSetting(name: .apnsProdCertFileName, defaultValue: "apn-nhtest-prod.p12")
        _apnsProdCertPassword = StringSetting(name: .apnsProdCertPassword, defaultValue: "")
        _apnsDevCertFileName = StringSetting(name: .apnsDevCertFileName, defaultValue: "apn-nhtest-dev.p12")
        _apnsDevCertPassword = StringSetting(name: .apnsDevCertPassword, defaultValue: "")

        register(_notificationDriver)
        register(_emitInterval)
        register(_maxHistogramBin)
        register(_useDropbox)
        register(_dropboxLinkButtonText)
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
        defaults[setting.name.rawValue] = setting.defaultValue
        settings[setting.name.rawValue] = setting
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
