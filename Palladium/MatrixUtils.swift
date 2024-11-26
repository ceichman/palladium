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

func rotation_matrix(axis: vector_float3, theta: Float) -> matrix_float4x4
{
    let c = cos(theta);
    let s = sin(theta);
    
    var X = vector_float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c
    X.y = axis.x * axis.y * (1 - c) - axis.z * s
    X.z = axis.x * axis.z * (1 - c) + axis.y * s
    X.w = 0.0;
    
    var Y = vector_float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s
    Y.w = 0.0
    
    var Z = vector_float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c
    Z.w = 0.0;
    
    var W = vector_float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    return matrix_float4x4(X, Y, Z, W);
}

func magnitude(_ vec: simd_float3) -> Float {
    return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
