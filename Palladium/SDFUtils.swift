//
//  SDF.swift
//  Palladium
//
//  Created by Charlotte Eichman on 4/10/26.
//

class SDFUtils {
    
    static func createSDF(type: SDFType, position: simd_float3, rotation: simd_float3, scale: simd_float3) -> SDF {
        
        let translationMatrix = translation_matrix(t: position)
        let rotationMatrix =
            rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
            rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
            rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scalingMatrix = scaling_matrix(scale: scale)
        
        let transform = ModelTransform(translation: translationMatrix, rotation: rotationMatrix, scaling: scalingMatrix)
        
        return SDF(transform: transform, type: type)
    }
}
