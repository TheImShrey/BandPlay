//
//  NetworkTaskable.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import Foundation

protocol NetworkTaskable {
    func cancel()
    func resume()
}

extension URLSessionDataTask: NetworkTaskable {}
extension URLSessionDownloadTask: NetworkTaskable {}
