//
//  Camera.swift
//  Palladium
//
//  Created by Edward Jeong on 11/11/24.
//

import Foundation
import simd

class Camera {
    var position: vec3d
    var target: vec3d
    var up: vec3d

    init(position: vec3d, target: vec3d, up: vec3d = vec3d(x: 0, y: 1, z: 0)) {
        self.position = position
        self.target = target
        self.up = up
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
        let mat = matrixPointAt(pos: position, target: target, up: up)
        return matrixQuickInverse(mat).m
    }
}

