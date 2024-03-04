//
//  MusicModel.swift
//  BandPlay
//
//  Created by Shreyash Shah on 03/03/24.
//

import Foundation
import UIKit

class MusicAsset {
    enum Status: Equatable {
        case pending
        case downloading(progress: Double)
        case ready
        case playing(elapsedTime: Double)
        case failed(error: Error)
        
        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending),
                (.downloading, .downloading),
                (.ready, .ready),
                (.playing, .playing),
                (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    let model: Music
    private(set) var localFileURL: URL?
    private(set) var artworkThumbnailURL: URL?
    private(set) var duration: Double
    private(set) var status: Status
    
    var id: String {
        return model.id
    }
    
    var name: String {
        return model.name
    }
    
    init(model: Music, duration: Double = 0.0, localFileURL: URL? = nil, artworkThumbnailURL: URL? = nil) {
        self.model = model
        self.status = localFileURL != nil ? .ready : .pending
        self.localFileURL = localFileURL
        self.artworkThumbnailURL = artworkThumbnailURL
        self.duration = duration
    }
    
    func set(status: Status) {
        self.status = status
    }
    
    func set(artworkThumbnailURL: URL) {
        self.artworkThumbnailURL = artworkThumbnailURL
    }
    
    func setDownloaded(localFileURL: URL, with duration: Double) {
        self.localFileURL = localFileURL
        self.duration = duration
        self.set(status: .ready)
    }
}
