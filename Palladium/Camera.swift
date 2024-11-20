//
//  Camera.swift
//  Palladium
//
//  Created by Edward Jeong on 11/11/24.
//

import Foundation
import simd

class Camera {
    var position: simd_float3
    var lookDirection: simd_float3
    var target: simd_float3 {
        get {
            position + lookDirection
        }
    }
    var velocityX: Float = 0
    var velocityY: Float = 0
    var velocityZ: Float = 0

    init(position: simd_float3, lookDirection: simd_float3) {
        self.position = position
        self.lookDirection = lookDirection
    }
    
    func yaw(dTheta: Double) {
        let yawMatrix = rotation_matrix(axis: vector_float3(0, 1, 0), theta: Float(dTheta))
        let yawed = yawMatrix * vector_float4(self.lookDirection, 1.0)
        self.lookDirection = simd_float3(yawed.x, yawed.y, yawed.z)
    }
    
    func pitch(dTheta: Double) {
        let pitchMatrix = rotation_matrix(axis: vector_float3(1, 0, 0), theta: Float(dTheta))
        let pitched = pitchMatrix * vector_float4(self.lookDirection, 1.0)
        self.lookDirection = simd_float3(pitched.x, pitched.y, pitched.z)
    }
    
    func move(deltaTime: CFTimeInterval) {
        self.position += simd_float3(self.velocityX, self.velocityY, self.velocityZ) * Float(deltaTime)
    }
    
    // Create the view matrix using the current position, target, and up vector
    func getViewMatrix() -> float4x4 {
        let mat = matrixPointAt(pos: position, target: target)
        return mat.inverse
    }
}
