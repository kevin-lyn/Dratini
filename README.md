# <img src="https://cloud.githubusercontent.com/assets/1491282/21975961/6d807474-dc0a-11e6-8f36-a71e7f38ee74.png" height="26" width="26"> Dratini ![CI Status](https://travis-ci.org/kevin0571/Dratini.svg?branch=master) ![Version](http://img.shields.io/cocoapods/v/Dratini.svg?style=flag) ![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg) ![Swift Pacakge Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg) ![License](https://img.shields.io/cocoapods/l/Dratini.svg?style=flag)
Dratini is a neat network abstraction layer.
If you are looking for a solution to make your network layer neat, Dratini is your choice.
Dratini uses protocols to define network request, parameters and response, which makes your network layer more readable and testable.

## Features
- Protocol base design.
- Auto serialization for parameters.
- Response is observable by request id or response type.
- UI non-blocking since request and response handling heppen in background thread.
- Request and response are interceptable by using delegate.

## Requirements
- Xcode 8.0+
- Swift 3.0

## Dependencies
- [Ditto](https://github.com/kevin0571/Ditto): it's used for serializing Swift object into JSON compatible dictionary, mainly used for impelmenting DefaultQueryString, URLEncodedBodyData and JSONBodyData.

## Usage

**CocoaPods**
```ruby
platform :ios, '8.0'
pod 'Dratini'
```

**Carthage**
```ruby
github "kevin0571/Dratini"
```

**Swift Package Manager**
```ruby
dependencies: [
    .Package(url: "https://github.com/kevin0571/Dratini.git", majorVersion: 1)
]
```

### Overview
Here are some basic steps to send out a request and observe for its response.

Setup RequestQueue:
```swift
let requestQueue = RequestQueue(baseURL: URL(string: "http://example.com"))
// Delegate and configuration are not required.
// Set the delegate(RequestQueueDelegate) if you wish to get callbacks for each step.
// RequestQueueConfiguration.default is used if configuration is not specified.
```

Keep a shared RequestQueue is recommended:
```swift
extension RequestQueue {
    static let shared = RequestQueue(baseURL: URL(string: "http://example.com"))
}
```

Describe your request, parameters and response:
```swift
struct LogInRequest: Request {
    typealias ParametersType = LogInParameters
    typealias ResponseType = LogInResponse
    
    var parameters: LogInParameters
    
    func path() -> String {
        return "/login"
    }
    
    func method() -> HTTPMethod {
        return .post
    }
}

// There are several built-in Parameters types:
// - DefaultQueryString for query string, it will mostly be used in GET request.
// - URLEncodedBodyData for URL encoded body data.
// - JSONBodyData for JSON format body data.
// - MultipartFormData for multipart form data, it will mostly be used for uploading file.
//
// In order to allow you to keep the naming convention of different platforms,
// property name of DefaultQueryString, URLEncodedBodyData and JSONBodyData will be mapped to other naming convention.
// By default property will be converted to lowercase name separated by underscore,
// e.g. accessToken will be converted to access_token. 
// You can set the mapping by overriding "serializableMapping" function.
// See more details in Ditto project's README.
struct LogInParameters: URLEncodedBodyData {
    let username: String
    let password: String
}

struct LogInResponse: Response {
    let username: String
    let name: String
    init?(data: ResponseData, response: URLResponse) {
        // - Use data.data to access raw response data.
        // - Use data.jsonObject to access JSON format dictionary.
        // - Use data.jsonArray to access JSON format array.
        // - Use data.string to access UTF8 string.
        guard let username = data.jsonObject["username"] as? String,
            let name = data.jsonObject["name"] as? String else {
            return nil
        }
        self.username = username
        self.name = name
    }
}
```

Send the request and observe for response:
```swift
let request = LogInRequest(parameters: LogInParameters(username: username,
                                                       password: password))
let requestID = RequestQueue.shared.add(request)
// Observe by using requestID.
// The observer will be removed by RequestQueue after the request is finished.
requestQueue.addObserver(for: requestID) { (result: Result<LogInResponse>) in
    guard let response = result.response else {
        // Show error message
        return
    }
    // Update UI by using response.username and response.name
}
// Observe a specific response type. 
// The observer is owned by an owner. The owner is held weakly by RequestQueue,
// thus the observer will be removed if owner is released.
requestQueue.addObserver(ownedBy: self) { [weak self] (result: Result<LogInResponse>) in
    // ...
}
// NOTE: observer callback is called in main thread.
```

### Do More with Dratini
Sometimes you need to do more with Dratini, here are some features you might need, e.g. upload file, intercept different states of request and response.

Upload file:
```swift
let data = MultipartFormData()
// Append file with fileURL
data.append(fileURL: fileURL, withName: name, fileName: fileName, mimeType: "application/x-plist")  
// Append raw file data
data.append(data: fileData, withName: name, fileName: fileName, mimeType: "application/x-plist")

// Assume we've created UploadFileRequest
let request = UploadFileRequest(parameters: data)
// Send out request
// ...
```

Intercept states of request:
```swift
// Conform to Request with RequestDelegate to get callbacks of different states.
struct LogInRequest: Request, RequestDelegate {
    // ...
    
    func requestWillSend(_ urlRequest: inout URLRequest) {
        // Called before request is sent out.
        // You are able to modify the URLRequest: update HTTP header for example.
    }
    
    func requestDidSend(_ urlRequest: URLRequest) {
        // Called after request is sent out.
    }
    
    func request(_ urlRequest: URLRequest, didFailWith error: DRError) {
        // Called when request is failed to be sent out or response is failed to be created.
    }
}
```

Validate response before creating response and intercept states of response:
```swift
struct LogInResponse: Response, ResponseDelegate {
    // ...
    
    // Validate the response before it's created.
    static func validate(_ response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return true
        }
        return httpResponse.statusCode >= 200 &&
            httpResponse.statusCode < 300 &&
            httpResponse.allHeaderFields["Token"] != nil
    }
    
    // Called after response is created.
    func responseDidReceive(_ response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
            let token = httpResponse.allHeaderFields["Token"] else {
            return nil
        }
        // Save your token
    }
}
```

Having common logic for all requests and response are sometimes necessary, RequestQueueDelegate is here for you:
```swift
class MyRequestQueueDelegate: RequestQueueDelegate {
    public func requestQueue(_ requestQueue: RequestQueue, willSend request: inout URLRequest) {
        // Called before each request is sent out.
    }
    
    public func requestQueue(_ requestQueue: RequestQueue, didSend request: URLRequest) {
        // Called after each request is sent out.
    }
    
    public func requestQueue(_ requestQueue: RequestQueue, didFailWith request: URLRequest, error: DRError) {
        // Called when request is failed to be sent out or response is failed to be created.
    }
    
    public func requestQueue(_ requestQueue: RequestQueue, didReceive response: URLResponse) {
        // Called after response is created.
    }
}

extension RequestQueue {
    // Set delegate when creating RequestQueue.
    static let shared = RequestQueue(delegate: MyRequestQueueDelegate(), baseURL: URL(string: "http://example.com")!)
}
```

Check if request is finished and cancel it:
```swift
let isFinished = RequestQueue.shared.isFinished(requestID)
RequestQueue.shared.cancel(requestID)
```

### Customization
If you wish to customize query string or body data encoding, you can implement your own by adpoting QueryString or BodyData protocol.
```swift
struct MyBodyData: BodyData {
    let string: String
    
    var contentType: String {
        return "my-content-type"
    }
    
    func encode() throws -> Data {
        return string.data(using: .utf8)!
    }
}
```