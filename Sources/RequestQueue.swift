//
//  RequestQueue.swift
//  Dratini
//
//  Created by Kevin Lin on 3/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

public typealias RequestID = UInt64

/// Configuration for requst queue.
/// RequestQueueConfiguration.default is provied with:
/// - sessionConfiguration = URLSessionConfiguration.default
/// - cachePolicy = .useProtocolCachePolicy
/// - timeoutInterval = 60
public struct RequestQueueConfiguration {
    public let sessionConfiguration: URLSessionConfiguration
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    static var `default`: RequestQueueConfiguration {
        return RequestQueueConfiguration(sessionConfiguration: URLSessionConfiguration.default,
                                         cachePolicy: .useProtocolCachePolicy,
                                         timeoutInterval: 60)
    }
}

/// Result for representing 'success' or 'failure'.
/// - success(T) is used when response is successfully received and serialized.
/// - failure(DRError) is used when any DRError is thrown.
public enum Result<T: Response> {
    case success(T)
    case failure(DRError)
}

/// Helper functions for Result
public extension Result {
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public var isFailure: Bool {
        return !isSuccess
    }
    
    public var response: T? {
        switch self {
        case .success(let response):
            return response
        case .failure:
            return nil
        }
    }
    
    public var error: DRError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

/// Delegate that could be used for request queue if you wish to get callback:
/// - before each request is sent
/// - after each request is sent
/// - when each request is failed
/// - when response is received
/// NOTE: RequestQueueDelegate will be called before RequestDelegate and ResponseDelegate.
public protocol RequestQueueDelegate {
    func requestQueue(_ requestQueue: RequestQueue, willSend request: inout URLRequest)
    func requestQueue(_ requestQueue: RequestQueue, didSend request: URLRequest)
    func requestQueue(_ requestQueue: RequestQueue, didFailWith request: URLRequest, error: DRError)
    func requestQueue(_ requestQueue: RequestQueue, didReceive response: URLResponse)
}

private let dispatchQueue = DispatchQueue(label: String(describing: RequestQueue.self),
                                          qos: .userInteractive,
                                          attributes: .concurrent)

/// RequestQueue maintains requests and observers.
/// Request can be added, removed and tracked in queue.
/// Observer is used to observe the corresponding response type of a request.
public class RequestQueue {
    // Type-erased observer block
    fileprivate struct AnyObserverBlock {
        private let base: Any
        private(set) weak var owner: AnyObject?
        
        init<T: Response>(_ base: @escaping (Result<T>) -> Void, owner: AnyObject?) {
            self.base = base
            self.owner = owner
        }
        
        func call<T: Response>(with result: Result<T>) {
            guard let block = base as? (Result<T>) -> Void else {
                return
            }
            block(result)
        }
    }

    fileprivate enum ObserverKey: Hashable {
        case responseType(String)
        case requestID(RequestID)
        
        var hashValue: Int {
            switch self {
            case .responseType(let responseType):
                return responseType.hashValue
            case .requestID(let requestID):
                return requestID.hashValue
            }
        }
        
        static func ==(lhs: ObserverKey, rhs: ObserverKey) -> Bool {
            if case .responseType(let responseType1) = lhs, case .responseType(let responseType2) = rhs {
                return responseType1 == responseType2
            } else if case .requestID(let requestID1) = lhs, case .requestID(let requestID2) = rhs {
                return requestID1 == requestID2
            } else {
                return false
            }
        }
    }
    
    public let configuration: RequestQueueConfiguration
    public let baseURL: URL
    fileprivate let delegate: RequestQueueDelegate?
    fileprivate let session: URLSession
    fileprivate var observers = [ObserverKey: [AnyObserverBlock]]()
    fileprivate let observersLock = NSLock()
    fileprivate var tasks = [RequestID: URLSessionTask]()
    fileprivate let tasksLock = NSLock()
    
    public init(configuration: RequestQueueConfiguration = RequestQueueConfiguration.default,
                delegate: RequestQueueDelegate? = nil,
                baseURL: URL) {
        self.configuration = configuration
        self.delegate = delegate
        self.baseURL = baseURL
        session = URLSession(configuration: configuration.sessionConfiguration)
    }
}

// MARK: Request ID

extension RequestQueue {
    private static var requestID: RequestID = 0
    private static let requestIDLock = NSLock()
    
    fileprivate func generateRequestID() -> RequestID {
        RequestQueue.requestIDLock.lock()
        defer {
            RequestQueue.requestIDLock.unlock()
        }
        RequestQueue.requestID += 1
        return RequestQueue.requestID
    }
}

// MARK: Add request to & remove request from queue

extension RequestQueue {
    
    /// Add a request to queue.
    /// Requests will be sent out in the order they are added.
    /// RequestID will be returned for the usage of adding observer, 
    /// removing request from queue and tracking finish stauts.
    /// RequestID is unique in all request queues.
    ///
    /// - parameter request: Request implemenation
    ///
    /// - returns: RequestID which is unique in all request queues.
    @discardableResult
    public func add<T: Request>(_ request: T) -> RequestID {
        let requestID = generateRequestID()
        dispatchQueue.async {
            let responseType = request.responseType()
            var urlRequest: URLRequest
            do {
                urlRequest = try RequestConverter.convert(request,
                                                          withBaseURL: self.baseURL,
                                                          cachePolicy: self.configuration.cachePolicy,
                                                          timeoutInterval: self.configuration.timeoutInterval)
            } catch {
                guard let error = (error as? DRError), case .invalidParameters = error else {
                    self.notify(for: requestID, responseType, with: .failure(.invalidParameters("Unknown reason")))
                    return
                }
                self.notify(for: requestID, responseType, with: .failure(error))
                return
            }
            
            self.delegate?.requestQueue(self, willSend: &urlRequest)
            if let requestDelegate = request as? RequestDelegate {
                requestDelegate.requestWillSend(&urlRequest)
            }
            
            let dataTask = self.session.dataTask(with: urlRequest) { (data, urlResponse, error) in
                self.tasksLock.lock()
                self.tasks.removeValue(forKey: requestID)
                self.tasksLock.unlock()
                do {
                    guard error == nil else {
                        throw DRError.invalidResponse(error!)
                    }
                    guard let data = data, let urlResponse = urlResponse else {
                        throw DRError.unknown
                    }
                    guard responseType.validate(urlResponse) else {
                        throw DRError.responseValidationFailed(urlResponse)
                    }
                    guard let response = responseType.init(data: ResponseData(data), response: urlResponse) else {
                        throw DRError.responseSerializationFailed
                    }
                    
                    self.delegate?.requestQueue(self, didReceive: urlResponse)
                    if let responseDelegate = response as? ResponseDelegate {
                        responseDelegate.responseDidReceive(urlResponse)
                    }
                    self.notify(for: requestID, request.responseType(), with: .success(response))
                } catch {
                    guard let error = error as? DRError else {
                        self.delegate?.requestQueue(self, didFailWith: urlRequest, error: .unknown)
                        if let requestDelegate = request as? RequestDelegate {
                            requestDelegate.request(urlRequest, didFailWith: .unknown)
                        }
                        self.notify(for: requestID, responseType, with: Result.failure(.unknown))
                        return
                    }
                    self.delegate?.requestQueue(self, didFailWith: urlRequest, error: error)
                    if let requestDelegate = request as? RequestDelegate {
                        requestDelegate.request(urlRequest, didFailWith: error)
                    }
                    self.notify(for: requestID, responseType, with: Result.failure(error))
                }
            }
            dataTask.resume()
            
            self.tasksLock.lock()
            self.tasks[requestID] = dataTask
            self.tasksLock.unlock()
            
            self.delegate?.requestQueue(self, didSend: urlRequest)
            if let requestDelegate = request as? RequestDelegate {
                requestDelegate.requestDidSend(urlRequest)
            }
        }
        return requestID
    }
    
    /// Cancel request from queue according to the given RequestID.
    ///
    /// - parameter requestID: RequestID returned by "add" function.
    public func cancel(_ requestID: RequestID) {
        dispatchQueue.async(flags: .barrier) {
            self.tasksLock.lock()
            if let task = self.tasks.removeValue(forKey: requestID) {
                task.cancel()
            }
            self.tasksLock.unlock()
            
            self.observersLock.lock()
            self.observers.removeValue(forKey: .requestID(requestID))
            self.observersLock.unlock()
        }
    }
    
    /// Check if a request is finished.
    /// A request is considered as finished:
    /// - Result.success or Result.failure is returned in observer.
    /// - request is removed from queue.
    /// 
    /// - parameter requestID: RequestID returned by "add" function.
    public func isFinished(_ requestID: RequestID) -> Bool {
        var isFinished = false
        dispatchQueue.sync(flags: .barrier) {
            tasksLock.lock()
            defer {
                tasksLock.unlock()
            }
            isFinished = tasks[requestID] == nil
        }
        return isFinished
    }
    
    private func notify<T: Response>(for requestID: RequestID, _ responseType: T.Type, with result: Result<T>) {
        let responseTypeKey = ObserverKey.responseType(String(describing: responseType))
        let requestIDKey = ObserverKey.requestID(requestID)
        
        self.observersLock.lock()
        // Only notify observers with owner
        let blocksForResponseType = (self.observers[responseTypeKey] ?? []).filter { $0.owner != nil }
        let blocksForRequestID = self.observers[requestIDKey] ?? []
        self.observers[responseTypeKey] = blocksForResponseType
        self.observers.removeValue(forKey: requestIDKey)
        self.observersLock.unlock()
        
        let blocks = blocksForResponseType + blocksForRequestID
        
        DispatchQueue.main.async {
            for block in blocks {
                block.call(with: result)
            }
        }
    }
}

// MARK: Observer

extension RequestQueue {
    
    /// Add observer for a specific response type.
    /// The observer will not be notified if it's owner is released.
    /// NOTE: block will be called in main thread.
    ///
    /// - parameter owner: owner that owns the observer. It will be weakly held in the queue.
    /// - parameter block: observer block which will be called when response or error is received.
    public func addObserver<T: Response>(ownedBy owner: AnyObject, using block: @escaping (Result<T>) -> Void) {
        observersLock.lock()
        defer {
            observersLock.unlock()
        }
        
        let key = ObserverKey.responseType(String(describing: T.self))
        if var blocks = observers[key] {
            blocks.append(AnyObserverBlock(block, owner: owner))
            observers[key] = blocks
        } else {
            observers[key] = [AnyObserverBlock(block, owner: owner)]
        }
    }
    
    /// Add observer for a specific requestID.
    /// The observer will be removed from the queue when the request is finished or removed.
    /// NOTE: block will be called in main thread.
    ///
    /// - parameter requestID: RequestID returned by "add" function.
    /// - parameter block: observer block which will be called when response or error is received.
    public func addObserver<T: Response>(for requestID: RequestID, using block: @escaping (Result<T>) -> Void) {
        observersLock.lock()
        defer {
            observersLock.unlock()
        }
        
        let key = ObserverKey.requestID(requestID)
        if var blocks = observers[key] {
            blocks.append(AnyObserverBlock(block, owner: nil))
            observers[key] = blocks
        } else {
            observers[key] = [AnyObserverBlock(block, owner: nil)]
        }
    }
    
    /// Remove observers for a specific response type which are owned by "owner".
    /// NOTE: block will be called in main thread.
    ///
    /// - parameter type: response type
    /// - parameter owner: owner that owns observers.
    public func removeObservers<T: Response>(forType type: T.Type, ownedBy owner: AnyObject) {
        observersLock.lock()
        defer {
            observersLock.unlock()
        }
        
        let key = ObserverKey.responseType(String(describing: type))
        guard let blocks = observers[key] else {
            return
        }
        observers[key] = blocks.filter { $0.owner !== owner }
    }
}
