//
//  Extensions.swift
//  BandPlay
//
//  Created by Shreyash Shah on 02/03/24.
//

import UIKit

extension UIButton {
    /// Adds a closure-based action to the button.
    ///
    /// - Parameters:
    ///   - controlEvents: The control events that trigger the closure (e.g., .touchUpInside).
    ///   - closure: The closure to be executed when the button is tapped.
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
        let action = UIAction { _ in
            closure()
        }
        
        self.addAction(action, for: controlEvents)
    }
}
