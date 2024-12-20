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
    
    var titleView: UIView = {
        let titleView = UIView()
        titleView.backgroundColor = .systemBackground
        return titleView
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 23, weight: .medium)
        label.text = "Options"
        label.textAlignment = .center
        return label
    }()
    
    var closeButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "xmark")!
        button.setImage(image, for: .normal)
        button.setPreferredSymbolConfiguration(.init(scale: .large), forImageIn: .normal)
        return button
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        
        let titleViewHeight = 60.0
        let titleViewFrame = CGRect(x: bounds.minX,
                                     y: bounds.minY,
                                     width: bounds.width,
                                     height: titleViewHeight)
        titleView.frame = titleViewFrame
        titleLabel.frame = titleViewFrame
        titleView.addSubview(titleLabel)
        self.addSubview(titleView)
        
        let buttonFrame = CGRect(x: bounds.minX,
                                 y: bounds.minY,
                                 width: titleViewHeight,
                                 height: titleViewHeight)
        closeButton.frame = buttonFrame
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.addTarget(self, action: #selector(shouldCloseOptions), for: .touchUpInside)
        titleView.addSubview(closeButton)

        tableView.dataSource = self
        tableView.delegate = self
        let tableViewFrame = CGRect(x: bounds.minX,
                                     y: bounds.minY + titleViewHeight,
                                     width: bounds.width,
                                     height: bounds.height - titleViewHeight)
        tableView.frame = tableViewFrame
        self.addSubview(tableView)
        
        blurView.frame = self.bounds
        tableView.backgroundView = blurView
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keys: [OptionKey] = options.keys.sortedOptions()
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
            cell.slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
            cell.configure(with: key, state: state)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.keys.count
    }
    
    @objc func switchChanged(_ sender: OptionSwitch!) {
        options[sender.key] = .bool(sender.isOn)
        
        // prevent both blurs from being applied at the same time
        // comes with a(n only slightly annoying) fade reload animation
        if sender.key == .boxBlur && options.getBool(.gaussianBlur) {
            options[.gaussianBlur] = .bool(false)
            let gaussianIndex = options.keys.sortedOptions().firstIndex(of: .gaussianBlur)!
            tableView.reloadRows(at: [IndexPath(row: gaussianIndex, section: 0)], with: .fade)
        }
        if sender.key == .gaussianBlur && options.getBool(.boxBlur) {
            options[.boxBlur] = .bool(false)
            let boxIndex = options.keys.sortedOptions().firstIndex(of: .boxBlur)!
            tableView.reloadRows(at: [IndexPath(row: boxIndex, section: 0)], with: .fade)
        }
        
    }
    
    @objc func sliderChanged(_ sender: OptionSlider!) {
        options[sender.key] = .float(sender.value)
    }
    
    @IBAction func shouldCloseOptions(_ sender: Any) {
        self.flyOut()
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

