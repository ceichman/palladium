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
        
        
        /// Load meshes
        let mainBundle = Bundle.main
        
        let teapotURL = mainBundle.url(forResource: "teapot", withExtension: "obj", subdirectory: "meshes")!
        let teapotMesh = Mesh.fromOBJ(url: teapotURL,
                                position: simd_float3(0.0, -1.0, 6.0),
                                rotation: simd_float3(0.8, 0, 0),
                                scale: simd_float3(1, 1, 1))
        // only needed if original OBJ has no normals. Maybe detect this automatically?
        teapotMesh.calculateNormals()
        
        let catURL = mainBundle.url(forResource: "cat", withExtension: "obj", subdirectory: "meshes")!
        let catMesh = Mesh.fromOBJ(url: catURL,
                                position: simd_float3(0.0, -1.0, 6.0),
                                rotation: simd_float3(0.8, 0, 0),
                                scale: simd_float3(0.01, 0.01, 0.01))
        catMesh.calculateNormals()
        
        let pumpkinURL = mainBundle.url(forResource: "pumpkin", withExtension: "obj", subdirectory: "meshes")!
        let pumpkinMesh = Mesh.fromOBJ(url: pumpkinURL,
                                       position: simd_float3(0.0, -1.0, 8.0),
                                       rotation: simd_float3(0, 0, 0),
                                       scale: simd_float3(0.1, 0.1, 0.1))
        pumpkinMesh.calculateNormals()

        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        renderer = Renderer(device: device!, mesh: pumpkinMesh)
        
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
        mesh.rotation = simd_float3(0, yPosition, 0)
    }

}
