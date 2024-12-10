//
//  ObjectInstance.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/10/24.
//

import Foundation
import simd

class ObjectInstance {
    
    var position = simd_float3(0, 0, 1)   // World-space position of the mesh
    var rotation = simd_float3.zero       // 3D rotation (subject to gimbal lock)
    var scale = simd_float3.one           // Per-axis scaling
 
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }

}
