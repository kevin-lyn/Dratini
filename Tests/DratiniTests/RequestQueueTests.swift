//
//  RequestQueueTests.swift
//  Dratini
//
//  Created by Kevin Lin on 4/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import XCTest
import Dratini

private struct TestGetResponse: Response {
    let stringParam: String
    let chineseParam: String
    let intParam: Int
    let optionalParam: String?
    
    init?(data: ResponseData, response: URLResponse) {
        guard let args = data.jsonObject["args"] as? [String: Any],
            let stringParam = args["string_param"] as? String,
            let chineseParam = args["chinese_param"] as? String,
            let intParamString = args["int_param"] as? String,
            let intParam = Int(intParamString) else {
            return nil
        }
        self.stringParam = stringParam
        self.chineseParam = chineseParam
        self.intParam = intParam
        self.optionalParam = args["optional_param"] as? String
    }
}

private struct TestGetQueryString: DefaultQueryString {
    let stringParam: String
    let chineseParam: String
    let intParam: Int
    let optionalParam: String?
}

private struct TestGetRequest: Request {
    typealias ParametersType = TestGetQueryString
    typealias ResponseType = TestGetResponse
    
    var parameters: TestGetQueryString
    
    func path() -> String {
        return "/get"
    }
    
    func method() -> HTTPMethod {
        return .get
    }
}

private struct TestPostResponse: Response {
    let stringParam: String
    let chineseParam: String
    let intParam: Int
    let optionalParam: String?
    
    init?(data: ResponseData, response: URLResponse) {
        guard let form = data.jsonObject["form"] as? [String: Any],
            let stringParam = form["string_param"] as? String,
            let chineseParam = form["chinese_param"] as? String,
            let intParamString = form["int_param"] as? String,
            let intParam = Int(intParamString) else {
                return nil
        }
        self.stringParam = stringParam
        self.chineseParam = chineseParam
        self.intParam = intParam
        self.optionalParam = form["optional_param"] as? String
    }
}

private struct TestPostBodyData: URLEncodedBodyData {
    let stringParam: String
    let chineseParam: String
    let intParam: Int
    let optionalParam: String?
}

private struct TestPostRequest: Request {
    typealias ParametersType = TestPostBodyData
    typealias ResponseType = TestPostResponse
    
    var parameters: TestPostBodyData
    
    func path() -> String {
        return "/post"
    }
    
    func method() -> HTTPMethod {
        return .post
    }
}

private struct TestPostMultipartResponse: Response {
    let fileContent: String
    let stringContent: String
    let stringValue: String
    let chineseValue: String
    
    init?(data: ResponseData, response: URLResponse) {
        guard let files = data.jsonObject["files"] as? [String: Any],
            let form = data.jsonObject["form"] as? [String: Any],
            let fileContent = files["file_content"] as? String,
            let stringContent = files["string_content"] as? String,
            let stringValue = form["string_value"] as? String,
            let chineseValue = form["chinese_value"] as? String else {
                return nil
        }
        self.fileContent = fileContent
        self.stringContent = stringContent
        self.stringValue = stringValue
        self.chineseValue = chineseValue
    }
}

private struct TestPostMultipartRequest: Request {
    typealias ParametersType = MultipartFormData
    typealias ResponseType = TestPostMultipartResponse
    
    var parameters: MultipartFormData
    
    func path() -> String {
        return "/post"
    }
    
    func method() -> HTTPMethod {
        return .post
    }
}

private class TestRequestQueueDelegate: RequestQueueDelegate {
    var willSend = false
    var didSend = false
    var didReceive = false
    var didFail = false
    
    func requestQueue(_ requestQueue: RequestQueue, willSend request: inout URLRequest) {
        willSend = true
    }
    
    func requestQueue(_ requestQueue: RequestQueue, didSend request: URLRequest) {
        didSend = true
    }
    
    func requestQueue(_ requestQueue: RequestQueue, didFailWith request: URLRequest, error: DRError) {
        didFail = true
    }
    
    func requestQueue(_ requestQueue: RequestQueue, didReceive response: URLResponse) {
        didReceive = true
    }
}

class RequestQueueTests: XCTestCase {
    private let delegate = TestRequestQueueDelegate()
    private lazy var requestQueue: RequestQueue = {
        return RequestQueue(delegate: self.delegate, baseURL: URL(string: "http://httpbin.org")!)
    }()
    
    func testGetRequest() {
        let expectation = self.expectation(description: #function)
        let request = TestGetRequest(parameters: TestGetQueryString(stringParam: "string",
                                                                    chineseParam: "中文",
                                                                    intParam: 1,
                                                                    optionalParam: nil))
        requestQueue.add(request)
        requestQueue.addObserver(ownedBy: self) { (result: Result<TestGetResponse>) in
            guard let response = result.response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssert(response.stringParam == request.parameters.stringParam)
            XCTAssert(response.chineseParam == request.parameters.chineseParam)
            XCTAssert(response.intParam == request.parameters.intParam)
            XCTAssert(response.optionalParam == request.parameters.optionalParam)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPostRequest() {
        let expectation = self.expectation(description: #function)
        let request = TestPostRequest(parameters: TestPostBodyData(stringParam: "string",
                                                                   chineseParam: "中文",
                                                                   intParam: 1,
                                                                   optionalParam: nil))
        requestQueue.add(request)
        requestQueue.addObserver(ownedBy: self) { (result: Result<TestPostResponse>) in
            guard let response = result.response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssert(response.stringParam == request.parameters.stringParam)
            XCTAssert(response.chineseParam == request.parameters.chineseParam)
            XCTAssert(response.intParam == request.parameters.intParam)
            XCTAssert(response.optionalParam == request.parameters.optionalParam)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMultipartRequest() {
        let expectation = self.expectation(description: #function)
        
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_file")
        let fileContent = "Test file content"
        try! fileContent.data(using: .utf8)?.write(to: fileURL)

        let data = MultipartFormData()
        data.append(fileURL: fileURL, withName: "file_content", fileName: "test_file", mimeType: "text/plain")
        let stringContent = "Test file data"
        data.append(data: stringContent.data(using: .utf8)!, withName: "string_content")
        let stringValue = "string"
        data.append(value: stringValue, withName: "string_value")
        let chineseValue = "中文"
        data.append(value: chineseValue, withName: "chinese_value")
        
        let request = TestPostMultipartRequest(parameters: data)
        requestQueue.add(request)
        requestQueue.addObserver(ownedBy: self) { (result: Result<TestPostMultipartResponse>) in
            guard let response = result.response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssert(response.fileContent == fileContent)
            XCTAssert(response.stringContent == stringContent)
            XCTAssert(response.stringValue == stringValue)
            XCTAssert(response.chineseValue == chineseValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancel() {
        let expectation = self.expectation(description: #function)
        let request = TestGetRequest(parameters: TestGetQueryString(stringParam: "string",
                                                                    chineseParam: "中文",
                                                                    intParam: 1,
                                                                    optionalParam: nil))
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestGetResponse>) in
            XCTFail("Request is not cancelled")
        }
        requestQueue.cancel(requestID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testIsFinished() {
        let expectation = self.expectation(description: #function)
        let request = TestGetRequest(parameters: TestGetQueryString(stringParam: "string",
                                                                    chineseParam: "中文",
                                                                    intParam: 1,
                                                                    optionalParam: nil))
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestGetResponse>) in
            XCTAssert(self.requestQueue.isFinished(requestID))
            expectation.fulfill()
        }
        XCTAssert(!requestQueue.isFinished(requestID))
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRemoveObservers() {
        let expectation = self.expectation(description: #function)
        let request = TestGetRequest(parameters: TestGetQueryString(stringParam: "string",
                                                                    chineseParam: "中文",
                                                                    intParam: 1,
                                                                    optionalParam: nil))
        let requestID = requestQueue.add(request)
        requestQueue.addObserver(for: requestID) { (result: Result<TestGetResponse>) in
            expectation.fulfill()
        }
        requestQueue.addObserver(ownedBy: self) { (result: Result<TestGetResponse>) in
            XCTFail("Observer is not removed")
        }
        requestQueue.removeObservers(forType: TestGetResponse.self, ownedBy: self)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRequestQueueDelegate() {
        let expectation = self.expectation(description: #function)
        let request = TestGetRequest(parameters: TestGetQueryString(stringParam: "string",
                                                                    chineseParam: "中文",
                                                                    intParam: 1,
                                                                    optionalParam: nil))
        requestQueue.add(request)
        requestQueue.addObserver(ownedBy: self) { (result: Result<TestGetResponse>) in
            XCTAssert(self.delegate.willSend)
            XCTAssert(self.delegate.didSend)
            XCTAssert(self.delegate.didReceive)
            XCTAssert(!self.delegate.didFail)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
