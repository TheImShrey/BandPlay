//
//  ArtworkImagePersistable.swift
//  BandPlay
//
//  Created by Shreyash Shah on 06/03/24.
//

import SwiftData
import Foundation

@Model
final class ArtworkImagePersistable {
    @Attribute(.unique)
    let url: URL
    
    @Attribute(.externalStorage)
    let data: Data
    
    init(url: URL, data: Data) {
        self.url = url
        self.data = data
    }
}
