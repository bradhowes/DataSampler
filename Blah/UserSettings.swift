//
//  BRHUserSettings.swift
//  Blah
//
//  Created by Brad Howes on 9/19/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

private enum Tags: String {
    case notificationDriver, emitInterval, maxHistogramBin, dropboxLinkButtonText, uploadAutomatically
    case remoteServerName, remoteServerPort, resendUntilFetched
    case apnsProdCertFileName, apnsProdCertPassword
    case apnsDevCertFileName, apnsDevCertPassword
}

private extension DefaultsKey {
    convenience init(tag: Tags) {
        self.init(tag.rawValue)
    }
}

// MARK: - Key definitions
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
 @brief Define converters between a natural type and the one use when storing in NSUserDefaults.
 */
protocol ValueConverter {
    associatedtype ValueType
    associatedtype DefaultsType
    
    /**
     Convert a NSUserDefaults value to a natural type
     
     - parameter value: the value to convert
     
     - returns: the converted value
     */
    static func defaultsToValue(_ value: DefaultsType) -> ValueType?
    /**
     Convert a natural type value to the NSUserDefaults one
     
     - parameter value: the value to convert
     
     - returns: the converted value
     */
    static func valueToDefaults(_ value: ValueType) -> DefaultsType

    static func valueToAnyObject(_ value: ValueType) -> AnyObject?
    static func anyObjectToValue(_ value: AnyObject?) -> ValueType?
}

/**
 @brief Define Int<->String converters
 */
struct IntValueConverter : ValueConverter {
    static func defaultsToValue(_ value: String) -> Int? { return Int(value) }
    static func valueToDefaults(_ value: Int) -> String { return String(value) }
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
 @brief Define Double<->String converters
 */
struct DoubleValueConverter : ValueConverter {
    static func defaultsToValue(_ value: String) -> Double? { return Double(value) }
    static func valueToDefaults(_ value: Double) -> String { return String(value) }
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
 @brief Define String<->String converters (no-op)
 */
struct StringValueConverter : ValueConverter {
    static func defaultsToValue(_ value: String) -> String? { return value }
    static func valueToDefaults(_ value: String) -> String { return value }
    static func valueToAnyObject(_ value: String) -> AnyObject? { return NSString(utf8String: value) }
    static func anyObjectToValue(_ value: AnyObject?) -> String? {
        return value != nil ? (value as! String) : nil
    }
}

/**
 @brief Define Bool<->Bool converters (no-op)
 */
struct BoolValueConverter : ValueConverter {
    static func defaultsToValue(_ value: Bool) -> Bool? { return value }
    static func valueToDefaults(_ value: Bool) -> Bool { return value }
    static func valueToAnyObject(_ value: Bool) -> AnyObject? { return NSNumber(value: value as Bool) }
    static func anyObjectToValue(_ value: AnyObject?) -> Bool? {
        return value != nil ? (value as! NSNumber).boolValue : nil
    }
}

protocol SettingDescription {
    var settingDescription: String { get }
}

/**
 @brief Base class for all user settings. Registers a default value for when a setting does not yet exist in
 NSUserDefaults. Also registers two closures, one to write current setting value to NSUserDefaults and the other
 to set the current value from a NSUserDefaults entry.
 */
class SettingBase {
    typealias Synchro = ()->Void
    static var defaults: [String:AnyObject] = [:]
    static var syncToUserDefaultsSynchros: [Synchro] = []
    static var syncFromUserDefaultsSynchros: [Synchro] = []
    static var settings: [SettingDescription] = []

    static func reset() {
        defaults = [:]
        syncToUserDefaultsSynchros = []
        syncFromUserDefaultsSynchros = []
        settings = []
    }

    func registerSetting(_ key: String, value: AnyObject?,
                         syncToUserDefaults: @escaping Synchro,
                         syncFromUserDefaults: @escaping Synchro) {
        SettingBase.defaults[key] = value
        SettingBase.syncToUserDefaultsSynchros.append(syncToUserDefaults)
        SettingBase.syncFromUserDefaultsSynchros.append(syncFromUserDefaults)
    }

    /**
     Update NSUserDefaults using the internal values
     */
    static func syncToUserDefaults() {
        SettingBase.syncToUserDefaultsSynchros.forEach { $0() }
    }
    /**
     Update the internal values using contents from NSUserDefaults.
     */
    static func syncFromUserDefaults() {
        for (index, synchro) in SettingBase.syncFromUserDefaultsSynchros.enumerated() {
            print("\(index)")
            synchro()
        }
        // BRHSettingBase.syncFromUserDefaultsSynchros.forEach { $0() }
    }
}

/**
 @brief Define a user setting that knows how to convert between a natural type (eg. Int or Double) and the type used to
 hold the value in the NSUserDefaults database.
 */
final class Setting<ValueType, DefaultsType, VC: ValueConverter> : SettingBase, SettingDescription, CustomDebugStringConvertible where ValueType: Equatable, ValueType == VC.ValueType, DefaultsType == VC.DefaultsType {

    let key: String
    let notificationName: Notification.Name
    var value: ValueType
    var defaultsValue: DefaultsType { return VC.valueToDefaults(self.value) }

    /**
     Initialize new instance

     - parameter key: the NSUserDefaults key for the user setting
     - parameter value: the initial value for the user setting if not present in NSUserDefaults
     */
    fileprivate init(tag: Tags, value: ValueType) {
        self.key = tag.rawValue
        self.notificationName = Notification.Name(rawValue: "BRHUserSettings." + self.key)
        self.value = value
        super.init()
        SettingBase.settings.append(self)
        self.registerSetting(self.key, value: VC.valueToAnyObject(self.value),
                             syncToUserDefaults: {
                                Defaults[self.key] = VC.valueToAnyObject(self.value)
            },
                             syncFromUserDefaults: {
                                if let value = VC.anyObjectToValue(Defaults.object(forKey: self.key) as AnyObject?) {
                                    if self.value != value {
                                        print("-- setting \(self.key) changed - old: \(self.value) new: \(value)")
                                        self.value = value
                                        NotificationCenter.default.post(name: self.notificationName,
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

typealias StringSetting = Setting<String, String, StringValueConverter>
typealias IntSetting = Setting<Int, String, IntValueConverter>
typealias DoubleSetting = Setting<Double, String, DoubleValueConverter>
typealias BoolSetting = Setting<Bool, Bool, BoolValueConverter>

/**
 @brief Collection of all user settings.
 */
final class UserSettings {
    static let singleton: UserSettings = UserSettings()
    static let kUpdatedNotification = Notification.Name(rawValue: "UserSettingsUpdated")

    private var _notificationDriver: StringSetting
    var notificationDriver: String {
        get { return _notificationDriver.value }
        set { _notificationDriver.value = newValue }
    }

    private var _emitInterval: IntSetting
    var emitInterval: Int {
        get { return _emitInterval.value }
        set { _emitInterval.value = newValue }
    }

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
        _notificationDriver = StringSetting(tag: .notificationDriver, value: "remote")
        _emitInterval = IntSetting(tag: .emitInterval, value: 120)

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
        syncFromUserDefaults()
        dump()
    }

    /**
     Update NSUserDefaults using the internal values
     */
    func syncToUserDefaults() {
        SettingBase.syncToUserDefaults()
    }
    
    /**
     Update the internal values using contents from NSUserDefaults.
     */
    func syncFromUserDefaults() {
        SettingBase.syncFromUserDefaults()
        NotificationCenter.default.post(name: UserSettings.kUpdatedNotification, object: self, userInfo: nil)
        dump()
    }

    /**
     Print out the current application settings.
     */
    func dump() {
        SettingBase.settings.forEach { print($0.settingDescription) }
    }
}
