//
//  Object.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/27/24.
//

import Foundation
import Metal
import simd

class Object {
    
    var mesh: Mesh
    var texture: MTLTexture?
    
    var position = simd_float3(0, 0, 1)   // World-space position of the mesh
    var rotation = simd_float3.zero       // 3D rotation (subject to gimbal lock)
    var scale = simd_float3.one           // Per-axis scaling

    /*
    init(meshName: String, textureName: String) {
        // TODO
    }
     */
    
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    

    init(mesh: Mesh) {
        self.mesh = mesh
    }
    
    init(mesh: Mesh, texture: MTLTexture) {
        self.mesh = mesh
        self.texture = texture
    }
    
}
