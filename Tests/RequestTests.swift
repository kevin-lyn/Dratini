//
//  RequestTests.swift
//  Dratini
//
//  Created by Kevin Lin on 11/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import XCTest
import Dratini

private struct TestResponse: Response {
    let headerValue: String
    init?(data: ResponseData, response: URLResponse) {
        guard let headers = data.jsonObject["headers"] as? [String: Any],
            let headerValue = headers["Test-Header"] as? String else {
            return nil
        }
        self.headerValue = headerValue
    }
}

private class TestRequest: Request, RequestDelegate {
    typealias ParametersType = EmptyParameters
    typealias ResponseType = TestResponse
    
    var parameters = EmptyParameters()
    let shouldFail: Bool
    private(set) var sent = false
    private(set) var errored = false
    
    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }
    
    func path() -> String {
        return shouldFail ? "/404" : "/get"
    }
    
    func method() -> HTTPMethod {
        return .get
    }
    
    func requestWillSend(_ urlRequest: inout URLRequest) {
        urlRequest.addValue("Test header value", forHTTPHeaderField: "Test-Header")
    }
    
    func requestDidSend(_ urlRequest: URLRequest) {
        sent = true
    }
    
    func request(_ urlRequest: URLRequest, didFailWith error: DRError) {
        errored = true
    }
}

class RequestTests: XCTestCase {
    private let requestQueue = RequestQueue(baseURL: URL(string: "http://httpbin.org")!)
    
    func testRequestDelegate() {
        let expectation = self.expectation(description: #function)
        let request = TestRequest(shouldFail: false)
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestResponse>) in
            guard let response = result.response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssert(response.headerValue == "Test header value")
            XCTAssert(request.sent)
            XCTAssert(!request.errored)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestDelegateWithFailure() {
        let expectation = self.expectation(description: #function)
        let request = TestRequest(shouldFail: true)
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestResponse>) in
            guard result.isFailure else {
                XCTFail("Request should fail")
                return
            }
            XCTAssert(request.sent)
            XCTAssert(request.errored)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
