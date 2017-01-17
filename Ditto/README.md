# <img src="https://cloud.githubusercontent.com/assets/1491282/18335864/2b8501d6-75b5-11e6-8bf5-276fe60792b0.png" height="26" width="24"> Ditto ![CI Status](https://travis-ci.org/kevin0571/Ditto.svg?branch=master) ![Version](http://img.shields.io/cocoapods/v/Ditto-Swift.svg?style=flag) ![License](https://img.shields.io/cocoapods/l/Ditto-Swift.svg?style=flag)
Ditto allows you to serialize your swift object to JSON object compatible dictionary.

## Features
- Customizable mapping.
- Auto mapping with frequently used mapping style.
- Custom type convertible supported.
- Nested serializable.

## Requirements
- Xcode 8.0+
- Swift 3.0

## Usage

**CocoaPods**
```ruby
platform :ios, '8.0'
pod 'Ditto-Swift'
```

**Carthage**
```ruby
github "kevin0571/Ditto"
```

**Swift Package Manager**
```ruby
dependencies: [
    .Package(url: "https://github.com/kevin0571/Ditto.git", majorVersion: 1)
]
```

### Overview
```swift
import Ditto

struct ExampleStruct {
    let string = "string"
    let anotherString = "anotherString"
    let int = 1
    let url = URL(string: "https://github.com")
}

extension ExampleStruct: Serializable {
    func serializableMapping() -> Mapping {
        return [
            "string": "str",
            "int": "integer",
            "url": "url"
        ]
    }
}

// Serialize ExampleStruct
let exampleStruct = ExampleStruct()

// To Dictionary
let jsonObject: JSONObject = exampleStruct.serialize()
let jsonArray: [JSONObject] = [exampleStruct, exampleStruct].serialize()
/*
 "jsonObject" will be a dictionary with content:
 [
    "str": "string",
    "integer": 1,
    "url": "https://github.com"
 ]
 note that "anotherString" is not being serialized,
 becuase mapping of "anotherString" is not defined in "serializableMapping".
 */
 
// To String
let jsonObjectString: String = exampleStruct.serialize()

// To Data
let jsonObjectData: Data = exampleStruct.serialize()
```

### Auto Mapping
Available auto mapping styles: **lowercaseSeparatedByUnderScore**, **lowercase**, **lowerCamelCase**, **upperCamelCase**
```swift
extension ExampleStruct: Serializable {
    func serializableMapping() -> Mapping {
        return AutoMapping.mapping(
            for: self, 
            style: .lowercaseSeparatedByUnderScore
        )
    }
}

// Serialize ExampleStruct with auto mapping
let exampleStruct = ExampleStruct()
let jsnObject = exampleStruct.serialize()
/*
 "jsonObject" will be a dictionary with content:
 [
    "string": "string",
    "another_string": "anotherString",
    "int": 1,
    "url": "https://github.com"
 ]
 */
```

### Custom Type Convertible
```swift
class CustomClass {
    let string = "string"
    let int = 1
    private var converted: String {
        return "Converted to: \(string), \(int)"
    }
}

extension CustomClass: Convertible {
    func convert() -> Any {
        return converted
    }
}

struct ExampleStruct {
    let customClass = CustomClass()
}

extension ExampleStruct: Serializable {
    func serializableMapping() -> Mapping {
        return AutoMapping.mapping(
            for: self, 
            style: .lowercaseSeparatedByUnderScore
        )
    }
}

// Serialize ExampleStruct
let exampleStruct = ExampleStruct()
let jsonObject = exampleStruct.serialize()
/*
 "jsonObject" will be a dictionary with content:
 [
    "custom_class": "Converted to: string, int"
 ]
 */
```
