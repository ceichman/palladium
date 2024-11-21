//
//  Camera.swift
//  Palladium
//
//  Created by Edward Jeong on 11/11/24.
//

import Foundation
import simd

class Camera {
    
    private let YAWAXIS = simd_float3(0, 1, 0)
    private let PITCHAXIS = simd_float3(1, 0, 0)
    private let ROLLAXIS = simd_float3(0, 0, 1)

    var position: simd_float3
    var yaw = 0.0  // radians, 0 == +z
    var pitch = 0.0  // radians, 0 == +z
    var lookDirection: simd_float3 {
        get {
            let yawMatrix = rotation_matrix(axis: YAWAXIS, theta: Float(yaw))
            let pitchMatrix = rotation_matrix(axis: PITCHAXIS, theta: Float(pitch))
            let yawed = yawMatrix * vector_float4(ROLLAXIS, 1.0)
            let pitched = pitchMatrix * yawed
            return simd_float3(pitched.x, pitched.y, pitched.z)
        }
    }
    var velocityX: Float = 0
    var velocityY: Float = 0
    var velocityZ: Float = 0

    init(position: simd_float3) {
        self.position = position
    }
    
    init(position: simd_float3, pitch: Double, yaw: Double) {
        self.position = position
        self.pitch = pitch
        self.yaw = yaw
    }
    
    func move(deltaTime: CFTimeInterval) {
        self.position += simd_float3(self.velocityX, self.velocityY, self.velocityZ) * Float(deltaTime)
    }
    
    // Create the view matrix using the current position, target, and up vector
    func getViewMatrix() -> float4x4 {
        let target = self.position + self.lookDirection
        let mat = matrixPointAt(pos: position, target: target)
        return mat.inverse
    }
}
