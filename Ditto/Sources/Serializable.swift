//
//  Serializable.swift
//  Ditto
//
//  Created by Kevin Lin on 6/9/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

/// Mapping defines how a object field should be mapped to JSON object field.
public typealias Mapping = [String: String]

/**
 Serializable defines the common behaviors of serializing a object.
 Default implementation of `serialize` is provided.
 */
public protocol Serializable {
    
    /**
     Mapping from the current object field to JSON object field.
     Auto mapping is provided with built-in mapping styles, please refer to `AutoMapping`.
     
     Example:
     ```
     [
        "fisrtName": "first_name",
        "lastName": "last_name"
     ]
     ```
     
     - returns: `Mapping`
     */
    func serializableMapping() -> Mapping
}
