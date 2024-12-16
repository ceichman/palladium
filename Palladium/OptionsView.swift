//
//  OptionsView.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/15/24.
//

import Foundation
import UIKit

class OptionsView: UIView {
    
    static let duration = 0.5;
    
    func flyIn() {
        UIView.animate(withDuration: Self.duration, animations: {
            let moveLeft = CGAffineTransform(translationX: -(self.bounds.width), y: 0)
            self.transform = moveLeft
        })
    }
    
    func flyOut() {
        UIView.animate(withDuration: Self.duration, animations: {
            let zero = CGAffineTransform(translationX: 0, y: 0)
            self.transform = zero
        })
    }
    
}
