//
//  MusicItemViewModel+Ext.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import UIKit

extension MusicItemViewModel.ActionType {
    var title: String {
        switch self {
        case .download:
            return "Download"
        case .cancel:
            return "Cancel"
        case .play:
            return "Play"
        case .pause:
            return "Pause"
        case .failedErrorTap:
            return "Failed"
        case .musicSeek:
            return "Seek"
        case .openMusicDetails:
            return "Music Details"
        }
    }
    
    var image: UIImage {
        let icon: UIImage?
        switch self {
        case .cancel:
            icon = UIImage(systemName: "square.fill")
        case .download:
            icon = UIImage(named: "download")
        case .play:
            icon = UIImage(named: "play")
        case .pause:
            icon = UIImage(named: "pause")
        default:
            icon = nil
        }
        
        guard let icon else {
            assertionFailure("Failed to load refresh icon, this is not expected, Check if the SFSymbol name is valid.")
            return UIImage()
        }
        
        return icon
    }
    
    var foregroundColor: UIColor? {
        switch self {
        case .cancel:
            return .systemRed
        case .download, .play, .pause:
            return nil
        default:
            return nil
        }
    }
}

extension MusicAsset.Status {
    var nextAction: MusicItemViewModel.ActionType {
        switch self {
        case .pending:
            return .download
        case .downloading:
            return .cancel
        case .ready:
            return .play
        case .playing:
            return .pause
        case .failed:
            return .download
        }
    }
}
