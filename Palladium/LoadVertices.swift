//
//  LoadVertices.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/4/24.
//

import Foundation

// Eventually this file should contain routines to import data from .obj files
// and populate vertex arrays. Right now it's just a dumping ground for raw vertex data.

// In Metal, the default coordinate system is the normalized coordinate system, which means that by default you’re looking at a 2x2x1 cube centered at (0, 0, 0.5).
// If you consider the Z=0 plane, then (-1, -1, 0) is the lower left, (0, 0, 0) is the center, and (1, 1, 0) is the upper right.
// Placeholder triangle:
let vertexData: [Float] = [
   0.0,  1.0, 0.0,
  -1.0, -1.0, 0.0,
   1.0, -1.0, 0.0
]

// North: +z
// East: +x
let cubeVertices: [Float] = [
    // South face:
    10.0, 0.0, 10.0,
    10.0, 10.0, 10.0,
    20.0, 10.0, 10.0,
    10.0, 0.0, 10.0,
    20.0, 10.0, 10.0,
    20.0, 0.0, 10.0,
    // East face:
    20.0, 0.0, 10.0,
    20.0, 10.0, 10.0,
    20.0, 10.0, 20.0,
    20.0, 0.0, 10.0,
    20.0, 10.0, 20.0,
    20.0, 0.0, 20.0,
    // North face:
    20.0, 0.0, 20.0,
    20.0, 10.0, 20.0,
    10.0, 10.0, 20.0,
    20.0, 0.0, 20.0,
    10.0, 10.0, 20.0,
    10.0, 0.0, 20.0,
    // West face:
    10.0, 0.0, 20.0,
    10.0, 10.0, 20.0,
    10.0, 10.0, 10.0,
    10.0, 0.0, 20.0,
    10.0, 10.0, 10.0,
    10.0, 0.0, 10.0,
    // Top face:
    10.0, 10.0, 10.0,
    10.0, 10.0, 20.0,
    20.0, 10.0, 20.0,
    10.0, 10.0, 10.0,
    20.0, 10.0, 20.0,
    20.0, 10.0, 10.0,
    // Bottom face:
    10.0, 0.0, 20.0,
    10.0, 0.0, 10.0,
    20.0, 0.0, 10.0,
    10.0, 0.0, 20.0,
    20.0, 0.0, 10.0,
    20.0, 0.0, 20.0
 ]
