//
//  Config.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import Foundation
import UniformTypeIdentifiers

struct Constants {
    
}

enum FileTypes: String {
    case mp3 = "mp3"
    case jpeg = "jpeg"
    case png = "png"
    
    var uniformTypeIdentifier: UTType {
        switch self {
        case .mp3:
            return UTType.mp3
        case .jpeg:
            return UTType.jpeg
        case .png:
            return UTType.png
        }
    }
}

enum AppError: Error {
    case somethingWentWrong
    case invalidMusicFile
    case invalidImageFile
    case unknown
}
