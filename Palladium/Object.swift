//
//  Object.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/27/24.
//

import Foundation
import Metal
import simd

class Object {
    
    var mesh: Mesh
    var texture: MTLTexture?
    
    var position = simd_float3(0, 0, 1)   // World-space position of the mesh
    var rotation = simd_float3.zero       // 3D rotation (subject to gimbal lock)
    var scale = simd_float3.one           // Per-axis scaling

    /*
    init(meshName: String, textureName: String) {
        // TODO
    }
     */
    
    init(mesh: Mesh) {
        self.mesh = mesh
    }
    
    init(mesh: Mesh, texture: MTLTexture) {
        self.mesh = mesh
        self.texture = texture
    }
    
}
