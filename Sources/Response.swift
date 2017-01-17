//
//  Response.swift
//  Dratini
//
//  Created by Kevin Lin on 2/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

/// Wrapper of raw response data.
/// It also provides handy functions for accessing the data in string, JSON object or JSON array.
open class ResponseData {
    public let data: Data
    public lazy var string: String = String(data: self.data, encoding: .utf8) ?? ""
    public lazy var jsonObject: [String: Any] = ((try? JSONSerialization.jsonObject(with: self.data, options: [])) as? [String: Any]) ?? [String: Any]()
    public lazy var jsonArray: [[String: Any]] = ((try? JSONSerialization.jsonObject(with: self.data, options: [])) as? [[String: Any]]) ?? [[String: Any]]()

    init(_ data: Data) {
        self.data = data
    }
}

/// A protocol that all responses should conform to.
public protocol Response {
    init?(data: ResponseData, response: URLResponse)
    
    /// Validation before response is being created.
    /// Default implementation is provided to accept responses with status code between 200 and 299.
    static func validate(_ response: URLResponse) -> Bool
}

public extension Response {
    static func validate(_ response: URLResponse) -> Bool {
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        } else {
            return true
        }
    }
}

/// Helper struct which could be used when response is not required.
public struct EmptyResponse: Response {
    public init?(data: ResponseData, response: URLResponse) {}
}

/// Delegate that could be used with Response if you wish to get callback:
/// - when response is received
/// NOTE: ResponseDelegate will be called after RequestQueueDelegate
public protocol ResponseDelegate {
    func responseDidReceive(_ response: URLResponse)
}
