//
//  RequestConverterTests.swift
//  Dratini
//
//  Created by Kevin Lin on 13/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import XCTest
@testable import Dratini

private struct TestQueryString: DefaultQueryString {
    let string = "string"
    let int = 1
}

private struct TestBodyData: URLEncodedBodyData {
    let string = "string"
    let int = 1
}

private struct TestQueryStringRequest: Request {
    typealias ParametersType = TestQueryString
    typealias ResponseType = EmptyResponse
    
    var parameters = TestQueryString()
    
    func path() -> String {
        return "/get"
    }
    
    func method() -> HTTPMethod {
        return .get
    }
}

private struct TestBodyDataRequest: Request {
    typealias ParametersType = TestBodyData
    typealias ResponseType = EmptyResponse
    
    var parameters = TestBodyData()
    
    func path() -> String {
        return "/post"
    }
    
    func method() -> HTTPMethod {
        return .post
    }
}

class RequestConverterTests: XCTestCase {
    func testRequestWithQueryString() {
        let request = TestQueryStringRequest()
        guard let urlRequest = try? RequestConverter.convert(request, withBaseURL: URL(string: "http://httpbin.org")!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300) else {
            XCTFail("Convert request failed")
            return
        }
        XCTAssert(urlRequest.url!.absoluteString.hasPrefix("http://httpbin.org/get"))
        for item in URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!.queryItems! {
            XCTAssert(item.name == "string" || item.name == "int")
            XCTAssert(item.value == "string" || item.value == "1")
        }
        XCTAssert(urlRequest.httpMethod == "GET")
        XCTAssert((urlRequest.httpBody?.count ?? 0) == 0)
        XCTAssert(urlRequest.cachePolicy == .reloadIgnoringLocalCacheData)
        XCTAssert(urlRequest.timeoutInterval == 300)
    }
    
    func testRequestWithBodyData() {
        let request = TestBodyDataRequest()
        guard let urlRequest = try? RequestConverter.convert(request, withBaseURL: URL(string: "http://httpbin.org")!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300) else {
            XCTFail("Convert request failed")
            return
        }
        XCTAssert(urlRequest.url == URL(string: "http://httpbin.org/post"))
        XCTAssert(urlRequest.httpMethod == "POST")
        XCTAssert((urlRequest.httpBody?.count ?? 0) > 0)
        XCTAssert(urlRequest.cachePolicy == .reloadIgnoringLocalCacheData)
        XCTAssert(urlRequest.timeoutInterval == 300)
    }
}
