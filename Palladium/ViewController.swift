//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController {
    
    var renderer: Renderer!
    
    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /// Load mesh
        let mainBundle = Bundle.main
        let fileURL = mainBundle.url(forResource: "cat", withExtension: "obj", subdirectory: "meshes")!
        let teapotMesh = Mesh.fromOBJ(url: fileURL)
        teapotMesh.calculateNormals()
        
        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        renderer = Renderer(device: device!, mesh: teapotMesh)
        /// Set up device and metalView
        metalView.delegate = renderer

    }
    
}
