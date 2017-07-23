//
//  ResponseTests.swift
//  Dratini
//
//  Created by Kevin Lin on 13/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import XCTest
@testable import Dratini

private struct TestRequest: Request {
    typealias ParametersType = EmptyParameters
    typealias ResponseType = TestResponse
    
    var parameters = EmptyParameters()
    
    func path() -> String {
        return "/404"
    }
    
    func method() -> HTTPMethod {
        return .get
    }
}

private class TestResponse: Response, ResponseDelegate {
    private(set) var received = false
    
    required init?(data: ResponseData, response: URLResponse) {
        
    }
    
    static func validate(_ response: URLResponse) -> Bool {
        guard let httpURLResponse = response as? HTTPURLResponse else {
            return false
        }
        return httpURLResponse.statusCode == 404
    }
    
    func responseDidReceive(_ response: URLResponse) {
        received = true
    }
}

class ResponseTests: XCTestCase {
    private let requestQueue = RequestQueue(baseURL: URL(string: "http://httpbin.org")!)
    
    func testResponseData() {
        let jsonObjectString = "{\"int_value\":10,\"float_value\":10.1,\"array_value\":[1,2,3,4,5],\"string_value\":\"string\",\"dictionary_value\":{\"key_1\":\"value_1\"}}"
        let jsonObjectData = jsonObjectString.data(using: .utf8)!
        let jsonObjectResponseData = ResponseData(jsonObjectData)
        XCTAssert(jsonObjectResponseData.string == jsonObjectString)
        XCTAssert(jsonObjectResponseData.jsonArray.isEmpty)
        if let data = try? JSONSerialization.data(withJSONObject: jsonObjectResponseData.jsonObject, options: []) {
            XCTAssert(data == jsonObjectData)
        } else {
            XCTFail("Invalid JSON object")
        }
        
        let jsonArrayString = "[{\"int_value\":10,\"float_value\":10.1,\"array_value\":[1,2,3,4,5],\"string_value\":\"string\",\"dictionary_value\":{\"key_1\":\"value_1\"}}]"
        let jsonArrayData = jsonArrayString.data(using: .utf8)!
        let jsonArrayResponseData = ResponseData(jsonArrayData)
        XCTAssert(jsonArrayResponseData.string == jsonArrayString)
        XCTAssert(jsonArrayResponseData.jsonObject.isEmpty)
        if let data = try? JSONSerialization.data(withJSONObject: jsonArrayResponseData.jsonArray, options: []) {
            XCTAssert(data == jsonArrayData)
        } else {
            XCTFail("Invalid JSON array")
        }
    }
    
    func testResponse() {
        let expectation = self.expectation(description: #function)
        let request = TestRequest()
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestResponse>) in
            guard let response = result.response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssert(response.received)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
