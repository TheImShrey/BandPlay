//
//  MusicAssetPersistable.swift
//  BandPlay
//
//  Created by Shreyash Shah on 06/03/24.
//

import SwiftData
import Foundation

@Model
final class MusicAssetPersistable {
    @Attribute(.unique)
    let id: String
    let name: String
    let audioURL: String
    let localFileURL: URL?

    init(id: String,
         name: String,
         audioURL: String,
         localFileURL: URL?) {
        self.id = id
        self.name = name
        self.audioURL = audioURL
        self.localFileURL = localFileURL
    }
}

extension MusicAsset {
    convenience init(from model: MusicAssetPersistable) {
        self.init(model: Music(id: model.id,
                               name: model.name,
                               audioURL: model.audioURL),
                  localFileURL: model.localFileURL)
        
        switch model.localFileURL {
        case .some:
            self.set(status: .ready)
        case .none:
            self.set(status: .pending)
        }
    }
    
    func buildPersistable() -> MusicAssetPersistable {
        return MusicAssetPersistable(id: self.id,
                                     name: self.name,
                                     audioURL: self.model.audioURL,
                                     localFileURL: self.localFileURL)
    }
}
