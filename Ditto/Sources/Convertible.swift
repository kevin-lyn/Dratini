//
//  Convertible.swift
//  Ditto
//
//  Created by Kevin Lin on 7/9/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

import Foundation

/// Types of values that are allowed in JSON
public protocol JSONValue {}

extension String: JSONValue {}
extension Int: JSONValue {}
extension UInt: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension UInt8: JSONValue {}
extension UInt16: JSONValue {}
extension UInt32: JSONValue {}
extension UInt64: JSONValue {}
extension Float: JSONValue {}
extension Double: JSONValue {}
extension Bool: JSONValue {}
extension NSString: JSONValue {}
extension NSNumber: JSONValue {}
extension Dictionary: JSONValue {}
extension Array: JSONValue {}

// Type alias
public typealias JSONObject = [String: JSONValue?]
public typealias JSONArray = [JSONValue?]

/**
 Convertible defines how a swift obejct should be converted to a JSON object compatible value.
 
 Example:
 ```
 extension URL: Convertible {
    public func convert() -> JSONValue? {
        return self.absoluteString
    }
 }
 ```
 Please refer to ConvertibleTypes for built-in convertible types.
 */
public protocol Convertible {
    
    /**
     Convert the current object to a JSON object compatible value.
     You can convert your custom type to any JSON object compatible value.
     
     - returns: JSON object compatible value.
     */
    func convert() -> JSONValue?
}
