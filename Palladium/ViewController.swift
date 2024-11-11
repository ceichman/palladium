//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {
    
    var renderer: Renderer!
    
    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set up device and metalView
        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        metalView.delegate = self
        
        /// Load mesh
        let mainBundle = Bundle.main
        let fileURL = mainBundle.url(forResource: "teapot", withExtension: "obj")!
        let teapotMesh = Mesh.fromOBJ(url: fileURL)
        teapotMesh.calculateNormals()
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        renderer = Renderer(device: device!, mesh: teapotMesh)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO
    }
    
    func draw(in view: MTKView) {
        renderer.render(in: view)
    }
}
