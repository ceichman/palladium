//
//  ProjectionUtils.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/4/24.
//

import Foundation
import simd

struct ProjectionParams {
    var aspectRatio: Float
    var fovRadians: Float
    var nearZ: Float
    var farZ: Float
    // temp
    // var projectionMatrix: simd_float4x4
}

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
    var size: CInt
    var mat: [Float]
}

// Used to collect info before normals are calculated. Defined as a class
// to take advantage of pass-by-reference so that multiple Triangle primitives can
// reuse the same underlying vertex during normal calculation.
class ApplicationVertex {
    var position = simd_float3(0, 0, 0)
    var color = simd_float4(0, 0, 0, 0)
    var normal = simd_float3(0, 0, 0)
    var uvs = simd_float2.zero
    
    init(position: simd_float3, color: simd_float4, normal: simd_float3) {
        self.position = position
        self.color = color
        self.normal = normal
    }
    
    init(position: simd_float3, color: simd_float4) {
        self.position = position
        self.color = color
        self.normal = simd_float3.zero
    }
}

// Used to actually pass vertex data to the GPU after normals are calculated.
struct Vertex {
    var position: simd_float3
    var color: simd_float4
    var normal: simd_float3
    var uvs: simd_float2
    
    init(_ applicationVertex: ApplicationVertex) {
        position = applicationVertex.position
        color = applicationVertex.color
        normal = applicationVertex.normal
        uvs = applicationVertex.uvs
    }
}

struct Triangle {
    var a: ApplicationVertex
    var b: ApplicationVertex
    var c: ApplicationVertex
}

