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
    var yaw = Double.pi / 2.0  // radians, 0 == +z
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
    
    var forwardVelocity: Float = 0 // in the direction of LookDirection
    var strafeVelocity: Float = 0  // in the xz-plane
    var verticalVelocity: Float = 0  // independent of LookDirection
    private var worldVelocity: simd_float3 {
        get {
            let forwardContribution = forwardVelocity * lookDirection
            let relativeRight = normalize(cross(YAWAXIS, lookDirection))
            let strafeContribution = relativeRight * strafeVelocity
            let verticalContribution = YAWAXIS * verticalVelocity
            return forwardContribution + strafeContribution + verticalContribution
        }
    }
    
    var fovRadians: Float = 40.0 * Float.pi / 180.0

    init(position: simd_float3) {
        self.position = position
    }
    
    init(position: simd_float3, pitch: Double, yaw: Double) {
        self.position = position
        self.pitch = pitch
        self.yaw = yaw
    }
    
    func move(deltaTime: CFTimeInterval) {
        self.position += worldVelocity * Float(deltaTime)
    }
    
    // Create the view matrix using the current position, target, and up vector
    private func getViewMatrix() -> float4x4 {
        let target = self.position + self.lookDirection
        let mat = matrixPointAt(pos: position, target: target)
        return mat.inverse
    }
    
    func viewProjection(aspectRatio: Float) -> ViewProjection {
        let nearZ: Float = 0.3
        let farZ: Float = 1000.0
        let proj = projection_matrix(aspectRatio: aspectRatio,
                                     fovRadians: self.fovRadians,
                                     nearZ: nearZ,
                                     farZ: farZ
        )
        return ViewProjection(view: self.getViewMatrix(), projection: proj)
    }
}
