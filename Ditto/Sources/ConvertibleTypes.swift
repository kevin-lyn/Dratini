//
//  ConvertibleTypes.swift
//  Ditto
//
//  Created by Kevin Lin on 7/9/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

import Foundation

// MARK: DefaultConvertible

/**
 DefaultConvertible simply return the current object.
 */
public protocol DefaultConvertible: Convertible {}

extension DefaultConvertible {
    public func convert() -> JSONValue? {
        return self as? JSONValue
    }
}

extension String: DefaultConvertible {}
extension Int: DefaultConvertible {}
extension UInt: DefaultConvertible {}
extension Int8: DefaultConvertible {}
extension Int16: DefaultConvertible {}
extension Int32: DefaultConvertible {}
extension Int64: DefaultConvertible {}
extension UInt8: DefaultConvertible {}
extension UInt16: DefaultConvertible {}
extension UInt32: DefaultConvertible {}
extension UInt64: DefaultConvertible {}
extension Float: DefaultConvertible {}
extension Double: DefaultConvertible {}
extension Bool: DefaultConvertible {}
extension NSString: DefaultConvertible {}
extension NSNumber: DefaultConvertible {}

// MARK: Frequently used convertible types

extension URL: Convertible {
    public func convert() -> JSONValue? {
        return self.absoluteString
    }
}

extension NSURL: Convertible {
    public func convert() -> JSONValue? {
        return self.absoluteString
    }
}

extension NSNull: Convertible {
    public func convert() -> JSONValue? {
        return nil
    }
}

extension Array: Convertible {
    public func convert() -> JSONValue? {
        return convertSequence(sequence: self)
    }
}

extension NSArray: Convertible {
    public func convert() -> JSONValue? {
        return convertSequence(sequence: self)
    }
}

extension Dictionary: Convertible {
    public func convert() -> JSONValue? {
        var jsonObject = JSONObject()
        for (key, value) in self {
            guard let key = key as? String else {
                continue
            }
            jsonObject[key] = convertAny(any: value)
        }
        return jsonObject
    }
}

extension Optional: Convertible {
    public func convert() -> JSONValue? {
        switch self {
        case let .some(value):
            if let value = convertAny(any: value) {
                return value
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

// MARK: Helpers

private func convertAny(any: Any) -> JSONValue? {
    if let convertible = any as? Convertible {
        return convertible.convert()
    } else if let serializable = any as? Serializable {
        return serializable.serialize() as JSONObject
    } else {
        return nil
    }
}

private func convertSequence<T: Sequence>(sequence: T) -> [Any] {
    var convertedArray = [Any]()
    for element in sequence {
        if let element = convertAny(any: element) {
            convertedArray.append(element)
        }
    }
    return convertedArray
}
