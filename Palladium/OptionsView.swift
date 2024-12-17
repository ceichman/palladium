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
    var options: [String:OptionType] = [
        "boxBlur": .bool(false),
        "gaussianBlur": .bool(false),
        "invertColors": .bool(false),
        "texturing": .bool(true),
        "wireframe": .bool(false),
        "specularHighlights": .bool(true)
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
        tableView.register(OptionCellBool.self, forCellReuseIdentifier: OptionCellBool.identifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionCellBool.identifier, for: indexPath) as! OptionCellBool
        let keys: [String] = options.keys.sorted()
        let key = keys[indexPath.row]
        cell.configure(with: key, state: options[key]!)
        cell.toggle.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.keys.count
    }
    
    @objc func switchChanged(_ sender: OptionSwitch!) {
        options[sender.key] = .bool(sender.isOn)
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
        opts.boxBlur = options["boxBlur"]!.forceBool()!
        opts.gaussianBlur = options["gaussianBlur"]!.forceBool()!
        opts.invertColors = options["invertColors"]!.forceBool()!
        opts.texturing = options["texturing"]!.forceBool()!
        opts.wireframe = options["wireframe"]!.forceBool()!
        opts.specularHighlights = options["specularHighlights"]!.forceBool()!
        return opts
    }
    
}


class OptionSwitch: UISwitch {
    var key: String = ""
}
