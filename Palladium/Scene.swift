//
//  Scene.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

class Scene {
    var objects: [String:Object]
    var directionalLights: [DirectionalLight]
    var pointLights: [PointLight]
    var camera: Camera
    var preRenderUpdate: (CFTimeInterval) -> Void = {_ in }
    
    init(objects: [String:Object], directionalLights: [DirectionalLight], pointLights: [PointLight], camera: Camera) {
        self.objects = objects
        self.directionalLights = directionalLights
        self.pointLights = pointLights
        self.camera = camera
    }
    
}

extension Scene {
    static let defaultScene: Scene = {
        
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
        axisObject.position = simd_float3(0.0, 0.0, 0.0)
        axisObject.scale = simd_float3.one / 10.0

        let spotObject = Object(meshName: "spot", textureName: "spot-texture")
        spotObject.position = simd_float3(-1.0, 0.5, 4.0)
        spotObject.rotation = simd_float3(0, Float.pi, 0)
        spotObject.scale = simd_float3(2, 2, 2)
        
        let pineappleObject = Object(meshName: "pineapple2")//, textureName: "pineapple2")
        pineappleObject.position = simd_float3(0, -1, -4)
        pineappleObject.rotation = simd_float3(2.0 * Float.pi / 5, 5 * Float.pi / 6, Float.pi / 3)
        pineappleObject.scale = simd_float3.one * 4
        
        
        let camera = Camera(position: simd_float3(8.5, 3.2, 6.1))
        camera.yaw = -2.8
        camera.pitch = -0.45
        
        let objects = ["spot": spotObject, "pumpkin": pumpkinObject, "axis": axisObject, "pineapple": pineappleObject, "teapot": teapotObject]
        
        
        let preRenderUpdate = { (deltaTime: CFTimeInterval) in
            let time = Date().timeIntervalSince1970.magnitude
            let animationA = Float(cos(time * 2) + 2)
            let animationB = Float(sin(time) * 2.5)
            objects["spot"]!.rotation = simd_float3(0, animationB, 0)
            objects["pumpkin"]!.scale = simd_float3(repeating: animationA) / 50
            objects["teapot"]!.rotation = simd_float3(animationA * 8, 0, 0)
            camera.move(deltaTime: deltaTime)
        }
        
        let pointLight = PointLight(position: .zero,
                                    color: .one,
                                    intensity: 1.0,
                                    radius: 60.0)
        
        var directionalLight = DirectionalLight(direction: simd_float3(0, -1, 0))
        directionalLight.intensity = 0.8
        directionalLight.color = simd_float3(0, 1, 0.2)
        
        let scene = Scene(objects: objects, directionalLights: [directionalLight], pointLights: [pointLight], camera: camera)
        scene.preRenderUpdate = preRenderUpdate
        return scene
    }()
}
