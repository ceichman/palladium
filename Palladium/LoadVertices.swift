//
//  LoadVertices.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/4/24.
//

import Foundation
import Metal
import simd

// Eventually this file should contain routines to import data from .obj files
// and populate an ApplicationVertex array. Right now it's just a dumping ground for raw vertex data.

// Used to collect info before normals are calculated. Defined as a class
// to take advantage of pass-by-reference so that multiple Triangle primitives can
// reuse the same underlying vertex during normal calculation.
class ApplicationVertex {
    var position: simd_float3
    var color: simd_float4
    var normal: simd_float4
    
    init(position: simd_float3, color: simd_float4, normal: simd_float4) {
        self.position = position
        self.color = color
        self.normal = normal
    }
}

// Used to actually pass vertex data to the GPU after normals are calculated.
struct Vertex {
    var position: simd_float3
    var color: simd_float4
    var normal: simd_float4
    
    init(_ applicationVertex: ApplicationVertex) {
        position = applicationVertex.position
        color = applicationVertex.color
        normal = applicationVertex.normal
    }
}

struct Triangle {
    var a: ApplicationVertex
    var b: ApplicationVertex
    var c: ApplicationVertex
}

// Calculates the normal vectors for an array of triangles, updating values in-place.
// Each triangle in triangles: [Triangle] should be made up of elements of vertices: [Vertex].
// Only needed upon loading new vertex data.
func calculateNormals(triangles: inout [Triangle], vertices: [ApplicationVertex]) {
    for i in triangles.indices {
        let lineA = triangles[i].b.position - triangles[i].a.position
        let lineB = triangles[i].c.position - triangles[i].a.position
        let cross3 = cross(lineA, lineB)
        let cross4 = simd_float4(cross3, 0.0)
        triangles[i].a.normal += cross4
        triangles[i].b.normal += cross4
        triangles[i].c.normal += cross4
    }
    // normalize all vertices
    for i in vertices.indices {
        vertices[i].normal = normalize(vertices[i].normal)
    }
}

func assembleVertexArray(triangles: [Triangle]) -> [Vertex] {
    var result: [Vertex] = []
    for triangle in triangles {
        result.append(Vertex(triangle.a))
        result.append(Vertex(triangle.b))
        result.append(Vertex(triangle.c))
    }
    return result
}

// In Metal, the default coordinate system is the normalized coordinate system, which means that by default you’re looking at a 2x2x1 cube centered at (0, 0, 0.5).
// If you consider the Z=0 plane, then (-1, -1, 0) is the lower left, (0, 0, 0) is the center, and (1, 1, 0) is the upper right.

let white = simd_float4(1, 1, 1, 1)
let red = simd_float4(1, 0, 0, 1)
let green = simd_float4(0, 1, 0, 1)
let blue = simd_float4(0, 0, 1, 1)

var vertices: [ApplicationVertex] = // needs to be mutable so we can calculate normals when loaded
[
    ApplicationVertex(position: simd_float3(0, 0, 0), color: red, normal: simd_float4.zero), // southwest bottom
    ApplicationVertex(position: simd_float3(0, 1, 0), color: green, normal: simd_float4.zero), // southwest top
    ApplicationVertex(position: simd_float3(1, 1, 0), color: blue, normal: simd_float4.zero), // southeast top
    ApplicationVertex(position: simd_float3(1, 0, 0), color: white, normal: simd_float4.zero), // southeast bottom
    ApplicationVertex(position: simd_float3(0, 0, 1), color: red, normal: simd_float4.zero), // northwest bottom
    ApplicationVertex(position: simd_float3(0, 1, 1), color: green, normal: simd_float4.zero), // northwest top
    ApplicationVertex(position: simd_float3(1, 1, 1), color: blue, normal: simd_float4.zero), // northeast top
    ApplicationVertex(position: simd_float3(1, 0, 1), color: white, normal: simd_float4.zero), // northeast bottom
]

var triangles: [Triangle] =
[
    // South face
    Triangle(a: vertices[0], b: vertices[1], c: vertices[2]),
    Triangle(a: vertices[0], b: vertices[2], c: vertices[3]),
    // East face
    Triangle(a: vertices[3], b: vertices[2], c: vertices[6]),
    Triangle(a: vertices[3], b: vertices[6], c: vertices[7]),
    // North face
    Triangle(a: vertices[7], b: vertices[6], c: vertices[5]),
    Triangle(a: vertices[7], b: vertices[5], c: vertices[4]),
    // West face
    Triangle(a: vertices[4], b: vertices[5], c: vertices[1]),
    Triangle(a: vertices[4], b: vertices[1], c: vertices[0]),
    // Top face
    Triangle(a: vertices[1], b: vertices[5], c: vertices[6]),
    Triangle(a: vertices[1], b: vertices[6], c: vertices[2]),
    // Bottom face
    Triangle(a: vertices[4], b: vertices[0], c: vertices[3]),
    Triangle(a: vertices[4], b: vertices[3], c: vertices[7]),
]

