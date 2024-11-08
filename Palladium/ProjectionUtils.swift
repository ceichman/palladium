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
    var time: Float
}

struct TransformationParams {
    var origin: simd_float3
    var rotation: simd_float3
    var scale: simd_float3
}
