//
//  Object.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/27/24.
//

import Foundation
import Metal
import MetalKit
import simd

class Object {
    
    let textureLoader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    let mainBundle = Bundle.main
    
    var mesh: Mesh
    var texture: MTLTexture?
    
    var position = simd_float3(0, 0, 1)   // World-space position of the mesh
    var rotation = simd_float3.zero       // 3D rotation (subject to gimbal lock)
    var scale = simd_float3.one           // Per-axis scaling

    convenience init(meshName: String, textureName: String) {
        self.init(meshName: meshName)
        let textureURL = mainBundle.url(forResource: textureName, withExtension: "png", subdirectory: "textures")!
        self.texture = try! textureLoader.newTexture(URL: textureURL)
    }
    
    init(meshName: String) {
        let meshURL = mainBundle.url(forResource: meshName, withExtension: "obj", subdirectory: "meshes")!
        self.mesh = Mesh.fromOBJ(url: meshURL, calculateOrigin: true)
    }

    init(mesh: Mesh) {
        self.mesh = mesh
    }
    
    init(mesh: Mesh, texture: MTLTexture) {
        self.mesh = mesh
        self.texture = texture
    }
    
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    

}
