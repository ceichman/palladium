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
    var target: simd_float3
    var velocityX: Float = 0
    var velocityY: Float = 0
    var velocityZ: Float = 0

    init(position: simd_float3, target: simd_float3) {
        self.position = position
        self.target = target
    }
    
    func move(deltaTime: CFTimeInterval) {
        self.position += simd_float3(self.velocityX, self.velocityY, self.velocityZ) * Float(deltaTime)
    }
    
    // Move camera up
    func moveUp(_ distance: Float) {
        position.y += distance
        target.y += distance
    }

    // Move camera down
    func moveDown(_ distance: Float) {
        position.y -= distance
        target.y -= distance
    }

    // Move camera left
    func moveLeft(_ distance: Float) {
        position.x -= distance
        target.x -= distance
    }

    // Move camera right
    func moveRight(_ distance: Float) {
        position.x += distance
        target.x += distance
    }

    // Create the view matrix using the current position, target, and up vector
    func getViewMatrix() -> float4x4 {
        let mat = matrixPointAt(pos: position, target: target)
        return mat.inverse
    }
}
