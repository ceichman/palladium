//
//  PointLight.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

import Foundation
import simd

class PointLight {
    var intensity: Float = 1.0
    var color: simd_float3 = .one
    var radius: Float = 1.0
}
