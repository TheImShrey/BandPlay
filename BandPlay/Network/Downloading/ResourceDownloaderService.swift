//
//  ResourceDownloadService.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
import UniformTypeIdentifiers

typealias ResourceLoadingResult = ((ResourceDownloaderService.Progress) -> (Void))

protocol ResourceDownloaderServicible: AnyObject {
    func downloadResource(from url: URL,
                          of type: UTType,
                          onDownload: @escaping ResourceLoadingResult) -> ResourceDownloaderService.TrackerHandle
}

class ResourceDownloaderService {
    
    enum Progress {
        case inProgress(Double)
        case ended(Result<(downloadedAtURL: URL, suggestedFileName: String?), Error>)
    }
    
    /// - Note Progress tracking will be reported as long as caller holds the reference to the returned tracker handle
    struct TrackerHandle {
        let task: NetworkTaskable
        let downloadProgressObservation: NSKeyValueObservation
    }
    
    struct Request {
        struct Constants {
            static let defaultMimeType = "application/octet-stream"
        }
        
        let url: URL
        let type: UTType

        init(url: URL, type: UTType) {
            self.url = url
            self.type = type
        }
    }
    
    let networkSession: URLSession
    init(environment: Environment) {
        networkSession = URLSession(configuration: environment.defaultNetworkConfiguration)
    }
}

extension ResourceDownloaderService.Request: Requestable {
    var method: RequestableMethod {
        return .get
    }
    
    var headers: [String : String] {
        let mimeType = type.preferredMIMEType ?? Constants.defaultMimeType
        return ["Content-Type": mimeType]
    }
    
    /// One day as default timeout Interval
    var timeoutInterval: TimeInterval {
        return 24 * 60 * 60
    }
    
    /// Use network layer level cache for downloads
    var cachePolicy: URLRequest.CachePolicy {
        return .returnCacheDataElseLoad
    }
}

extension ResourceDownloaderService: ResourceDownloaderServicible {
    func downloadResource(from url: URL,
                          of type: UTType,
                          onDownload: @escaping ResourceLoadingResult) -> TrackerHandle {
        let downloadRequest = Request(url: url, type: type).request
        let downloadTask = networkSession.downloadTask(with: downloadRequest) { (downloadedFileURL, response, error) in
            if let error {
                onDownload(.ended(.failure(error)))
            } else if let downloadedFileURL {
                onDownload(.ended(.success((downloadedAtURL: downloadedFileURL,
                                            suggestedFileName: response?.suggestedFilename))))
            } else {
                onDownload(.ended(.failure(AppError.somethingWentWrong)))
            }
        }
        
        let downloadProgressObservation = downloadTask.progress.observe(\.fractionCompleted) { (progress, _) in
            onDownload(.inProgress(progress.fractionCompleted))
        }
        
        downloadTask.resume()
        return TrackerHandle(task: downloadTask, downloadProgressObservation: downloadProgressObservation)
    }
}
