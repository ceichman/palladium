//
//  Scene.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

class Scene {
    var objects: [ObjectTemplate:[ObjectInstance]] = [:]
    var directionalLights: [DirectionalLight] = []
    var pointLights: [PointLight]  = []
    var camera: Camera
    var preRenderUpdate: (CFTimeInterval) -> Void = {_ in }
    
    init(camera: Camera) {
        self.camera = camera
    }
    
}

extension Scene {
    static let defaultScene: Scene = {
        
        let mainBundle = Bundle.main
        
        let cubeNormalObject = ObjectTemplate(meshName: "cube-normal")
        let cubeNormalInstance = ObjectInstance()
        cubeNormalInstance.position = simd_float3(0.0, 0.0, 3.0)
        cubeNormalInstance.rotation = simd_float3(0.4, 0, 0)
        
        let teapotObject = ObjectTemplate(meshName: "teapot")
        let teapotInstance = ObjectInstance()
        teapotInstance.position = simd_float3(-6.0, -6.0, 1.0)
        teapotInstance.rotation = simd_float3(0, 0, 0)
        
        let catObject = ObjectTemplate(meshName: "cat")
        let catInstance = ObjectInstance()
        catInstance.position = simd_float3(0.0, -1.0, 4.0)
        catInstance.scale = simd_float3.one / 1000
        
        let pumpkinObject = ObjectTemplate(meshName: "pumpkin")
        let pumpkinInstance = ObjectInstance()
        pumpkinInstance.position = simd_float3(0.0, -1.0, 8.0)
        pumpkinInstance.scale = simd_float3.one / 50
        
        let axisObject = ObjectTemplate(meshName: "axis")
        let axisInstance = ObjectInstance()
        axisInstance.position = simd_float3(0.0, 0.0, 0.0)
        axisInstance.scale = simd_float3.one / 10.0

        let spotObject = ObjectTemplate(meshName: "spot", textureName: "spot-texture")
        let spotInstance = ObjectInstance()
        spotInstance.position = simd_float3(-1.0, 0.5, 4.0)
        spotInstance.rotation = simd_float3(0, Float.pi, 0)
        spotInstance.scale = simd_float3(2, 2, 2)
        
        let pineappleObject = ObjectTemplate(meshName: "pineapple2")//, textureName: "pineapple2")
        let pineappleInstance = ObjectInstance()
        pineappleInstance.position = simd_float3(0, -1, -4)
        pineappleInstance.rotation = simd_float3(2.0 * Float.pi / 5, 5 * Float.pi / 6, Float.pi / 3)
        pineappleInstance.scale = simd_float3.one * 4
        
        
        let camera = Camera(position: simd_float3(8.5, 3.2, 6.1))
        camera.yaw = -2.8
        camera.pitch = -0.45
        
        let objects = [
            teapotObject: [teapotInstance],
            catObject: [catInstance],
            pumpkinObject: [pumpkinInstance],
            axisObject: [axisInstance],
            spotObject: [spotInstance],
            pineappleObject: [pineappleInstance]
        ]
        
        let preRenderUpdate = { (deltaTime: CFTimeInterval) in
            let time = Date().timeIntervalSince1970.magnitude
            let animationA = Float(cos(time * 2) + 2)
            let animationB = Float(sin(time) * 2.5)
            spotInstance.rotation = simd_float3(0, animationB, 0)
            pumpkinInstance.scale = simd_float3(repeating: animationA) / 50
            teapotInstance.rotation = simd_float3(animationA * 8, 0, 0)
            camera.move(deltaTime: deltaTime)
        }
        
        let pointLight = PointLight(position: .zero,
                                    color: .one,
                                    intensity: 1.0,
                                    radius: 60.0)
        
        var directionalLight = DirectionalLight(direction: simd_float3(0, -1, 0))
        directionalLight.intensity = 0.8
        directionalLight.color = simd_float3(0, 1, 0.2)
        
        let scene = Scene(camera: camera)
        scene.directionalLights = [directionalLight]
        scene.pointLights = [pointLight]
        scene.preRenderUpdate = preRenderUpdate
        scene.objects = objects
        return scene
    }()
}
