//
//  DRError.swift
//  Dratini
//
//  Created by Kevin Lin on 10/1/17.
//  Copyright © 2017 Kevin. All rights reserved.
//

import Foundation

/// Dratini error type.
/// - invalidParameters(String): something went wrong during parameters encoding.
/// - invalidResponse(Error): error thrown by URLSession.
/// - responseValidationFailed(URLResponse): validation failed before serializing response.
/// - responseSerializationFailed: nil is returned by Response constructor.
/// - unknown: everything else unexpected.
public enum DRError: Error {
    case invalidParameters(String)
    case invalidResponse(Error)
    case responseValidationFailed(URLResponse)
    case responseSerializationFailed
    case unknown
}
