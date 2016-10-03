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
protocol BRHValueConverter {
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
struct BRHIntValueConverter : BRHValueConverter {
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
struct BRHDoubleValueConverter : BRHValueConverter {
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
struct BRHStringValueConverter : BRHValueConverter {
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
struct BRHBoolValueConverter : BRHValueConverter {
    static func defaultsToValue(_ value: Bool) -> Bool? { return value }
    static func valueToDefaults(_ value: Bool) -> Bool { return value }
    static func valueToAnyObject(_ value: Bool) -> AnyObject? { return NSNumber(value: value as Bool) }
    static func anyObjectToValue(_ value: AnyObject?) -> Bool? {
        return value != nil ? (value as! NSNumber).boolValue : nil
    }
}

protocol BRHSettingDescription {
    var settingDescription: String { get }
}

/**
 @brief Base class for all user settings. Registers a default value for when a setting does not yet exist in
 NSUserDefaults. Also registers two closures, one to write current setting value to NSUserDefaults and the other
 to set the current value from a NSUserDefaults entry.
 */
class BRHSettingBase {
    typealias Synchro = ()->Void
    static var defaults: [String:AnyObject] = [:]
    static var syncToUserDefaultsSynchros: [Synchro] = []
    static var syncFromUserDefaultsSynchros: [Synchro] = []
    static var settings: [BRHSettingDescription] = []

    static func reset() {
        defaults = [:]
        syncToUserDefaultsSynchros = []
        syncFromUserDefaultsSynchros = []
        settings = []
    }

    func registerSetting(_ key: String, value: AnyObject?,
                         syncToUserDefaults: @escaping Synchro,
                         syncFromUserDefaults: @escaping Synchro) {
        BRHSettingBase.defaults[key] = value
        BRHSettingBase.syncToUserDefaultsSynchros.append(syncToUserDefaults)
        BRHSettingBase.syncFromUserDefaultsSynchros.append(syncFromUserDefaults)
    }

    /**
     Update NSUserDefaults using the internal values
     */
    static func syncToUserDefaults() {
        BRHSettingBase.syncToUserDefaultsSynchros.forEach { $0() }
    }
    /**
     Update the internal values using contents from NSUserDefaults.
     */
    static func syncFromUserDefaults() {
        for (index, synchro) in BRHSettingBase.syncFromUserDefaultsSynchros.enumerated() {
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
final class BRHSetting<ValueType, DefaultsType, ValueConverter: BRHValueConverter> : BRHSettingBase, BRHSettingDescription, CustomDebugStringConvertible where ValueType: Equatable, ValueType == ValueConverter.ValueType, DefaultsType == ValueConverter.DefaultsType {

    let key: String
    let notificationName: Notification.Name
    var value: ValueType
    var defaultsValue: DefaultsType { return ValueConverter.valueToDefaults(self.value) }

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
        BRHSettingBase.settings.append(self)
        self.registerSetting(self.key, value: ValueConverter.valueToAnyObject(self.value),
                             syncToUserDefaults: {
                                Defaults[self.key] = ValueConverter.valueToAnyObject(self.value)
            },
                             syncFromUserDefaults: {
                                if let value = ValueConverter.anyObjectToValue(Defaults.object(forKey: self.key) as AnyObject?) {
                                    if self.value != value {
                                        print("-- setting \(self.key) changed - old: \(self.value) new: \(value)")
                                        self.value = value
                                        NotificationCenter.default.post(name: self.notificationName,
                                                                        object: self,
                                                                        userInfo: ["old": self.value, "new": value])
                                    }
                                }
                                else {
                                    Defaults[self.key] = ValueConverter.valueToAnyObject(self.value)
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

typealias BRHStringSetting = BRHSetting<String, String, BRHStringValueConverter>
typealias BRHIntSetting = BRHSetting<Int, String, BRHIntValueConverter>
typealias BRHDoubleSetting = BRHSetting<Double, String, BRHDoubleValueConverter>
typealias BRHBoolSetting = BRHSetting<Bool, Bool, BRHBoolValueConverter>

/**
 @brief Collection of all user settings.
 */
final class BRHUserSettings {
    static let kUpdatedNotification = Notification.Name(rawValue: "BRHUserSettingsUpdated")

    var notificationDriver: BRHStringSetting
    var emitInterval: BRHIntSetting
    var maxHistogramBin: BRHIntSetting
    var dropboxLinkButtonText: BRHStringSetting
    var uploadAutomatically: BRHBoolSetting
    var remoteServerName: BRHStringSetting
    var remoteServerPort: BRHIntSetting
    var resendUntilFetched: BRHBoolSetting
    var apnsProdCertFileName: BRHStringSetting
    var apnsProdCertPassword: BRHStringSetting
    var apnsDevCertFileName: BRHStringSetting
    var apnsDevCertPassword: BRHStringSetting

    /**
     Initialize user settings collection. Sets up default values in NSUserDefaults.
     */
    fileprivate init() {
        BRHSettingBase.reset()
        notificationDriver = BRHStringSetting(tag: .notificationDriver, value: "remote")
        emitInterval = BRHIntSetting(tag: .emitInterval, value: 120)
        maxHistogramBin = BRHIntSetting(tag: .maxHistogramBin, value: 30)
        dropboxLinkButtonText = BRHStringSetting(tag: .dropboxLinkButtonText, value: "Link")
        uploadAutomatically = BRHBoolSetting(tag: .uploadAutomatically, value: true)
        remoteServerName = BRHStringSetting(tag: .remoteServerName, value: "brhemitter.azurewebsites.net")
        remoteServerPort = BRHIntSetting(tag: .remoteServerPort, value: 80)
        resendUntilFetched = BRHBoolSetting(tag: .resendUntilFetched, value: true)
        apnsProdCertFileName = BRHStringSetting(tag: .apnsProdCertFileName, value: "apn-nhtest-prod.p12")
        apnsProdCertPassword = BRHStringSetting(tag: .apnsProdCertPassword, value: "")
        apnsDevCertFileName = BRHStringSetting(tag: .apnsDevCertFileName, value: "apn-nhtest-dev.p12")
        apnsDevCertPassword = BRHStringSetting(tag: .apnsDevCertPassword, value: "")
        Defaults.register(defaults: BRHSettingBase.defaults)
        syncFromUserDefaults()
        dump()
    }

    /**
     Update NSUserDefaults using the internal values
     */
    func syncToUserDefaults() {
        BRHSettingBase.syncToUserDefaults()
    }
    
    /**
     Update the internal values using contents from NSUserDefaults.
     */
    func syncFromUserDefaults() {
        BRHSettingBase.syncFromUserDefaults()
        NotificationCenter.default.post(name: BRHUserSettings.kUpdatedNotification, object: self, userInfo: nil)
        dump()
    }

    /**
     Print out the current application settings.
     */
    func dump() {
        BRHSettingBase.settings.forEach { print($0.settingDescription) }
    }
}

private var singleton: BRHUserSettings?
extension BRHUserSettings {
    static func settings() -> BRHUserSettings {
        if singleton == nil { singleton = BRHUserSettings() }
        return singleton!
    }
}
