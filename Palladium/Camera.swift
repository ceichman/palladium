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
    var yaw = 0.0  // radians, 0 == +z
    var pitch = 0.0  // radians, 0 == +z
    var lookDirection: simd_float3 {
        get {
            let yawMod = yaw.remainder(dividingBy: Double.pi * 2)
            let pitchMod = pitch.remainder(dividingBy: Double.pi * 2)
            var forward = simd_float3()
            forward.x = Float(cos(pitchMod) * cos(yawMod))
            forward.y = Float(sin(pitchMod))
            forward.z = Float(cos(pitchMod) * sin(yawMod))
            return normalize(forward)
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
    private func getViewMatrix() -> float4x4 {
        let target = self.position + self.lookDirection
        let mat = matrixPointAt(pos: position, target: target)
        return mat.inverse
    }
    
    func viewProjection(_ params: ProjectionParams) -> ViewProjection {
        // TODO
        let proj = projection_matrix(aspectRatio: params.aspectRatio, fovRadians: params.fovRadians, nearZ: params.nearZ, farZ: params.farZ)
        return ViewProjection(view: self.getViewMatrix(), projection: proj)
    }
}
