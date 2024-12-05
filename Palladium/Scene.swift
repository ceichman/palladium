//
//  Scene.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

class Scene: RendererDelegate {
    var objects: [String:Object]
    var directionalLights: [DirectionalLight]
    var pointLights: [PointLight]
    var camera: Camera
    
    init(objects: [String:Object], directionalLights: [DirectionalLight], pointLights: [PointLight], camera: Camera) {
        self.objects = objects
        self.directionalLights = directionalLights
        self.pointLights = pointLights
        self.camera = camera
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
}
