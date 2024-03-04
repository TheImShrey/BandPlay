//
//  MusicListEmptyStateView.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import UIKit
import SnapKit

class MusicPlayListZeroStateView: UIView {
    enum State {
        case empty
        case loading
        case loaded
    }
    
    private struct Theme {
        static let loadButtonColor: UIColor = .tintColor
        static let loadingIcon = AppIcons.refresh.image
    }
    
    private enum AnimationKeys: String {
        case loadingViewRotation = "loadingViewRotationAnimation"
    }
    
    private let imageView: UIImageView
    private(set) var state: State
    
    convenience init(isCompact: Bool = false) {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        self.imageView = UIImageView(image: Theme.loadingIcon.withTintColor(Theme.loadButtonColor))
        self.state = .empty
        
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(imageView.snp.width)
        }
        
        self.set(state: self.state)
    }
    
    func set(state: State) {
        switch state {
        case .empty, .loaded:
            imageView.layer.removeAnimation(forKey: AnimationKeys.loadingViewRotation.rawValue)
        case .loading:
            imageView.layer.removeAnimation(forKey: AnimationKeys.loadingViewRotation.rawValue)
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = CGFloat.pi * 2
            rotationAnimation.duration = 1.0
            rotationAnimation.repeatCount = .infinity
            imageView.layer.add(rotationAnimation, forKey: AnimationKeys.loadingViewRotation.rawValue)
        }
        self.state = state
    }
}
