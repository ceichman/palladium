//
//  MatrixHelpers.swift
//  Palladium
//
//  Created by Edward Jeong on 11/11/24.
//

import Foundation
import simd


struct mat4x4 {
    var m: float4x4
    
    init() {
        m = float4x4(1.0)
    }
}

struct vec3d {
    var x: Float
    var y: Float
    var z: Float
    
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

// Helper vector functions
func vectorSub(_ v1: vec3d, _ v2: vec3d) -> vec3d {
    return vec3d(x: v1.x - v2.x, y: v1.y - v2.y, z: v1.z - v2.z)
}

func vectorDotProduct(_ v1: vec3d, _ v2: vec3d) -> Float {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
}

func vectorMul(_ v: vec3d, _ k: Float) -> vec3d {
    return vec3d(x: v.x * k, y: v.y * k, z: v.z * k)
}

func vectorCrossProduct(_ v1: vec3d, _ v2: vec3d) -> vec3d {
    return vec3d(
        x: v1.y * v2.z - v1.z * v2.y,
        y: v1.z * v2.x - v1.x * v2.z,
        z: v1.x * v2.y - v1.y * v2.x
    )
}

func vectorNormalise(_ v: vec3d) -> vec3d {
    let length = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    return vec3d(x: v.x / length, y: v.y / length, z: v.z / length)
}

// Matrix PointAt function
func matrixPointAt(pos: vec3d, target: vec3d, up: vec3d) -> mat4x4 {
    // Calculate new forward direction
    var newForward = vectorSub(target, pos)
    newForward = vectorNormalise(newForward)

    // Calculate new Up direction
    let a = vectorMul(newForward, vectorDotProduct(up, newForward))
    var newUp = vectorSub(up, a)
    newUp = vectorNormalise(newUp)

    // New Right direction is just cross product
    let newRight = vectorCrossProduct(newUp, newForward)

    // Construct dimensioning and translation matrix
    var matrix = mat4x4()
    matrix.m[0] = simd_float4(newRight.x, newRight.y, newRight.z, 0.0)
    matrix.m[1] = simd_float4(newUp.x, newUp.y, newUp.z, 0.0)
    matrix.m[2] = simd_float4(newForward.x, newForward.y, newForward.z, 0.0)
    matrix.m[3] = simd_float4(pos.x, pos.y, pos.z, 1.0)

    return matrix
}

// Matrix QuickInverse function (only for rotation/translation matrices)
func matrixQuickInverse(_ m: mat4x4) -> mat4x4 {
    var matrix = mat4x4()
    
    // Transpose rotation part
    matrix.m[0] = simd_float4(m.m[0].x, m.m[1].x, m.m[2].x, 0.0)
    matrix.m[1] = simd_float4(m.m[0].y, m.m[1].y, m.m[2].y, 0.0)
    matrix.m[2] = simd_float4(m.m[0].z, m.m[1].z, m.m[2].z, 0.0)
    
    // Calculate the inverse of the translation part
    matrix.m[3].x = -(m.m[3].x * matrix.m[0].x + m.m[3].y * matrix.m[1].x + m.m[3].z * matrix.m[2].x)
    matrix.m[3].y = -(m.m[3].x * matrix.m[0].y + m.m[3].y * matrix.m[1].y + m.m[3].z * matrix.m[2].y)
    matrix.m[3].z = -(m.m[3].x * matrix.m[0].z + m.m[3].y * matrix.m[1].z + m.m[3].z * matrix.m[2].z)
    matrix.m[3].w = 1.0
    
    return matrix
}
