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

class Mesh {
    var origin: simd_float3   // Offset for transformations of the mesh
    var position: simd_float3   // World-space position of the mesh
    var rotation: simd_float3   // 3D rotation (subject to gimbal lock)
    var scale: simd_float3   // Per-axis scaling
    var triangles: [Triangle]
    var vertices: [ApplicationVertex]
    
    init(origin: simd_float3, triangles: [Triangle], vertices: [ApplicationVertex]) {
        self.origin = origin
        self.position = simd_float3.zero
        self.triangles = triangles
        self.vertices = vertices
        self.rotation = simd_float3(repeating: 0)
        self.scale = simd_float3.one
    }
    
    init(triangles: [Triangle], vertices: [ApplicationVertex]) {
        self.origin = simd_float3.zero
        self.position = simd_float3.zero
        self.triangles = triangles
        self.vertices = vertices
        self.rotation = simd_float3.zero
        self.scale = simd_float3.one
    }
    
    // Calculates the normal vectors for an array of triangles, updating values in-place.
    // Each triangle in self.triangles should be made up of elements of vertices: [Vertex].
    // Each vertex in each triangle should be a member of vertices.
    // Only needed upon loading new vertex data.
    func calculateNormals() {
        for i in self.triangles.indices {
            let lineA = self.triangles[i].b.position - self.triangles[i].a.position
            let lineB = self.triangles[i].c.position - self.triangles[i].a.position
            let cross = cross(lineA, lineB)
            self.triangles[i].a.normal += cross
            self.triangles[i].b.normal += cross
            self.triangles[i].c.normal += cross
        }
        // normalize all vertices
        normalizeNormals()
    }
    
    func normalizeNormals() {
        for i in vertices.indices {
            if vertices[i].normal == simd_float3.zero { continue }
            vertices[i].normal = normalize(vertices[i].normal)
        }
    }
    
    // Returns the array of shader-ready vertices and the size of the resulting buffer.
    func vertexArray() -> ([Vertex], Int) {
        var result: [Vertex] = []
        for triangle in triangles {
            result.append(Vertex(triangle.a))
            result.append(Vertex(triangle.b))
            result.append(Vertex(triangle.c))
        }
        return (result, result.count * MemoryLayout<Vertex>.stride)
    }
    
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position - origin)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    
    static func fromOBJ(url: URL) -> Mesh {
        let reader = LineReader(url: url)!
        let parser = OBJParser(source: reader)
        
        var vertices: [ApplicationVertex] = []
        var normals: [simd_float3] = []
        var uvs: [simd_float2] = []
        var triangles: [Triangle] = []
        
        var vertexAverage = simd_float3.zero
        
        parser.onVertex = { (x, y, z, w, r, g, b) in
            vertices.append(ApplicationVertex(
                position: simd_float3(x: Float(x), y: Float(y), z: Float(z)),
                color: simd_float4(x: r, y: g, z: b, w: 1.0)
            ))
            vertexAverage += simd_float3(x, y, z)
        }
        
        parser.onVertexNormal = { (x, y, z) in
            normals.append(simd_float3(x: Float(x), y: Float(y), z: Float(z)))
        }
        
        parser.onTextureCoord = { (u, v, w) in
            uvs.append(simd_float2(x: Float(u), y: Float(v)))
        }
        
        parser.onFace = { (count, vertexIndices, vertexTextureCoordIndices, vertexNormalIndices ) in
            if count != 3 { return }
            for i in 0..<count {
                if vertexNormalIndices.count > i { vertices[vertexIndices[i]].normal += normals[vertexNormalIndices[i]] } // accumulate and normalize later
                if vertexTextureCoordIndices.count > i { vertices[vertexIndices[i]].uvs = uvs[vertexTextureCoordIndices[i]] }
            }
            triangles.append(Triangle(a: vertices[vertexIndices[0]], b: vertices[vertexIndices[1]], c: vertices[vertexIndices[2]]))
        }
        
        parser.onUnknown = { (line) in } // do nothing
        
        parser.parse() // populate arrays
        
        let mesh = Mesh(triangles: triangles, vertices: vertices)
        mesh.normalizeNormals()
        mesh.origin = simd_float3(vertexAverage / Float(vertices.count))
        
        return mesh
    }
    
    static func fromOBJ(url: URL, origin: simd_float3) -> Mesh {
        let mesh = self.fromOBJ(url: url)
        mesh.origin = origin
        return mesh
    }
    
    static func fromOBJ(url: URL, position: simd_float3, rotation: simd_float3, scale: simd_float3) -> Mesh {
        let mesh = self.fromOBJ(url: url)
        mesh.position = position
        mesh.rotation = rotation
        mesh.scale = scale
        return mesh
    }
}


// In Metal, the default coordinate system is the normalized coordinate system, which means that by default you’re looking at a 2x2x1 cube centered at (0, 0, 0.5).
// If you consider the Z=0 plane, then (-1, -1, 0) is the lower left, (0, 0, 0) is the center, and (1, 1, 0) is the upper right.

let white = simd_float4(1, 1, 1, 1)
let red = simd_float4(1, 0, 0, 1)
let green = simd_float4(0, 1, 0, 1)
let blue = simd_float4(0, 0, 1, 1)

var vertices: [ApplicationVertex] = // needs to be mutable so we can calculate normals when loaded
[
    ApplicationVertex(position: simd_float3(0, 0, 0), color: red), // southwest bottom
    ApplicationVertex(position: simd_float3(0, 1, 0), color: green), // southwest top
    ApplicationVertex(position: simd_float3(1, 1, 0), color: blue), // southeast top
    ApplicationVertex(position: simd_float3(1, 0, 0), color: white), // southeast bottom
    ApplicationVertex(position: simd_float3(0, 0, 1), color: red), // northwest bottom
    ApplicationVertex(position: simd_float3(0, 1, 1), color: green), // northwest top
    ApplicationVertex(position: simd_float3(1, 1, 1), color: blue), // northeast top
    ApplicationVertex(position: simd_float3(1, 0, 1), color: white), // northeast bottom
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

let cubeMesh = Mesh(triangles: triangles, vertices: vertices)
