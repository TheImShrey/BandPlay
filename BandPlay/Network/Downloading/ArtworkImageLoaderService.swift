//
//  ArtworkImageLoaderService.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import Foundation
import UIKit

typealias ArtworkImageLoadingResult = ((Result<UIImage, Error>) -> (Void))

enum ArtworkImageResolution: Int {
    case low = 108
    case sd = 540
    case hd = 1080
}

enum ArtworkImageLoadingState {
    case awaited
    case loaded(image: UIImage)
    case failed
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
    
    /// - Note In Memory Mocked Cache for loaded images, ideally this should be a disk cache
    private var mockIdAndURLMapping: [String: URL]
    private let urlCache: URLCache
    private var seed: Int
    private let networkSession: URLSession
    private let id = UUID()
    
    init(environment: Environment) {
        self.mockIdAndURLMapping = [:]
        let urlCache = URLCache(memoryCapacity: Constants.memoryCapacity,
                                diskCapacity: Constants.diskCapacity,
                                diskPath: "\(Constants.cacheDirectoryBaseName)-\(id.uuidString)")
        self.urlCache = urlCache
        
        let configuration = environment.defaultNetworkConfiguration
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache
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
        
        if let response = urlCache.cachedResponse(for: downloadRequest),
           let image = UIImage(data: response.data) {
            onLoaded(.success(image))
            return NoopTask()
        }
        
        let loadingTask = networkSession.dataTask(with: downloadRequest) { [weak self, downloadRequest] (data, response, error) in
            if let error {
                onLoaded(.failure(error))
            } else if let data {
                if let image = UIImage(data: data) {
                    if let response {
                        let cachedResponse = CachedURLResponse(response: response, data: data)
                        self?.urlCache.storeCachedResponse(cachedResponse, for: downloadRequest)
                    }
                   
                    onLoaded(.success(image))
                } else {
                    onLoaded(.failure(AppError.invalidImageFile))
                }
            } else {
                onLoaded(.failure(AppError.somethingWentWrong))
            }
        }
        
        loadingTask.resume()
        return loadingTask
    }
}
