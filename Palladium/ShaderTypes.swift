//
//  ShaderTypes.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/13/24.
//

import Foundation
import simd

struct ViewProjection {
    var view: simd_float4x4
    var projection: simd_float4x4
}

struct ModelTransformation {
    var translation: simd_float4x4
    var rotation: simd_float4x4
    var scaling: simd_float4x4
}

struct FragmentParams {
    var cameraPosition: simd_float3
    var specularCoefficient: Float
    var numDirectionalLights: CInt
    var numPointLights: CInt
}

struct ConvolutionKernel {
    var size: CInt   // should be odd sqrt(mat.count)
    var mat: [Float]
}
