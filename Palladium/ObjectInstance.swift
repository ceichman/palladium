//
//  ObjectInstance.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/10/24.
//

import Foundation
import simd

class ObjectInstance {
    
    var position: simd_float3   // World-space position of the mesh
    var rotation: simd_float3       // 3D rotation
    var scale: simd_float3           // Per-axis scaling
    
    var previousPosition = simd_float3(0, 0, 1)
    var previousRotation = simd_float3.zero
    var previousScale = simd_float3.one
    
    init(position: simd_float3, rotation: simd_float3, scale: simd_float3) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.previousPosition = position
        self.previousRotation = rotation
        self.previousScale = scale
    }
    
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    
    func previousModelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: previousPosition)
        let rotation =
            rotation_matrix(axis: PITCHAXIS, theta: previousRotation.x) *
            rotation_matrix(axis: YAWAXIS, theta: previousRotation.y) *
            rotation_matrix(axis: ROLLAXIS, theta: previousRotation.z)
        let scaling = scaling_matrix(scale: previousScale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    
    func snapshotPrevious() -> Void {
        previousPosition = position
        previousRotation = rotation
        previousScale = scale
    }

}
