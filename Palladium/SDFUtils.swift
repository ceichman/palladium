//
//  SDF.swift
//  Palladium
//
//  Created by Charlotte Eichman on 4/10/26.
//

class SDFUtils {
    
    static func createSDF(type: SDFType, position: simd_float3, eulerRotation: simd_float3, scale: simd_float3) -> SDF {
        
        let transform = MatrixUtils.createInverseModelTransform(position: position, eulerRotation: eulerRotation, scale: scale)
        
        return SDF(worldToLocal: transform, type: type)
    }
    
}
