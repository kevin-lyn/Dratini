//
//  RequestConverter.swift
//  Dratini
//
//  Created by Kevin Lin on 3/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

struct RequestConverter {
    private init() {}
    
    static func convert<T: Request>(_ request: T,
                        withBaseURL baseURL: URL,
                        cachePolicy: URLRequest.CachePolicy,
                        timeoutInterval: TimeInterval) throws -> URLRequest {
        var url = baseURL
        url.appendPathComponent(request.path())
        if let queryString = request.parameters as? QueryString,
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            urlComponents.query = try queryString.encode()
            url = urlComponents.url ?? url
        }
        
        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = request.method().rawValue.uppercased()
        
        switch request.method() {
        case .options, .post, .put, .patch, .trace, .connect:
            guard let bodyData = request.parameters as? BodyData else {
                break
            }
            urlRequest.httpBody = try bodyData.encode()
            urlRequest.setValue(bodyData.contentType, forHTTPHeaderField: "Content-Type")
        default:
            break
        }
        
        return urlRequest
    }
}
