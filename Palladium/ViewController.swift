//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal

class ViewController: UIViewController {
    
    var renderer: Renderer!
    var timer: CADisplayLink!
    var mesh: Mesh!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainBundle = Bundle.main
        let fileURL = mainBundle.url(forResource: "teapot", withExtension: "obj")!
        let teapotMesh = Mesh.fromOBJ(url: fileURL)
        self.mesh = teapotMesh
        
        renderer = Renderer(view: view, mesh: mesh)
        
        timer = CADisplayLink(target: self, selector: #selector(mainLoop))
        timer.add(to: RunLoop.main, forMode: .default)
    }
    
    @objc func mainLoop() {
        autoreleasepool {
            renderer.render()
        }
    }
}


