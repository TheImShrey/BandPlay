//
//  MusicAsset+Ext.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import UIKit

extension MusicAsset.Status {
    var downloadProgress: Double {
        switch self {
        case .downloading(let progress):
            return progress
        case .ready, .playing:
            return 1.0
        default:
            return 0.0
        }
    }
    
    var elapsedTime: Double {
        switch self {
        case .playing(let elapsedTime):
            return elapsedTime
        default:
            return 0.0
        }
    }
    
    var labelText: String {
        switch self {
        case .pending:
            return "🔍 Discovered"
        case .downloading(let progress):
            let formattedProgress: String
            let value = progress * 100
            if value < 100 {
                formattedProgress = String(format: "%02.2f", value)
            } else {
                formattedProgress = String(format: "%.0f", value)
            }
            return "⬇️ Downloading: \(formattedProgress) % "
        case .ready:
            return "💾 Saved"
        case .playing:
            return "🎧 Playing"
        case .failed:
            return "‼️ Failed"
        }
    }
    
    var shortText: String {
        switch self {
        case .downloading(let progress):
            let formattedProgress: String
            let value = progress * 100
            if value < 100 {
                formattedProgress = String(format: "%02.2f", value)
            } else {
                formattedProgress = String(format: "%.0f", value)
            }
            return "⬇️ \(formattedProgress) % "
        default:
            return self.labelText
        }
    }
    
    var labelColor: UIColor {
        switch self {
        case .pending:
            return UIColor.systemGray
        case .downloading:
            return UIColor.systemYellow
        case .ready:
            return UIColor.systemGreen
        case .playing:
            return UIColor.systemBlue
        case .failed:
            return UIColor.systemRed
        }
    }
    
    var isPlaying: Bool {
        switch self {
        case .playing:
            return true
        default:
            return false
        }
    }
    
    var isDownloaded: Bool {
        switch self {
        case .ready, .playing:
            return true
        default:
            return false
        }
    }
    
    var isDownloading: Bool {
        switch self {
        case .downloading:
            return true
        default:
            return false
        }
    }
    
    var isFailed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
}
