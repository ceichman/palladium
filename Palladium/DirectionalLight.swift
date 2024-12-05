//
//  DirectionalLight.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

struct DirectionalLight {
    var intensity: Float = 1.0
    var color: simd_float3 = .one
    var direction: simd_float3
    
    init(direction: simd_float3) {
        self.direction = direction
    }
}
