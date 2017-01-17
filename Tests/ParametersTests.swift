//
//  ParametersTests.swift
//  Dratini
//
//  Created by Kevin Lin on 11/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import XCTest
import Dratini

private struct TestDefaultQueryString: DefaultQueryString {
    let stringValue = "string"
    let intValue = 10
    let floatValue = 10.1
    let arrayValue = [1,2,3,4,5]
    let dictionaryValue = ["key_1": "value_1"]
}

private struct TestURLEncodedBodyData: URLEncodedBodyData {
    let stringValue = "string"
    let intValue = 10
    let floatValue = 10.1
    let arrayValue = [1,2,3,4,5]
    let dictionaryValue = ["key_1": "value_1"]
}

private struct TestJSONBodyData: JSONBodyData {
    let stringValue = "string"
    let intValue = 10
    let floatValue = 10.1
    let arrayValue = [1,2,3,4,5]
    let dictionaryValue = ["key_1": "value_1"]
}

class ParametersTests: XCTestCase {
    func testDefaultQueryString() {
        let testDefaultQueryString = TestDefaultQueryString()
        guard let queryString = try? testDefaultQueryString.encode() else {
            XCTFail("Encode failed")
            return
        }
        XCTAssert(queryString == "int_value=10&float_value=10.1&array_value[]=1&array_value[]=2&array_value[]=3&array_value[]=4&array_value[]=5&string_value=string&dictionary_value[key_1]=value_1")
    }
    
    func testURLEncodedBodyData() {
        let testURLEncodedBodyData = TestURLEncodedBodyData()
        guard let bodyData = try? testURLEncodedBodyData.encode() else {
            XCTFail("Encode failed")
            return
        }
        XCTAssert(bodyData == "int_value=10&float_value=10.1&array_value%5B%5D=1&array_value%5B%5D=2&array_value%5B%5D=3&array_value%5B%5D=4&array_value%5B%5D=5&string_value=string&dictionary_value%5Bkey_1%5D=value_1".data(using: .utf8)!)
    }
    
    func testJSONBodyData() {
        let testJSONBodyData = TestJSONBodyData()
        guard let bodyData = try? testJSONBodyData.encode() else {
            XCTFail("Encode failed")
            return
        }
        XCTAssert(bodyData == "{\"int_value\":10,\"float_value\":10.1,\"array_value\":[1,2,3,4,5],\"string_value\":\"string\",\"dictionary_value\":{\"key_1\":\"value_1\"}}".data(using: .utf8)!)
    }
}
