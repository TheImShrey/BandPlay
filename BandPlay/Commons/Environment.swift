//
//  Environment.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
import UIKit

enum EnvType: String {
    case release
    case debug
}

class Environment {
    let defaultNetworkConfiguration: URLSessionConfiguration
    let sharedNetworkSession: URLSession
    let jsonDecoder: JSONDecoder
    let fileManager: BandPlayFileManager
    
    init(with type: EnvType) {
        UIDevice.current.isBatteryMonitoringEnabled = true

        // TODO: Configure environment variables depending `type` in future, ex: Mocked FileManager & urlSession with debug logs etc
        self.fileManager = BandPlayFileManager()
        
        /// - Note By doing this, we can easily mock the URLSession in future for testing, or add app wide network logging capabilities, throttling, etc
        let configuration = URLSessionConfiguration.default
        self.defaultNetworkConfiguration = configuration
        self.sharedNetworkSession = URLSession(configuration: configuration)
        
        self.jsonDecoder = JSONDecoder()
    }
}
