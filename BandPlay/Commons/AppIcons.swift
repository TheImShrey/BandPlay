//
//  AppIcons.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import UIKit

enum AppIcons: String {
    case refresh = "arrow.triangle.2.circlepath.circle.fill"
    case seekBarThumb = "circle.fill"
    
    var image: UIImage {
        guard let icon = UIImage(systemName: self.rawValue) else {
            assertionFailure("Failed to load refresh icon, this is not expected, Check if the SFSymbol name is valid.")
            return UIImage()
        }
        
        return icon
    }
}
