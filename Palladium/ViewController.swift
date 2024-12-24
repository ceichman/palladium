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
    
    let cameraVelocity: Float = 5.0
    
    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var boxBlurSwitch: UISwitch!
    @IBOutlet weak var gaussianBlurSwitch: UISwitch!
    @IBOutlet weak var optionsView: OptionsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()!
        metalView.device = device
        
        renderer = Renderer(view: metalView, optionsProvider: optionsView)
        self.scene = renderer.scene
        
        /// Set up device and metalView
        metalView.delegate = renderer

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panRecognizer.minimumNumberOfTouches = 1
        panRecognizer.maximumNumberOfTouches = 1
        metalView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        metalView.addGestureRecognizer(pinchRecognizer)
    }
    
    @IBAction func shouldShowOptions(_ sender: UIButton) {
        optionsView.flyIn()
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
    let sensitivity: Double = 0.01
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
        let newFov = scene.camera.fovRadians / Float(sender.scale)
        scene.camera.fovRadians = newFov.clamped(to: scene.camera.minFovRadians...scene.camera.maxFovRadians)
        sender.scale = 1.0
    }
    
}
