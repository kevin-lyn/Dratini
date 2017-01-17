//
//  Request.swift
//  Dratini
//
//  Created by Kevin Lin on 1/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

public enum HTTPMethod: String {
    case options, get, head, post, put, patch, delete, trace, connect
}

/// Protocol that all requests should conform to.
/// Specifying ParametersType and ResponseType are required.
/// Checkout Parameters.swift and Response.swift for more details.
/// If there is no parameters required, please set ParametersType to EmptyParameters.
/// The same for response, EmptyResponse will be used if response isn't needed.
public protocol Request {
    /// Default implementations for query string and body data are provided.
    /// DefaultQueryString is the default implementation for query string.
    /// URLEncodedBodyData is the implementation for URL encoded body data.
    /// JSONBodyData is the implementation for JSON body data.
    /// MultipartFormData is the implementation for multipart form data.
    associatedtype ParametersType: Parameters
    /// The response type which will be passed into the observer callback.
    associatedtype ResponseType: Response
    
    var parameters: ParametersType { get set }
    
    func path() -> String
    func method() -> HTTPMethod
    func responseType() -> ResponseType.Type
}

public extension Request {
    func responseType() -> ResponseType.Type {
        return ResponseType.self
    }
}

/// Delegate that could be used with Request if you wish to get callback:
/// - before request is sent
/// - after request is sent
/// - when request is failed
/// NOTE: RequestDelegate will be called after RequestQueueDelegate.
public protocol RequestDelegate {
    /// It's called before the actual URLRequest is sent out.
    /// Giving a chance to overwrite attributes of URLRequest.
    func requestWillSend(_ urlRequest: inout URLRequest)
    
    /// It's called right after URLRequest is sent out.
    func requestDidSend(_ urlRequest: URLRequest)
    
    /// It's called when request is failed.
    /// Any failure before response is generated will fall into this function.
    /// See DRError for error types.
    func request(_ urlRequest: URLRequest, didFailWith error: DRError)
}
