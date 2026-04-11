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
    
    func modelTransform() -> ModelTransform {
        return MatrixUtils.createModelTransform(position: position, eulerRotation: rotation, scale: scale)
    }
    
    func previousModelTransform() -> ModelTransform {
        return MatrixUtils.createModelTransform(position: previousPosition, eulerRotation: previousRotation, scale: previousScale)
    }
    
    func saveCurrentAsPrevious() -> Void {
        previousPosition = position
        previousRotation = rotation
        previousScale = scale
    }

}
