//
//  ArtworkImageLoaderService.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import Foundation
import UIKit
import SwiftData

typealias ArtworkImageLoadingResult = ((ArtworkImageLoadingState) -> (Void))

enum ArtworkImageResolution: Int {
    case low = 108
    case sd = 540
    case hd = 1080
}

enum ArtworkImageLoadingState {
    case awaited
    case loaded(image: UIImage)
    case failed(error: Error)
}

protocol ArtworkImageLoaderServicible {
    func loadArtworkImage(for musicId: String,
                          in resolution: ArtworkImageResolution,
                          onLoaded: @escaping ArtworkImageLoadingResult) -> NetworkTaskable
}

final class MockArtworkImageLoaderService {
    struct Constants {
        static let cacheDirectoryBaseName = "MockArtworkImageLoader"
        static let memoryCapacity = 10 * 1024 * 1024
        static let diskCapacity = 10 * 1024 * 1024
        static let requestTimeoutInterval = 5 * 60.0
        static let initialSeed = 1050
    }
    
    enum Errors: Error {
        case cacheMiss
    }
    
    private let environment: Environment
    private var mockIdAndURLMapping: [String: URL]
    private var seed: Int
    private let networkSession: URLSession
    private let id = UUID()
    
    init(environment: Environment) {
        self.environment = environment
        self.mockIdAndURLMapping = [:]
        
        let configuration = environment.defaultNetworkConfiguration
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = Constants.requestTimeoutInterval
        self.seed = Constants.initialSeed
        
        self.networkSession = URLSession(configuration: configuration)
    }
}


extension MockArtworkImageLoaderService: ArtworkImageLoaderServicible {
    func loadArtworkImage(for musicId: String,
                          in resolution: ArtworkImageResolution,
                          onLoaded: @escaping ArtworkImageLoadingResult) -> NetworkTaskable {
        let imageURL: URL
        if let _imageURL = mockIdAndURLMapping[musicId] {
            imageURL = _imageURL
        } else {
            /// - Note Use picsum to load random images based on arbitrary id from model Id
            self.seed += 1
            guard let _imageURL = URL(string: "https://picsum.photos/id/\(self.seed)")
            else {
                assertionFailure("Mocked Artwork URL is invalid")
                fatalError()
            }
            
            self.mockIdAndURLMapping[musicId] = _imageURL
            imageURL = _imageURL
        }
                      
        let imageURLForResolution = imageURL
            .appendingPathComponent("\(resolution.rawValue)")
            .appendingPathComponent("\(resolution.rawValue)")
        
        let downloadRequest = URLRequest(url: imageURLForResolution)
        
        let loadingTask = networkSession.dataTask(with: downloadRequest) { [weak self] (data, response, error) in
            if let error {
                onLoaded(.failed(error: error))
            } else if let data {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        print(imageURLForResolution)
                        self?.storeArtworkImageDataToPersistedStorage(data, having: imageURLForResolution)
                    }
                   
                    onLoaded(.loaded(image: image))
                } else {
                    onLoaded(.failed(error: AppError.invalidImageFile))
                }
            } else {
                onLoaded(.failed(error: AppError.somethingWentWrong))
            }
        }
        
        DispatchQueue.main.async { [weak self, loadingTask] in
            guard let self else { return }
            
            do {
                let artworkImage = try self.retriveArtworkFromPersistedStorage(having: imageURLForResolution)
                onLoaded(.loaded(image: artworkImage))
                if loadingTask.state == .running {
                    loadingTask.cancel()
                }
            } catch {
                debugPrint("Artwork Cache miss musicId: (\(musicId)): \(error)")
                if loadingTask.state == .suspended {
                    loadingTask.resume()
                }
            }
        }
        
        return loadingTask
    }
}


// MARK: - Caching Artwork Images
extension MockArtworkImageLoaderService {
    @MainActor private func retriveArtworkFromPersistedStorage(having url: URL) throws -> UIImage {
        let artworkDataFetchDescriptor = FetchDescriptor<ArtworkImagePersistable>()
        let persistanceContainer = self.environment.persistanceContainer
        let persistedArtworkDatas = try persistanceContainer?.mainContext.fetch(artworkDataFetchDescriptor)
        if let persistedArtworkData = persistedArtworkDatas?.first(where: { $0.url == url }),
           let image = UIImage(data: persistedArtworkData.data) {
            return image
        } else {
            throw Errors.cacheMiss
        }
    }
    
    @MainActor private func storeArtworkImageDataToPersistedStorage(_ data: Data, having url: URL) {
        let artworkPersistableData = ArtworkImagePersistable(url: url, data: data)
        self.environment.persistanceContainer?.mainContext.insert(artworkPersistableData)
    }
}
