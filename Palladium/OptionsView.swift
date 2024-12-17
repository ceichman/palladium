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
    
    var options = RendererOptions()
    var tableView = UITableView()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    let data = ["wireframe", "texturing", "specular"]
    
    func setup() {
        
        // setup table view header
        let header = UIView(frame: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 60))
        header.backgroundColor = .red
        
        let headerLabel = UILabel(frame: header.frame)
        headerLabel.textAlignment = .center
        headerLabel.text = "Options"
        headerLabel.font = .systemFont(ofSize: 22, weight: .medium)
        header.addSubview(headerLabel)
        
        let closeButton = UIButton(configuration: .tinted())
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        header.addSubview(closeButton)

        // configure table view
        let tableViewBounds = CGRect(x: bounds.minX, y: bounds.minY + 60, width: bounds.width, height: bounds.height - 60)
        tableView.frame = tableViewBounds
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        self.addSubview(tableView)

        // set up blur effect behind table view
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
        self.sendSubviewToBack(blurEffectView)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func flyIn() {
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
        return options
    }

}

class OptionCell: UITableViewCell {
    
}
