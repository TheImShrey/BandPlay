//
//  MusicPlayList.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation

// MARK: - MusicPlayList
struct MusicPlayList: Decodable, Equatable {
    let musics: [Music]
    
    enum CodingKeys: String, CodingKey {
        case musics = "data"
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.musics = try container.decodeIfPresent([Music].self, forKey: CodingKeys.musics) ?? []
    }
}
