//
//  Environment.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
import UIKit
import SwiftData

enum EnvType: String {
    case release
    case debug
}

class Environment {
    struct Constants {
        static let persistanceStoreFileName = "BandPlay.store"
    }
    
    let defaultNetworkConfiguration: URLSessionConfiguration
    let sharedNetworkSession: URLSession
    let jsonDecoder: JSONDecoder
    let fileManager: BandPlayFileManager
    let persistanceContainer: ModelContainer?
    
    init(with type: EnvType) {
        // TODO: Configure environment variables depending `type` in future, ex: Mocked FileManager & urlSession with debug logs etc
        let fileManager = BandPlayFileManager()
        self.fileManager = fileManager
        
        /// - Note By doing this, we can easily mock the URLSession in future for testing, or add app wide network logging capabilities, throttling, etc
        let configuration = URLSessionConfiguration.default
        self.defaultNetworkConfiguration = configuration
        self.sharedNetworkSession = URLSession(configuration: configuration)
        
        self.jsonDecoder = JSONDecoder()

        do {
            try Environment.setupPersistentStorageDirectory(using: fileManager)
            let persistentStorageDirectoryURL = fileManager.persistentStorageDirectoryURL
            let persistentStoreFilePath = persistentStorageDirectoryURL.appending(component: Constants.persistanceStoreFileName)

            let configuration = ModelConfiguration(url: persistentStoreFilePath,
                                                   allowsSave: true)
            self.persistanceContainer = try ModelContainer(for: Persistables.MusicAsset.self, Persistables.ArtworkImageData.self,
                                                           configurations: configuration)
        } catch {
            self.persistanceContainer = nil
            debugPrint("Error while creating persistanceContainer: \(error)")
        }
    }
    
    class func setupPersistentStorageDirectory(using fileManager: BandPlayFileManager) throws {
        let persistentStorageDirectoryURL = fileManager.persistentStorageDirectoryURL
        guard fileManager.isDirectoryExists(at: persistentStorageDirectoryURL) == false else { return }
        try fileManager.createDirectory(at: persistentStorageDirectoryURL, withIntermediateDirectories: true)
    }
}
