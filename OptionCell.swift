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
    var key: String { get set }
    
    func configure(with optionName: String, state: OptionType)
    
}

class OptionCellBool: UITableViewCell, OptionCell {
    
    var key: String = ""
    
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
    
    func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.isUserInteractionEnabled = true
        label.frame = self.bounds.insetBy(dx: 15, dy: 0)
        self.contentView.addSubview(label)
        self.accessoryView = toggle
    }
    

    func configure(with optionName: String, state: OptionType) {
        // convert camel case to display string
        let enabled = state.forceBool()!
        label.text = optionName.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized
        toggle.key = optionName
        toggle.isOn = enabled
        setup()
    }
}

class OptionCellFloat: UITableViewCell, OptionCell {
    
    var label: UILabel = {
         let label = UILabel()
         label.textColor = .label
         label.isUserInteractionEnabled = false
         return label
     }()
    
    static let identifier = "OptionCellFloat"
    
    var key: String = ""
    
    func configure(with optionName: String, state: OptionType) {
        
    }

}
