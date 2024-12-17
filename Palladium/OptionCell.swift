//
//  OptionCell.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/17/24.
//

import Foundation
import UIKit

protocol OptionCell: UITableViewCell {
    
    static var identifier: String { get }
    
    func configure(with key: OptionKey, state: OptionType)
    
}

class OptionCellBool: UITableViewCell, OptionCell {
    
    var label: UILabel = {
         let label = UILabel()
         label.textColor = .label
         label.isUserInteractionEnabled = false
         return label
     }()
    
    var toggle: OptionSwitch = {
        let toggle = OptionSwitch(frame: .zero)
        toggle.isUserInteractionEnabled = true
        // setup switch
        return toggle
    }()
    

    static let identifier = "OptionCellBool"
    
    private func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.isUserInteractionEnabled = true
        label.frame = self.bounds.insetBy(dx: 15, dy: 0)
        self.contentView.addSubview(label)
        self.accessoryView = toggle
    }
    

    func configure(with key: OptionKey, state: OptionType) {
        // convert camel case to display string
        label.text = key.rawValue
        toggle.key = key
        let enabled = state.asBool()!
        toggle.isOn = enabled
        setup()
    }
}

class OptionSwitch: UISwitch {
    var key = OptionKey.none
}

class OptionCellFloat: UITableViewCell, OptionCell {
    
    static let identifier = "OptionCellFloat"
    
    var label: UILabel = {
         let label = UILabel()
         label.textColor = .label
         label.isUserInteractionEnabled = false
         return label
    }()
    
    var slider: OptionSlider = {
        let slider = OptionSlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        return slider
    }()
    
    private func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.isUserInteractionEnabled = true
        label.frame = self.bounds.insetBy(dx: 15, dy: 0)
        slider.frame = self.bounds.insetBy(dx: 100, dy: 0)
        self.contentView.addSubview(label)
        self.accessoryView = slider
    }

    func configure(with key: OptionKey, state: OptionType) {
        // convert camel case to display string
        label.text = key.rawValue
        slider.key = key
        slider.value = state.asFloat()!
        setup()
    }

}

class OptionSlider: UISlider {
    var key = OptionKey.none
}
