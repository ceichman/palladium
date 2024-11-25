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
    var mesh: Mesh!
    var camera: Camera!
    
    let cameraVelocity: Float = 5.0
    
    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /// Load meshes
        let mainBundle = Bundle.main
        
        let cubeNormalURL = mainBundle.url(forResource: "cube-normal", withExtension: "obj", subdirectory: "meshes")!
        let cubeNormalMesh = Mesh.fromOBJ(url: cubeNormalURL,
                                          position: simd_float3(0.0, 0.0, 3.0),
                                          rotation: simd_float3(0.8, 0, 0),
                                          scale: simd_float3.one)
        
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
        
        let axisURL = mainBundle.url(forResource: "axis", withExtension: "obj", subdirectory: "meshes")!
        let axisMesh = Mesh.fromOBJ(url: axisURL,
                                    position: simd_float3(5.0, 5.0, 4.0),
                                    rotation: .zero,
                                    scale: .one)
        axisMesh.calculateNormals()
        
        /// Set up camera
        self.camera = Camera(position: simd_float3(0, 0, 0))
        
        let device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        self.mesh = axisMesh
        renderer = Renderer(device: device!, mesh: self.mesh, camera: camera)
        
        /// Set up device and metalView
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 0.0
        metalView.delegate = renderer
        renderer.delegate = self
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panRecognizer.minimumNumberOfTouches = 1
        panRecognizer.maximumNumberOfTouches = 1
        metalView.addGestureRecognizer(panRecognizer)
    }
    
    func preRenderUpdate(deltaTime: CFTimeInterval) {
        let time = Date().timeIntervalSince1970.magnitude
        // let xPosition = Float(cos(time) * 2.5) + 4.0
        let yPosition = Float(sin(time) * 2.5)
        // mesh.rotation = simd_float3(0, yPosition, 0)
        camera.move(deltaTime: deltaTime)
    }

    @IBAction func upButtonPressed(_ sender: UIButton) {
        camera.velocityY = cameraVelocity
    }
    
    @IBAction func downButtonPressed(_ sender: UIButton) {
        camera.velocityY = -cameraVelocity
    }
    
    @IBAction func leftButtonPressed(_ sender: UIButton) {
        let relativeLeft = camera.relativeLeft
        camera.velocityX += relativeLeft.x * cameraVelocity
        camera.velocityZ += relativeLeft.z * cameraVelocity
    }

    @IBAction func rightButtonPressed(_ sender: UIButton) {
        let relativeRight = camera.relativeRight
        camera.velocityX += relativeRight.x * cameraVelocity
        camera.velocityZ += relativeRight.z * cameraVelocity
    }
    
    @IBAction func resetHorizontal(_ sender: UIButton) {
        camera.velocityX = 0.0
        camera.velocityZ = 0.0
    }

    @IBAction func resetVertical(_ sender: UIButton) {
        camera.velocityY = 0.0
    }
    
    var lastLocation = CGPoint()
    let sensitivity: Double = 0.02
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            lastLocation = sender.location(in: metalView)
        case .changed:
            guard lastLocation != CGPoint() else { break }
            let location = sender.location(in: metalView)
            let (dx, dy) = (location.x - lastLocation.x, location.y - lastLocation.y)
            lastLocation = location
            camera.yaw -= dx * sensitivity
            camera.pitch -= dy * sensitivity
            
        default:
            lastLocation = CGPoint()
        }
    }
    
}
