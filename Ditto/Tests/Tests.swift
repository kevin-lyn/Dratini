//
//  DittoTests.swift
//  DittoTests
//
//  Created by Kevin Lin on 6/9/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

import XCTest
import Ditto

private class TestClass {
    let string = "string"
    let int = 1
    var converted: String {
        return "Converted to: \(string), \(int)"
    }
}

extension TestClass: Convertible {
    func convert() -> JSONValue? {
        return converted
    }
}

private struct TestStruct {
    let string = "string"
    let anotherString: NSString = "anotherString"
    let int: Int? = 1
    let int8: Int8 = 1
    let int64: Int64 = 1
    let double: Double = 1.0
    let float: Float = 1.0
    let aURL = URL(string: "http://www.google.com")
    let complexNamingWithURL123 = "complexNamingWithURL123"
    let testClass: TestClass? = TestClass()
    let array = [1, 2, 3, 4, 5]
    var autoMappingStyle: AutoMappingStyle?
}

extension TestStruct: Serializable {
    func serializableMapping() -> Mapping {
        if let autoMappingStyle = autoMappingStyle {
            return AutoMapping.mapping(for: self, style: autoMappingStyle)
        } else {
            return [
                "string": "str",
                "int": "integer",
                "testClass": "test",
                "array": "array"
            ]
        }
    }
}

class DittoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConvertible() {
        let testStruct = TestStruct()
        let jsonObject = testStruct.serialize() as JSONObject
        XCTAssert(jsonObject["test"] as? String == testStruct.testClass?.converted)
    }
    
    func testSerializable() {
        var array = [TestStruct]()
        for _ in 0..<10 {
            array.append(TestStruct())
        }
        let jsonArray = array.serialize() as JSONArray
        for (i, jsonObject) in jsonArray.enumerated() {
            guard let jsonObject = jsonObject as? JSONObject else {
                XCTAssert(false)
                continue
            }
            XCTAssert(jsonObject["str"] as? String == array[i].string)
            XCTAssert(jsonObject["integer"] as? Int == array[i].int)
            XCTAssert(jsonObject["array"] as! [Int] == array[i].array)
            XCTAssert(jsonObject["test"] as? String == array[i].testClass?.converted)
        }
    }
    
    func testAutoMapping() {
        var testStruct = TestStruct()
        var jsonObject: JSONObject
        
        testStruct.autoMappingStyle = .lowercaseSeparatedByUnderscore
        jsonObject = testStruct.serialize()
        
        XCTAssert(jsonObject["string"] as? String == testStruct.string)
        XCTAssert(jsonObject["another_string"] as? NSString == testStruct.anotherString)
        XCTAssert(jsonObject["int"] as? Int == testStruct.int)
        XCTAssert(jsonObject["int_8"] as? Int8 == testStruct.int8)
        XCTAssert(jsonObject["int_64"] as? Int64 == testStruct.int64)
        XCTAssert(jsonObject["double"] as? Double == testStruct.double)
        XCTAssert(jsonObject["float"] as? Float == testStruct.float)
        XCTAssert(jsonObject["a_url"] as? String == testStruct.aURL?.absoluteString)
        XCTAssert(jsonObject["complex_naming_with_url_123"] as? String == testStruct.complexNamingWithURL123)
        XCTAssert(jsonObject["test_class"] as? String == testStruct.testClass?.converted)
        
        testStruct.autoMappingStyle = .lowercase
        jsonObject = testStruct.serialize()
        XCTAssert(jsonObject["string"] as? String == testStruct.string)
        XCTAssert(jsonObject["anotherstring"] as? NSString == testStruct.anotherString)
        XCTAssert(jsonObject["int"] as? Int == testStruct.int)
        XCTAssert(jsonObject["int8"] as? Int8 == testStruct.int8)
        XCTAssert(jsonObject["int64"] as? Int64 == testStruct.int64)
        XCTAssert(jsonObject["double"] as? Double == testStruct.double)
        XCTAssert(jsonObject["float"] as? Float == testStruct.float)
        XCTAssert(jsonObject["aurl"] as? String == testStruct.aURL?.absoluteString)
        XCTAssert(jsonObject["complexnamingwithurl123"] as? String == testStruct.complexNamingWithURL123)
        XCTAssert(jsonObject["testclass"] as? String == testStruct.testClass?.converted)
        
        testStruct.autoMappingStyle = .lowerCamelCase
        jsonObject = testStruct.serialize()
        XCTAssert(jsonObject["string"] as? String == testStruct.string)
        XCTAssert(jsonObject["anotherString"] as? NSString == testStruct.anotherString)
        XCTAssert(jsonObject["int"] as? Int == testStruct.int)
        XCTAssert(jsonObject["int8"] as? Int8 == testStruct.int8)
        XCTAssert(jsonObject["int64"] as? Int64 == testStruct.int64)
        XCTAssert(jsonObject["double"] as? Double == testStruct.double)
        XCTAssert(jsonObject["float"] as? Float == testStruct.float)
        XCTAssert(jsonObject["aURL"] as? String == testStruct.aURL?.absoluteString)
        XCTAssert(jsonObject["complexNamingWithURL123"] as? String == testStruct.complexNamingWithURL123)
        XCTAssert(jsonObject["testClass"] as? String == testStruct.testClass?.converted)
        
        testStruct.autoMappingStyle = .upperCamelCase
        jsonObject = testStruct.serialize()
        XCTAssert(jsonObject["String"] as? String == testStruct.string)
        XCTAssert(jsonObject["AnotherString"] as? NSString == testStruct.anotherString)
        XCTAssert(jsonObject["Int"] as? Int == testStruct.int)
        XCTAssert(jsonObject["Int8"] as? Int8 == testStruct.int8)
        XCTAssert(jsonObject["Int64"] as? Int64 == testStruct.int64)
        XCTAssert(jsonObject["Double"] as? Double == testStruct.double)
        XCTAssert(jsonObject["Float"] as? Float == testStruct.float)
        XCTAssert(jsonObject["AURL"] as? String == testStruct.aURL?.absoluteString)
        XCTAssert(jsonObject["ComplexNamingWithURL123"] as? String == testStruct.complexNamingWithURL123)
        XCTAssert(jsonObject["TestClass"] as? String == testStruct.testClass?.converted)
    }
}
