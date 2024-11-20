//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController, RendererDelegate {
    
    var renderer: Renderer!
    
    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /// Load mesh
        let mainBundle = Bundle.main
        let fileURL = mainBundle.url(forResource: "teapot", withExtension: "obj", subdirectory: "meshes")!
        // let fileURL = mainBundle.url(forResource: "cat", withExtension: "obj", subdirectory: "meshes")!
        // let fileURL = mainBundle.url(forResource: "cube-normal", withExtension: "obj", subdirectory: "meshes")!

        // let mesh = Mesh.fromOBJ(url: fileURL)
        let mesh = Mesh.fromOBJ(url: fileURL,
                                origin: simd_float3(0.0, -1.0, 6.0),
                                rotation: simd_float3(0.8, 0, 0),
                                scale: simd_float3(1, 1, 1))
        mesh.calculateNormals()  // only needed if original OBJ has no normals. Maybe detect this automatically?
        
        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        renderer = Renderer(device: device!, mesh: mesh)
        
        /// Set up device and metalView
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 0.0
        metalView.delegate = renderer
        renderer.delegate = self

    }
    
    func preRenderUpdate(mesh: Mesh) {
        let time = Date().timeIntervalSince1970.magnitude
        // let xPosition = Float(cos(time) * 2.5) + 4.0
        let yPosition = Float(sin(time) * 2.5)
        mesh.rotation = simd_float3(0.8, yPosition, 0)
    }

}
