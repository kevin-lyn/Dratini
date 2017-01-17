//
//  Parameters.swift
//  Dratini
//
//  Created by Kevin Lin on 10/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import Foundation
import Ditto

/// This protocol is only used internally to eliminate the difference between QueryString and BodyData.
/// So don't adopt this protocol.
public protocol Parameters {}

/// Implement your custom query string encoding by conforming to QueryString protocol.
/// In most cases you should just use the default implementation DefaultQueryString.
public protocol QueryString: Parameters {
    func encode() throws -> String
}

public protocol DefaultQueryString: QueryString, Serializable {}

/// Default query string implementation.
/// Since there is no specification for array and dictionary serialization,
/// DefaultQueryString is following a generally accepted solution for array and dictionary serialization.
/// If a different behavior of array and dictionary serialization is expected,
/// you should implement your own query string serialization by adopting QueryString protocol.
///
/// Array parameter - key: [1,2,3] will be converted to:
/// key[]=1&key[]=2&key[]=3
///
/// Dictionary parameter - key: { "nested1": 1, "nested2": 2 } will be converted to:
/// key[nested1]=1&key[nested2]=2
public extension DefaultQueryString {
    func encode() throws -> String {
        let jsonObject: JSONObject = serialize()
        var pairs = [String]()
        for case (let key, let value?) in jsonObject {
            pairs.append(contentsOf: convert(key: key, value: value, escaped: false))
        }
        return pairs.joined(separator: "&")
    }
    
    func serializableMapping() -> Mapping {
        return AutoMapping.mapping(for: self, style: .lowercaseSeparatedByUnderscore)
    }
}

/// Basic body data encoding implementations are provided:
/// URLEncodedBodyData, JSONBodyData and MultipartFormData.
/// If you wish to have other form of body data encoding,
/// you should implement your own by conforming to BodyData protocol.
public protocol BodyData: Parameters {
    var contentType: String { get }
    func encode() throws -> Data
}

public protocol URLEncodedBodyData: BodyData, Serializable {}

/// See DefaultQueryString for array and dictionary encoding rules.
public extension URLEncodedBodyData {
    var contentType: String {
        return "application/x-www-form-urlencoded; charset=utf-8"
    }
    
    func encode() throws -> Data {
        let jsonObject: JSONObject = serialize()
        var pairs = [String]()
        for case (let key, let value?) in jsonObject {
            pairs.append(contentsOf: convert(key: key, value: value, escaped: true))
        }
        return pairs.joined(separator: "&").data(using: .utf8) ?? Data()
    }
    
    func serializableMapping() -> Mapping {
        return AutoMapping.mapping(for: self, style: .lowercaseSeparatedByUnderscore)
    }
}

public protocol JSONBodyData: URLEncodedBodyData, Serializable {}

/// JSON object body data.
public extension JSONBodyData {
    var contentType: String {
        return "application/json"
    }
    
    func encode() throws -> Data {
        guard let data: Data = serialize() else {
            throw DRError.invalidParameters("Invalid JSON body")
        }
        return data
    }
    
    func serializableMapping() -> Mapping {
        return AutoMapping.mapping(for: self, style: .lowercaseSeparatedByUnderscore)
    }
}

private protocol MultipartEntry {
    var name: String { get }
    var fileName: String? { get }
    var mimeType: String? { get }
    func encode() throws -> Data
}

private struct MultipartFileEntry: MultipartEntry {
    private let fileURL: URL
    let name: String
    let fileName: String?
    let mimeType: String?
    
    init(fileURL: URL, name: String, fileName: String?, mimeType: String?) {
        self.fileURL = fileURL
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    func encode() throws -> Data {
        guard fileURL.isFileURL else {
            throw DRError.invalidParameters("Invalid file URL")
        }
        guard let reachable = try? fileURL.checkPromisedItemIsReachable(), reachable else {
            throw DRError.invalidParameters("File URL is not reachable")
        }
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue else {
            throw DRError.invalidParameters("File is directory")
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            throw DRError.invalidParameters("Unable to read from file URL")
        }
        return data
    }
}

private struct MultipartDataEntry: MultipartEntry {
    private let data: Data
    let name: String
    let fileName: String?
    let mimeType: String?
    
    init(data: Data, name: String, fileName: String?, mimeType: String?) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    func encode() throws -> Data {
        return self.data
    }
}

private struct MultipartKeyValueEntry: MultipartEntry {
    private let value: Any
    let name: String
    let fileName: String?
    let mimeType: String?
    
    init(value: Any, name: String) {
        self.value = value
        self.name = name
        self.fileName = nil
        self.mimeType = nil
    }
    
    func encode() throws -> Data {
        guard let data = "\(value)".data(using: .utf8) else {
            throw DRError.invalidParameters("Invalid multipart key-value entry")
        }
        return data
    }
}

/// Multipart body data.
/// Raw data, fileURL and key value entry can be added.
/// Raw data: data will be simply appended to body data.
/// File URL: will try to access and read data from the file, 
/// DRError.invalidParameters will be thrown if file is not accessible.
open class MultipartFormData: BodyData {
    private let boundary = "dratini.boundary.\(UUID().uuidString).\(arc4random())"
    private let crlf = "\r\n"
    private var entries = [MultipartEntry]()
    
    public init() {}
    
    public var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }
    
    public func encode() throws -> Data {
        var data = Data()
        let boundaryData = "--\(boundary)\(crlf)".data(using: .utf8)!
        let crlfData = crlf.data(using: .utf8)!
        for entry in entries {
            data.append(boundaryData)
            
            var disposition = "Content-Disposition: form-data; name=\"\(entry.name)\""
            if let fileName = entry.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            data.append(disposition.data(using: .utf8)!)
            data.append(crlfData)
            
            if let mimeType = entry.mimeType {
                let contentType = "Content-Type: \(mimeType)"
                data.append(contentType.data(using: .utf8)!)
                data.append(crlfData)
            }
            
            data.append(crlfData)
            data.append(try entry.encode())
            data.append(crlfData)
        }
        data.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
        return data
    }
    
    public func append(fileURL: URL, withName name: String) {
        append(fileURL: fileURL, withName: name, fileName: name, mimeType: nil)
    }
    
    public func append(fileURL: URL, withName name: String, fileName: String?, mimeType: String?) {
        entries.append(MultipartFileEntry(fileURL: fileURL,
                                          name: name,
                                          fileName: fileName,
                                          mimeType: mimeType))
    }
    
    public func append(data: Data, withName name: String) {
        append(data: data, withName: name, fileName: name, mimeType: nil)
    }
    
    public func append(data: Data, withName name: String, fileName: String?, mimeType: String?) {
        entries.append(MultipartDataEntry(data: data,
                                          name: name,
                                          fileName: fileName,
                                          mimeType: mimeType))
    }
    
    public func append(value: Any, withName name: String) {
        entries.append(MultipartKeyValueEntry(value: value, name: name))
    }
}

/// Helper struct which could be used when parameters is not required.
public struct EmptyParameters: Parameters {
    public init() {}
}

// MARK: Helpers

// From Alamofire ParameterEncoding.swift
private let urlQueryAllowedCharacterSet: CharacterSet = {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    
    var allowedCharacterSet = CharacterSet.urlQueryAllowed
    allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
    return allowedCharacterSet
}()

private func escape(_ string: String) -> String {
    return string.addingPercentEncoding(withAllowedCharacters: urlQueryAllowedCharacterSet) ?? ""
}

// Convert to query string
private func convert(key: String, value: Any, escaped: Bool) -> [String] {
    if let array = value as? JSONArray {
        var pairs = [String]()
        for case let item? in array {
            pairs.append(contentsOf: convert(key: key.appending("[]"), value: item, escaped: escaped))
        }
        return pairs
    } else if let object = value as? JSONObject {
        var pairs = [String]()
        for case (let objectKey, let objectValue?) in object {
            pairs.append(contentsOf: convert(key: key.appending("[\(objectKey)]"), value: objectValue, escaped: escaped))
        }
        return pairs
    } else {
        if escaped {
            return ["\(escape(key))=\(escape("\(value)"))"]
        } else {
            return ["\(key)=\(value)"]
        }
    }
}
