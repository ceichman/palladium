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
    
    var options = RendererOptions.defaults
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
        tableView.register(OptionCellFloat.self, forCellReuseIdentifier: OptionCellFloat.identifier)
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
        let keys: [String] = options.keys.sorted()
        let key = keys[indexPath.row]
        let state = options[key]!
        switch state {
        case .bool(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionCellBool.identifier, for: indexPath) as! OptionCellBool
            cell.toggle.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            cell.configure(with: key, state: state)
            return cell
        case .float(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionCellFloat.identifier, for: indexPath) as! OptionCellFloat
            cell.configure(with: key, state: state)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.keys.count
    }
    
    @objc func switchChanged(_ sender: OptionSwitch!) {
        options[sender.key] = .bool(sender.isOn)
        if sender.key == "boxBlur" && options["gaussianBlur"]!.asBool()! {
            options["gaussianBlur"] = .bool(false)
            let gaussianIndex = options.keys.sorted().firstIndex(of: "gaussianBlur")!
            tableView.reloadRows(at: [IndexPath(row: gaussianIndex, section: 0)], with: .fade)
        }
        if sender.key == "gaussianBlur" && options["boxBlur"]!.asBool()! {
            options["boxBlur"] = .bool(false)
            let boxIndex = options.keys.sorted().firstIndex(of: "boxBlur")!
            tableView.reloadRows(at: [IndexPath(row: boxIndex, section: 0)], with: .fade)
        }
    }
    
    @objc func sliderChanged(_ sender: OptionSlider!) {
        options[sender.key] = .float(sender.value)
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
        return self.options
    }
    
}

