//
//  ArtworkImageLoadingState+Ext.swift
//  BandPlay
//
//  Created by Shreyash Shah on 05/03/24.
//

import UIKit

extension ArtworkImageLoadingState {
    
    var image: UIImage {
        switch self {
        case .awaited:
            return UIImage(systemName: "photo.badge.arrow.down.fill") ?? UIImage()
        case .loaded(let image):
            return image
        case .failed:
            return UIImage(systemName: "xmark.rectangle.fillpreviewThumbnail") ?? UIImage()
        }
    }
    
    var tintColor: UIColor? {
        switch self {
        case .awaited:
            return .tintColor
        case .loaded:
            return nil
        case .failed:
            return .systemRed
        }
    }
}
