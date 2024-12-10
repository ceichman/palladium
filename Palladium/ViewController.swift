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
    var scene: Scene!
    var objects: [String:Object]!
    
    let cameraVelocity: Float = 5.0
    
    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var boxBlurSwitch: UISwitch!
    @IBOutlet weak var gaussianBlurSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()!
        metalView.device = device
        
        scene = Scene.defaultScene
        renderer = Renderer(view: metalView, scene: scene)
        
        /// Set up device and metalView
        metalView.delegate = renderer

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panRecognizer.minimumNumberOfTouches = 1
        panRecognizer.maximumNumberOfTouches = 1
        metalView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        metalView.addGestureRecognizer(pinchRecognizer)
    }
    
    @IBAction func upButtonPressed(_ sender: UIButton) {
        scene.camera.verticalVelocity = cameraVelocity
    }
    
    @IBAction func downButtonPressed(_ sender: UIButton) {
        scene.camera.verticalVelocity = -cameraVelocity
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        scene.camera.forwardVelocity = cameraVelocity
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        scene.camera.forwardVelocity = -cameraVelocity
    }

    @IBAction func leftButtonPressed(_ sender: UIButton) {
        scene.camera.strafeVelocity = -cameraVelocity
    }
    
    @IBAction func rightButtonPressed(_ sender: UIButton) {
        scene.camera.strafeVelocity = cameraVelocity
    }
    
    @IBAction func resetCameraVelocity(_ sender: UIButton) {
        scene.camera.forwardVelocity = 0
        scene.camera.strafeVelocity = 0
        scene.camera.verticalVelocity = 0
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
            scene.camera.pitch = (scene.camera.pitch - dy * sensitivity).clamped(to: -Double.pi / 2.0...Double.pi / 2.0)
            scene.camera.yaw -= dx * sensitivity
            
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
    
    @IBAction func specularHighlightsSwitchDidChange(_ sender: UISwitch) {
        renderer.options.specularHighlights = sender.isOn
    }
    
}
