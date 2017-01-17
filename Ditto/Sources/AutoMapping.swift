//
//  AutoMapping.swift
//  Ditto
//
//  Created by Kevin Lin on 6/9/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

private extension Character {
    func isUppercase() -> Bool {
        guard let unicodeScalar = String(self).unicodeScalars.first else {
            return false
        }
        return unicodeScalar >= "A".unicodeScalars.first! && unicodeScalar <= "Z".unicodeScalars.first!
    }
    
    func isLowercase() -> Bool {
        guard let unicodeScalar = String(self).unicodeScalars.first else {
            return false
        }
        return unicodeScalar >= "a".unicodeScalars.first! && unicodeScalar <= "z".unicodeScalars.first!
    }
    
    func uppercased() -> Character {
        return String(self).uppercased().characters.first!
    }
    
    func lowercased() -> Character {
        return String(self).lowercased().characters.first!
    }
}

/**
 `AutoMappingStyle` will provide a `Mapping` according to the given field.
 Available styles:
 - lowercaseSeparatedByUnderScore: fisrtName -> first_name
 - lowercase: firstName -> firstname
 - lowerCamelCase: firstName -> firstName
 - upperCamelCase: firstName -> FirstName
 */
public enum AutoMappingStyle {
    case lowercaseSeparatedByUnderscore, lowercase, lowerCamelCase, upperCamelCase
    internal func map(_ field: String) -> String {
        var mapped = ""
        switch self {
        case .lowercaseSeparatedByUnderscore:
            guard var lastVisitedChar = field.characters.first else {
                break
            }
            for (index, char) in field.characters.enumerated() {
                if index == 0 {
                    mapped.append(char.lowercased())
                } else if char.isUppercase() {
                    if !lastVisitedChar.isUppercase() {
                        mapped.append("_")
                        mapped.append(char.lowercased())
                    } else {
                        mapped.append(char.lowercased())
                    }
                } else if !char.isLowercase() {
                    if lastVisitedChar.isUppercase() || lastVisitedChar.isLowercase() {
                        mapped.append("_")
                        mapped.append(char)
                    } else {
                        mapped.append(char)
                    }
                } else {
                    mapped.append(char)
                }
                lastVisitedChar = char
            }
        case .lowercase:
            mapped = field.lowercased()
        case .lowerCamelCase:
            mapped = field
        case .upperCamelCase:
            guard let firstChar = field.characters.first else {
                break
            }
            mapped.append(firstChar.uppercased())
            mapped.append(field.substring(from: field.index(field.startIndex, offsetBy: 1)))
        }
        return mapped
    }
}

/**
 Factory for creating `Mapping` according to `AutoMappingStyle`.
 */
public struct AutoMapping {
    private init() {}
    
    /**
     Create `Mapping` of the given object.
     
     - parameter object: the object that need to be mapped to JSON object.
     - parameter style: `AutoMappingStyle`
     
     - returns: `Mapping`
     */
    public static func mapping(for object: Any, style: AutoMappingStyle) -> Mapping {
        let fields = self.fields(of: object)
        var mapping = Mapping()
        for field in fields {
            mapping[field] = style.map(field)
        }
        return mapping
    }
    
    private static func fields(of object: Any) -> [String] {
        var labels = [String]()
        let mirror = Mirror(reflecting: object)
        for child in mirror.children {
            guard let label = child.label else {
                continue
            }
            labels.append(label)
        }
        return labels
    }
}
