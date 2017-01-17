//
//  Serializer.swift
//  Ditto
//
//  Created by Kevin Lin on 23/10/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

import Foundation

extension Serializable {
    
    /**
     Serialize the current object to a JSON object.
     Non-convertible field of the current object will be ignored.
     
     - returns: `JSONObject`
     */
    public func serialize() -> JSONObject {
        let mapping = self.serializableMapping()
        let mirror = Mirror(reflecting: self)
        var jsonObject = JSONObject()
        for child in mirror.children {
            guard let label = child.label else {
                continue
            }
            guard let jsonField = mapping[label] else {
                continue
            }
            
            let value = child.value
            if let serializable = value as? Serializable {
                jsonObject[jsonField] = serializable.serialize() as JSONObject
            } else if let convertible = value as? Convertible {
                jsonObject[jsonField] = convertible.convert()
            }
        }
        return jsonObject
    }
    
    public func serialize() -> String {
        return stringify(jsonValue: serialize() as JSONObject)
    }
    
    public func serialize() -> Data? {
        return serialize().data(using: .utf8)
    }
}

extension Array where Element: Serializable {
    public func serialize() -> JSONArray {
        var jsonArray = JSONArray()
        for serializable in self {
            jsonArray.append(serializable.serialize() as JSONObject)
        }
        return jsonArray
    }
    
    public func serialize() -> String {
        return stringify(jsonValue: serialize() as JSONArray)
    }
    
    public func serialize() -> Data? {
        return serialize().data(using: .utf8)
    }
}

extension Array where Element: Convertible {
    public func serialize() -> JSONArray {
        var jsonArray = JSONArray()
        for convertible in self {
            jsonArray.append(convertible.convert())
        }
        return jsonArray
    }
    
    public func serialize() -> String {
        return stringify(jsonValue: serialize() as JSONArray)
    }
    
    public func serialize() -> Data? {
        return serialize().data(using: .utf8)
    }
}

// MARK: Helpers

private func stringify(jsonValue: JSONValue?) -> String {
    guard let jsonValue = jsonValue else {
        return "null"
    }
    let string: String
    switch jsonValue {
    case is Integer: fallthrough
    case is Float: fallthrough
    case is Double: fallthrough
    case is Bool: fallthrough
    case is NSNumber:
        string = "\(jsonValue)"
    case is JSONObject:
        let jsonObject = jsonValue as! JSONObject
        var objectString = "{"
        var count = 0
        let totalCount = jsonObject.count
        for (key, value) in jsonObject {
            count += 1
            objectString += "\"\(key)\":\(stringify(jsonValue: value))\(count == totalCount ? "" : ",")"
        }
        objectString += "}"
        string = objectString
    case is JSONArray:
        let jsonArray = jsonValue as! JSONArray
        var arrayString = "["
        var count = 0
        let totalCount = jsonArray.count
        for object in jsonArray {
            count += 1
            arrayString += "\(stringify(jsonValue: object))\(count == totalCount ? "" : ",")"
        }
        arrayString += "]"
        string = arrayString
    default:
        string = "\"\(jsonValue)\""
    }
    return string
}
