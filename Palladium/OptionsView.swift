//
//  OptionsView.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/15/24.
//

import Foundation
import UIKit

class OptionsView: UIView, OptionsProvider, UITableViewDataSource, UITableViewDelegate {
    
    static let animationDuration = 0.3;
    
    // var options = RendererOptions()
    var options: [String:Bool] = [
        "boxBlur": false,
        "gaussianBlur": false,
        "invertColors": false,
        "texturing": true,
        "wireframe": false,
        "specularHighlights": true
    ]
    var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }()
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.isOpaque = false
        tableView.backgroundView = nil
        tableView.register(OptionCell.self, forCellReuseIdentifier: OptionCell.identifier)
        return tableView
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        let tableViewBounds = CGRect(x: bounds.minX,
                                     y: bounds.minY + 60,
                                     width: bounds.width,
                                     height: bounds.height - 60)
        tableView.frame = tableViewBounds
        
        self.addSubview(tableView)
        
        blurView.frame = self.bounds
        tableView.backgroundView = blurView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionCell.identifier, for: indexPath) as! OptionCell
        let keys: [String] = options.keys.sorted()
        let key = keys[indexPath.row]
        cell.configure(with: key, enabled: options[key]!)
        cell.toggle.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.keys.count
    }
    
    @objc func switchChanged(_ sender: OptionSwitch!) {
        options[sender.key] = sender.isOn
    }
    
    func flyIn() {
        // not sure why this has to go here
        tableView.backgroundColor = .clear
        UIView.animate(withDuration: Self.animationDuration, animations: {
            let moveLeft = CGAffineTransform(translationX: -(self.bounds.width), y: 0)
            self.transform = moveLeft
        })
    }
    
    func flyOut() {
        UIView.animate(withDuration: Self.animationDuration, animations: {
            let zero = CGAffineTransform(translationX: 0, y: 0)
            self.transform = zero
        })
    }
    
    func getOptions() -> RendererOptions {
        let opts = RendererOptions()
        opts.boxBlur = options["boxBlur"]!
        opts.gaussianBlur = options["gaussianBlur"]!
        opts.invertColors = options["invertColors"]!
        opts.texturing = options["texturing"]!
        opts.wireframe = options["wireframe"]!
        opts.specularHighlights = options["specularHighlights"]!
        return opts
    }
    
}

class OptionCell: UITableViewCell {
    
    static let identifier = "OptionCell"
    
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
    
    func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.isUserInteractionEnabled = true
        label.frame = self.bounds.insetBy(dx: 15, dy: 0)
        self.contentView.addSubview(label)
        self.accessoryView = toggle
    }
    
    func configure(with optionName: String, enabled: Bool) {
        // convert camel case to display string
        label.text = optionName.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized
        toggle.key = optionName
        toggle.isOn = enabled
        setup()
    }
    
}

class OptionSwitch: UISwitch {
    var key: String = ""
}
