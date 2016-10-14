//
//  UserSettings.swift
//  Blah
//
//  Created by Brad Howes on 9/19/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Enumeration of user setting names.
 */
public enum UserSettingName: String {
    case notificationDriver, emitInterval, maxHistogramBin, useDropbox, dropboxLinkButtonText, uploadAutomatically
    case remoteServerName, remoteServerPort, resendUntilFetched
    case apnsProdCertFileName, apnsProdCertPassword
    case apnsDevCertFileName, apnsDevCertPassword
}

/**
 Protocol for a user setting. Note that the interface has no means of returning a value, though we can get the 
 default value.
 */
public protocol SettingInterface {

    /// The name of the user setting
    var name: UserSettingName { get }
    /// The default value to use if not found in UserDefaults
    var defaultValue: Any { get }
    // A printable description of the setting
    var settingDescription: String { get }

    /**
     Read the value from UserDefaults and use it
     */
    func read()

    /**
     Write the held value to UserDefaults
     */
    func write()
}

/**
 Define converters between a Swift native type and one used for UserDefaults
 */
private protocol ValueConverterInterface {

    /** 
     The native Swift type we wish to work in (eg `Int` or `String`)
     */
    associatedtype ValueType

    /**
     Convert a Swift native type value to Any type
     - parameter value: the value to convert
     - returns: the converted value
     */
    static func valueToAny(_ value: ValueType) -> Any

    /**
     Convert Any type to a Swift native type.
     - parameter value: the value to convert
     - returns: the converted value or nil if unable to convert
     */
    static func anyToValue(_ value: Any?) -> ValueType?
}

extension UserDefaults {

    /**
     Allow indexing into UserDefaults via UserSettingName enumeration
     */
    subscript(key: UserSettingName) -> Any? {
        get { return object(forKey: key.rawValue) }
        set { set(newValue, forKey: key.rawValue) }
    }
}

/**
 Define a user setting that knows how to convert between a natural type (eg. Int or Double) and the type used to
 hold the value in the UserDefaults database.
 */
private final class Setting<ValueType, VC: ValueConverterInterface>: SettingInterface, CustomDebugStringConvertible
where ValueType: Equatable, ValueType == VC.ValueType {

    /// The name of the setting
    var name: UserSettingName

    /// The current value of the setting
    var value: ValueType {

        /** 
         Emit a notification when the setting value changes
         */
        didSet {
            let notification = UserSettingsChangedNotificationWith<ValueType>(name: name, oldValue: oldValue,
                                                                              newValue: value)
            print("didSet: \(name) old: \(oldValue) new: \(value)")
            notification.post(sender: self)
        }
    }

    /// Default value to use if the setting does not exist in UserDefaults
    var defaultValue: Any
    /// Pretty-printed representation for the setting
    var description: String { return "<Setting: '\(name)' '\(value)'>" }
    /// Debugger representation for the setting
    var debugDescription: String { return description }
    /// Internal representation for the setting
    var settingDescription: String { return description }

    /**
     Initialize new instance

     - parameter name: the name of the user setting
     - parameter defaultValue: the value for the setting if not present in UserDefaults
     */
    fileprivate init(name: UserSettingName, defaultValue: ValueType) {
        self.name = name
        self.value = VC.anyToValue(UserDefaults.standard[name] as Any?) ?? defaultValue
        self.defaultValue = VC.valueToAny(defaultValue)
    }

    /**
     Update held setting with value from UserDefaults
     */
    fileprivate func read() {
        if let value = VC.anyToValue(UserDefaults.standard[name]) {
            if self.value != value {
                self.value = value
            }
        }
        else {
            UserDefaults.standard[name] = defaultValue
        }
    }

    /** 
     Update UserDefaults with the currently-held value
     */
    fileprivate func write() {
        UserDefaults.standard[name] = VC.valueToAny(self.value)
    }
}

/**
 Collection of all user settings.
 */
final class UserSettings: UserSettingsInterface {

    internal var dependentType: Any.Type { return UserSettingsDependent.self }

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

    var count: Int { return settings.count }

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

        settings.append(_notificationDriver)
        settings.append(_emitInterval)
        settings.append(_maxHistogramBin)
        settings.append(_useDropbox)
        settings.append(_dropboxLinkButtonText)
        settings.append(_uploadAutomatically)
        settings.append(_remoteServerName)
        settings.append(_remoteServerPort)
        settings.append(_resendUntilFetched)
        settings.append(_apnsProdCertFileName)
        settings.append(_apnsProdCertPassword)
        settings.append(_apnsDevCertFileName)
        settings.append(_apnsDevCertPassword)

        var defaults = [String:Any]()
        settings.forEach { defaults[$0.name.rawValue] = $0.defaultValue }
        UserDefaults.standard.register(defaults: defaults)

        read()
        dump()
    }

    /**
     Update NSUserDefaults using the internal values
     */
    func write() {
        settings.forEach { $0.write() }
    }

    /**
     Update the internal values using contents from NSUserDefaults.
     */
    func read() {
        settings.forEach { $0.read() }
        dump()
    }

    /**
     Print out the current application settings.
     */
    func dump() {
        settings.forEach { print("\($0)") }
    }

    private var settings: [SettingInterface] = []

    private typealias StringSetting = Setting<String, StringValueConverter>
    private typealias IntSetting = Setting<Int, IntValueConverter>
    private typealias DoubleSetting = Setting<Double, DoubleValueConverter>
    private typealias BoolSetting = Setting<Bool, BoolValueConverter>
    
    /**
     Define Int<->NSNumber converter
     */
    private struct IntValueConverter : ValueConverterInterface {
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
     Double<->NSNumber converter
     */
    private struct DoubleValueConverter : ValueConverterInterface {
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
     String<->String converter (no-op)
     */
    private struct StringValueConverter : ValueConverterInterface {
        static func valueToAny(_ value: String) -> Any { return NSString(utf8String: value)! }
        static func anyToValue(_ value: Any?) -> String? {
            return value != nil ? (value as! String) : nil
        }
    }

    /**
     Bool<->NSNumber converter
     */
    private struct BoolValueConverter : ValueConverterInterface {
        static func valueToAny(_ value: Bool) -> Any { return NSNumber(value: value) }
        static func anyToValue(_ value: Any?) -> Bool? {
            return value != nil ? (value as! NSNumber).boolValue : nil
        }
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

}
