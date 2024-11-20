//
//  MatrixHelpers.swift
//  Palladium
//
//  Created by Edward Jeong on 11/11/24.
//

import Foundation
import simd


let UP = simd_float3(0, 1, 0)
// Matrix PointAt function

func matrixPointAt(pos: simd_float3, target: simd_float3) -> float4x4 {
    // Calculate new forward direction
    var newForward = target - pos
    newForward = normalize(newForward)

    // Calculate new Up direction
    let a = newForward * dot(UP, newForward)
    let newUp = normalize(UP - a)

    // New Right direction is just cross product
    let newRight = cross(newUp, newForward)

    // Construct dimensioning and translation matrix
    let A = simd_float4(newRight.x, newRight.y, newRight.z, 0.0)
    let B = simd_float4(newUp.x, newUp.y, newUp.z, 0.0)
    let C = simd_float4(newForward.x, newForward.y, newForward.z, 0.0)
    let D = simd_float4(pos.x, pos.y, pos.z, 1.0)

    return float4x4(A, B, C, D)
}
