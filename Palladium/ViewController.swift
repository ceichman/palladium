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
    var object: Object!
    var camera: Camera!
    
    let cameraVelocity: Float = 5.0
    
    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var boxBlurSwitch: UISwitch!
    @IBOutlet weak var gaussianBlurSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /// Load meshes
        let mainBundle = Bundle.main
        
        let cubeNormalURL = mainBundle.url(forResource: "cube-normal", withExtension: "obj", subdirectory: "meshes")!
        let cubeNormalMesh = Mesh.fromOBJ(url: cubeNormalURL)
        let cubeNormalObject = Object(mesh: cubeNormalMesh)
        cubeNormalObject.position = simd_float3(0.0, 0.0, 3.0)
        cubeNormalObject.rotation = simd_float3(0.4, 0, 0)
        
        let teapotURL = mainBundle.url(forResource: "teapot", withExtension: "obj", subdirectory: "meshes")!
        let teapotMesh = Mesh.fromOBJ(url: teapotURL)
        teapotMesh.calculateNormals()
        let teapotObject = Object(mesh: teapotMesh)
        teapotObject.position = simd_float3(0.0, -1.0, 6.0)
        teapotObject.rotation = simd_float3(0.8, 0, 0)
        
        let catURL = mainBundle.url(forResource: "cat", withExtension: "obj", subdirectory: "meshes")!
        let catMesh = Mesh.fromOBJ(url: catURL)
        catMesh.calculateNormals()
        let catObject = Object(mesh: catMesh)
        catObject.position = simd_float3(0.0, -1.0, 4.0)
        catObject.scale = simd_float3.one / 1000
        
        let pumpkinURL = mainBundle.url(forResource: "pumpkin", withExtension: "obj", subdirectory: "meshes")!
        let pumpkinMesh = Mesh.fromOBJ(url: pumpkinURL)
        pumpkinMesh.calculateNormals()
        let pumpkinObject = Object(mesh: pumpkinMesh)
        pumpkinObject.position = simd_float3(0.0, -1.0, 3.0)
        pumpkinObject.scale = simd_float3.one / 10
        
        let axisURL = mainBundle.url(forResource: "axis", withExtension: "obj", subdirectory: "meshes")!
        let axisMesh = Mesh.fromOBJ(url: axisURL)
        axisMesh.calculateNormals()
        let axisObject = Object(mesh: axisMesh)
        axisObject.position = simd_float3(5.0, 5.0, 4.0)
        
        let spotURL = mainBundle.url(forResource: "spot", withExtension: "obj", subdirectory: "meshes")!
        let spotMesh = Mesh.fromOBJ(url: spotURL)
        let spotObject = Object(mesh: spotMesh)
        spotObject.position = simd_float3(-1.0, 0.5, 4.0)
        spotObject.rotation = simd_float3(0, Float.pi, 0)
        
        
        /// Set up camera
        self.camera = Camera(position: simd_float3(0, 0, 0))
        
        let device = MTLCreateSystemDefaultDevice()!
        metalView.device = device
        
        let texLoader = MTKTextureLoader(device: device)
        
        let spotTextureURL = mainBundle.url(forResource: "spot-texture-raster", withExtension: "png", subdirectory: "textures")!
        let spotTexture = try! texLoader.newTexture(URL: spotTextureURL)

        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        self.object = Object(mesh: spotMesh, texture: spotTexture)
        renderer = Renderer(view: metalView, object: object, camera: camera)
        
        /// Set up device and metalView
        metalView.delegate = renderer
        renderer.delegate = self
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panRecognizer.minimumNumberOfTouches = 1
        panRecognizer.maximumNumberOfTouches = 1
        metalView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        metalView.addGestureRecognizer(pinchRecognizer)
    }
    
    func preRenderUpdate(deltaTime: CFTimeInterval) {
        let time = Date().timeIntervalSince1970.magnitude
        // let xPosition = Float(cos(time) * 2.5) + 4.0
        let yPosition = Float(sin(time) * 2.5)
        // object.mesh.rotation = simd_float3(0, Float(time), 0)
        object.rotation = simd_float3(0, yPosition, 0)
        camera.move(deltaTime: deltaTime)
    }
    
    @IBAction func upButtonPressed(_ sender: UIButton) {
        camera.velocityY = cameraVelocity
    }
    
    @IBAction func downButtonPressed(_ sender: UIButton) {
        camera.velocityY = -cameraVelocity
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        let forward = camera.lookDirection
        camera.velocityX += forward.x * cameraVelocity
        camera.velocityY += forward.y * cameraVelocity
        camera.velocityZ += forward.z * cameraVelocity
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        let forward = camera.lookDirection
        camera.velocityX -= forward.x * cameraVelocity
        camera.velocityY -= forward.y * cameraVelocity
        camera.velocityZ -= forward.z * cameraVelocity
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
    
    @IBAction func resetCameraVelocity(_ sender: UIButton) {
        camera.velocityX = 0.0
        camera.velocityY = 0.0
        camera.velocityZ = 0.0
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
            camera.pitch = (camera.pitch - dy * sensitivity).clamped(to: -Double.pi / 2.0...Double.pi / 2.0)
            camera.yaw -= dx * sensitivity
            
        default:
            lastLocation = CGPoint()
        }
    }
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        let newFov = renderer.options.fovDegrees / sender.scale
        renderer.options.fovDegrees = newFov.clamped(to: 15...85)
        sender.scale = 1.0
    }
    
    @IBAction func wireframeSwitchDidChange(_ sender: UISwitch) {
        renderer.options.wireframe = sender.isOn
    }
    
    @IBAction func boxBlurSwitchDidChange(_ sender: UISwitch) {
        renderer.options.boxBlur = sender.isOn
        if sender.isOn {
            gaussianBlurSwitch.setOn(false, animated: true)
            renderer.options.gaussianBlur = false
        }
    }
    
    @IBAction func gaussianBlurSwitchDidChange(_ sender: UISwitch) {
        renderer.options.gaussianBlur = sender.isOn
        if sender.isOn {
            boxBlurSwitch.setOn(false, animated: true)
            renderer.options.boxBlur = false
        }
    }
    
    @IBAction func invertColorsSwitchDidChange(_ sender: UISwitch) {
        renderer.options.invertColors = sender.isOn
    }
    
}
