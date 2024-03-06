//
//  Music.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation

// MARK: - Music
struct Music: Decodable, Equatable {
    let id: String
    let name: String
    let audioURL: String
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case audioURL
    }
    
    init(id: String, name: String, audioURL: String) {
        self.id = id
        self.name = name
        self.audioURL = audioURL
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: Music.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: Music.CodingKeys.name)
        self.audioURL = try container.decode(String.self, forKey: Music.CodingKeys.audioURL)
    }
}

