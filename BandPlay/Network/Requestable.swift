//
//  Requestable.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation

enum RequestableMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol Requestable {
    var url: URL { get }
    var request: URLRequest { get }
    var method: RequestableMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var timeoutInterval: TimeInterval { get }
    var cachePolicy: URLRequest.CachePolicy { get }
}

extension Requestable {
    var request: URLRequest {
        var request = URLRequest(url: self.url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeoutInterval)
        request.httpMethod = self.method.rawValue
        request.httpBody = self.body
        request.allHTTPHeaderFields = self.headers
        return request
    }
    
    var headers: [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    var body: Data? {
        return nil
    }
    
    var timeoutInterval: TimeInterval {
        return 60
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }
}
