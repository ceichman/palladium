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
    var objects: [String:Object]!
    var camera: Camera!
    
    let cameraVelocity: Float = 5.0
    
    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var boxBlurSwitch: UISwitch!
    @IBOutlet weak var gaussianBlurSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /// Load meshes
        let mainBundle = Bundle.main
        
        let cubeNormalObject = Object(meshName: "cube-normal")
        cubeNormalObject.position = simd_float3(0.0, 0.0, 3.0)
        cubeNormalObject.rotation = simd_float3(0.4, 0, 0)
        
        let teapotObject = Object(meshName: "teapot")
        teapotObject.position = simd_float3(-6.0, -6.0, 1.0)
        teapotObject.rotation = simd_float3(0, 0, 0)
        
        let catObject = Object(meshName: "cat")
        catObject.position = simd_float3(0.0, -1.0, 4.0)
        catObject.scale = simd_float3.one / 1000
        
        let pumpkinObject = Object(meshName: "pumpkin")
        pumpkinObject.position = simd_float3(0.0, -1.0, 8.0)
        pumpkinObject.scale = simd_float3.one / 50
        
        let axisObject = Object(meshName: "axis")
        axisObject.position = simd_float3(1.0, 0.0, 0.0)
        axisObject.scale = simd_float3.one / 10.0

        let spotObject = Object(meshName: "spot", textureName: "spot-texture")
        spotObject.position = simd_float3(-1.0, 0.5, 4.0)
        spotObject.rotation = simd_float3(0, Float.pi, 0)
        spotObject.scale = simd_float3(2, 2, 2)
        
        let pineappleObject = Object(meshName: "pineapple2")//, textureName: "pineapple2")
        pineappleObject.position = simd_float3(0, -1, -4)
        pineappleObject.rotation = simd_float3(2.0 * Float.pi / 5, 5 * Float.pi / 6, Float.pi / 3)
        pineappleObject.scale = simd_float3.one * 4
        
        
        /// Set up camera
        self.camera = Camera(position: simd_float3(8.5, 3.2, 6.1))
        camera.yaw = -2.8
        camera.pitch = -0.45
        
        let device = MTLCreateSystemDefaultDevice()!
        metalView.device = device
        

        /// Creates a Renderer object (from refactor). Only supports a single mesh atm
        self.objects = ["spot": spotObject, "pumpkin": pumpkinObject, "axis": axisObject, "pineapple": pineappleObject, "teapot": teapotObject]
        renderer = Renderer(view: metalView, objects: ([Object])(objects.values), camera: camera)
        
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
        let animationA = Float(cos(time * 2) + 2)
        let animationB = Float(sin(time) * 2.5)
        objects["spot"]!.rotation = simd_float3(0, animationB, 0)
        objects["pumpkin"]!.scale = simd_float3(repeating: animationA) / 50
        objects["teapot"]!.rotation = simd_float3(animationA * 8, 0, 0)
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
    
    @IBAction func texturingSwitchDidChange(_ sender: UISwitch) {
        renderer.options.texturing = sender.isOn
    }
    
}
