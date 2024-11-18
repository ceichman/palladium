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
        let fileURL = mainBundle.url(forResource: "teapot", withExtension: "obj", subdirectory: "meshes")!
        // let fileURL = mainBundle.url(forResource: "cat", withExtension: "obj", subdirectory: "meshes")!
        // let fileURL = mainBundle.url(forResource: "cube-normal", withExtension: "obj", subdirectory: "meshes")!
        let mesh = Mesh.fromOBJ(url: fileURL)
        mesh.calculateNormals()  // only needed if original OBJ has no normals. Maybe detect this automatically?
        
        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        renderer = Renderer(device: device!, mesh: mesh)
        /// Set up device and metalView
        metalView.delegate = renderer

    }
    
}
