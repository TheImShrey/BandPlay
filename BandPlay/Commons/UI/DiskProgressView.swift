//
//  DiskProgressView.swift
//  BandPlay
//
//  Created by Shreyash Shah on 04/03/24.
//

import UIKit

class DiskProgressView: UIProgressView {
    struct Metrics {
        static let threeSixtyDegreesInRadian = 2 * CGFloat.pi
        
        /// - Note Coordinates are flipped in UIKit hence 270 degrees will actually point to top
        static let startAngle = 3 * CGFloat.pi/2
        static let defaultDiskWidth: CGFloat = 3.0
    }
    
    struct Theme {
        static let defaultTrackTintColor = UIColor.tertiarySystemFill
        static let defaultProgressTintColor = UIColor.tintColor
    }
    
    var diskWidth: CGFloat? = nil
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let progressDiskWidth = self.diskWidth ?? Metrics.defaultDiskWidth
        context.setLineWidth(progressDiskWidth)

        // MARK: Draw background circle
        let rectSize = min(rect.width, rect.height) - progressDiskWidth
        let rect = CGRect(x: rect.midX - rectSize/2,
                          y: rect.midY - rectSize/2,
                          width: rectSize,
                          height: rectSize)
        
        let trackTintColor = self.trackTintColor ?? Theme.defaultTrackTintColor
        context.setStrokeColor(trackTintColor.cgColor)
        context.strokeEllipse(in: rect)
        
        // MARK: Draw progress arc
        let startAngle = Metrics.startAngle
        let progressAngleDelta = CGFloat(self.progress) * Metrics.threeSixtyDegreesInRadian
        let endAngle = Metrics.startAngle + progressAngleDelta
        
        context.addArc(center: CGPoint(x: rect.midX,
                                       y: rect.midY),
                       radius: (rectSize / 2.0),
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false) /// Coordinates are flipped in UIKit hence clockwise will actually work like counter clockwise
        let progressTintColor = self.progressTintColor ?? Theme.defaultProgressTintColor
        context.setStrokeColor(progressTintColor.cgColor)
        context.strokePath()
    }
}
