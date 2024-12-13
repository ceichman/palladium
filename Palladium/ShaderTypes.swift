//
//  ShaderTypes.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/13/24.
//

import Foundation
import simd
import Metal

struct ViewProjection {
    var view: simd_float4x4
    var projection: simd_float4x4
}

struct ModelTransformation {
    var translation: simd_float4x4
    var rotation: simd_float4x4
    var scaling: simd_float4x4
}

struct DirectionalLight {
    var direction: simd_float3
    var color: simd_float3 = .one
    var intensity: Float = 1.0
    
    init(direction: simd_float3) {
        self.direction = direction
    }
}

struct PointLight {
    var position: simd_float3 = .zero
    var color: simd_float3 = .one
    var intensity: Float = 1.0
    var radius: Float = 1.0
}

struct FragmentParams {
    var cameraPosition: simd_float3
    var specularCoefficient: Float
    var numDirectionalLights: CInt
    var numPointLights: CInt
}
