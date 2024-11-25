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
            print(yaw, pitch)
            let yawMod = yaw.remainder(dividingBy: Double.pi * 2)
            let pitchMod = pitch.remainder(dividingBy: Double.pi * 2)
            // this should get rid of gimbal lock
            
            // TODO: this may not actually fix gimbal lock; consider quaternion rotation instead
            let axis = normalize(simd_float3(Float(pitchMod), Float(yawMod), 0))
            let rotMatrix = rotation_matrix(axis: axis, theta: magnitude(simd_float3(Float(pitchMod), Float(yawMod), 0)))
            let rotated = rotMatrix * vector_float4(ROLLAXIS, 1.0)
            return simd_float3(rotated.x, rotated.y, rotated.z)
        }
    }
    
    // debug the physics
    // Normalized direction vectors for strafing.
    var relativeLeft: simd_float3 {
        let cross = cross(YAWAXIS * -1.0, lookDirection)
        return normalize(simd_float3(cross.x, 0, cross.z))
    }
    var relativeRight: simd_float3 {
        let cross = cross(YAWAXIS, lookDirection)
        return normalize(simd_float3(cross.x, 0, cross.z))
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
