//
//  DirectionalLight.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

struct DirectionalLight {
    var direction: simd_float3
    var color: simd_float3 = .one
    var intensity: Float = 1.0
    
    init(direction: simd_float3) {
        self.direction = direction
    }
}
